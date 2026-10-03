import("stdfaust.lib");

declare name "rtal-whammy-dive";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Expression pitch shifter for whammy bends, dive bombs and harmonies, with a momentary kick switch.";

presetMode = nentry("whammy-dive/[0]Factory Preset [style:menu{'Manual':0;'Octave Scream':1;'Dive Bomb':2;'Shallow Chorus Bend':3}]", 0, 0, 3, 1);
intervalManual = nentry("whammy-dive/[1]Interval [style:menu{'+2 Octaves':0;'+1 Octave':1;'+5th':2;'+4th':3;'-2nd':4;'-1 Octave':5;'-2 Octaves':6;'Dive Bomb':7;'Detune':8}]", 1, 0, 8, 1);
modeManual = nentry("whammy-dive/[2]Mode [style:menu{'Whammy':0;'Harmony':1}]", 0, 0, 1, 1);
position = hslider("whammy-dive/[3]Position", 0.0, 0.0, 1.0, 0.001);
kick = checkbox("whammy-dive/[4]Kick");
rampManual = hslider("whammy-dive/[5]Ramp [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("whammy-dive/[6]Tone [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("whammy-dive/[7]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isScream = (presetMode >= 0.5) * (presetMode < 1.5);
isDive = (presetMode >= 1.5) * (presetMode < 2.5);
isShallow = presetMode >= 2.5;

selectPreset(manual, scream, dive, shallow) =
  manual * isManual +
  scream * isScream +
  dive * isDive +
  shallow * isShallow;

interval = int(selectPreset(intervalManual, 1, 7, 8));
mode = selectPreset(modeManual, 0, 0, 1);
ramp = selectPreset(rampManual, 0.20, 0.55, 0.30);
tone = selectPreset(toneManual, 0.75, 0.60, 0.80);
level = selectPreset(levelManual, 0.50, 0.50, 0.50);

process = _,_ : whammyStereo
with {
  rangeSemis = ba.selectn(9, interval, 24.0, 12.0, 7.0, 5.0, -2.0, -12.0, -24.0, -36.0, 0.25);

  // Kick pushes the treadle fully down; Ramp sets how fast the pitch travels.
  target = max(position, kick > 0.5);
  rampSec = 0.005 + ramp * ramp * 1.5;
  travel = target : si.smooth(ba.tau2pole(rampSec));
  semis = rangeSemis * travel;

  whammyStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    // Longer grains for downward shifts keep low notes from fluttering.
    shiftUp = mono : ef.transpose(1536, 512, semis);
    shiftDown = mono : ef.transpose(4096, 1024, semis);
    shifted = ba.if(rangeSemis < 0.0, shiftDown, shiftUp) : fi.lowpass(2, 2500.0 + tone * tone * 15000.0);
    // Detune is a harmony-style chorus bend: the shifted copy sits next to the dry.
    isHarmony = (mode > 0.5) | (interval == 8);
    g = 0.3 + level * 1.4;
    outL = (shifted + inL * isHarmony) * g * ba.if(isHarmony, 0.7, 1.0);
    outR = (shifted + inR * isHarmony) * g * ba.if(isHarmony, 0.7, 1.0);
  };
};
