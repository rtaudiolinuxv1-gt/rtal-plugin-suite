import("stdfaust.lib");

declare name "rtal-shite_amp";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Broken, saggy and rude amp character.";

presetMode = nentry("shite-amp/[0]Factory Preset [style:menu{'Manual':0;'Pub Combo':1;'Torn Speaker':2;'Dead Chassis':3}]", 0, 0, 3, 1);
gainManual = hslider("shite-amp/[1]Gain [style:knob]", 0.54, 0.0, 1.0, 0.01) : si.smoo;
sagManual = hslider("shite-amp/[2]Sag [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
rattleManual = hslider("shite-amp/[3]Rattle [style:knob]", 0.28, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("shite-amp/[4]Tone [style:knob]", 0.42, 0.0, 1.0, 0.01) : si.smoo;
rotManual = hslider("shite-amp/[5]Rot [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("shite-amp/[6]Level [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("shite-amp/[7]Mix [style:knob]", 0.90, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isPub = (presetMode >= 0.5) * (presetMode < 1.5);
isTorn = (presetMode >= 1.5) * (presetMode < 2.5);
isDead = presetMode >= 2.5;

selectPreset(manual, pub, torn, dead) =
  manual * isManual +
  pub * isPub +
  torn * isTorn +
  dead * isDead;

gain = selectPreset(gainManual, 0.42, 0.62, 0.84);
sag = selectPreset(sagManual, 0.30, 0.56, 0.78);
rattle = selectPreset(rattleManual, 0.18, 0.46, 0.62);
tone = selectPreset(toneManual, 0.48, 0.40, 0.28);
rot = selectPreset(rotManual, 0.18, 0.40, 0.68);
level = selectPreset(levelManual, 0.50, 0.46, 0.40);
mix = selectPreset(mixManual, 0.84, 0.94, 1.0);

process = _,_ : ampStereo
with {
  ampStereo(inL, inR) = outL, outR
  with {
    mono = ((inL + inR) * 0.5) : fi.highpass(1, 55.0);
    env = mono : an.amp_follower_ar(0.004, 0.18) : min(1.0);
    sagAmt = 1.0 - env * sag * 0.6;
    rotAmt = rot * 0.18;

    ampL = ampify(inL, 0.07);
    ampR = ampify(inR, -0.07);

    outL = ma.tanh(inL * (1.0 - mix) + ampL * mix);
    outR = ma.tanh(inR * (1.0 - mix) + ampR * mix);

    ampify(x, offset) = shaped
    with {
      pre = x : fi.highpass(1, 45.0) : fi.lowpass(1, 7000.0);
      dirty = ((pre * (2.0 + gain * 13.0) * sagAmt) + offset + os.osc(0.7 + rattle * 9.0) * rattle * 0.03) : ma.tanh;
      boxy = dirty : fi.resonbp(180.0 + tone * 900.0, 1.8 + tone * 5.0, 1.0);
      crackle = dirty : fi.highpass(1, 1300.0 + tone * 1800.0) : *(rattle * 0.16 + rot * 0.1);
      flap = dirty : de.fdelay5(8192, 7.0 + rot * 38.0) : fi.resonbp(110.0 + rot * 160.0, 1.4 + rot * 2.8, 1.0) : *(0.08 + rot * 0.24);
      cracked = dirty * (1.0 - tone * 0.45) + boxy * (0.25 + tone * 0.6) + crackle + flap;
      shaped = cracked : fi.lowpass(1, 1700.0 + tone * 4800.0) : fi.highpass(1, 65.0 + rotAmt * 120.0) : *(0.45 + level * 1.2);
    };
  };
};
