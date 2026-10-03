import("stdfaust.lib");

declare name "rtal-abbey-adt";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Artificial double tracking: a varispeed tape copy wanders behind your part, or swoops into tape flanging.";

presetMode = nentry("abbey-adt/[0]Factory Preset [style:menu{'Manual':0;'Studio Two Double':1;'Lazy Double':2;'Tape Flange':3}]", 0, 0, 3, 1);
modeManual = nentry("abbey-adt/[1]Mode [style:menu{'Double':0;'Tape Flange':1}]", 0, 0, 1, 1);
delayManual = hslider("abbey-adt/[2]Delay [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
wanderManual = hslider("abbey-adt/[3]Wander [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
rateManual = hslider("abbey-adt/[4]Wander Rate [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("abbey-adt/[5]Tape Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
panManual = hslider("abbey-adt/[6]Spread [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("abbey-adt/[7]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isStudio = (presetMode >= 0.5) * (presetMode < 1.5);
isLazy = (presetMode >= 1.5) * (presetMode < 2.5);
isFlange = presetMode >= 2.5;

selectPreset(manual, studio, lazy, flange) =
  manual * isManual +
  studio * isStudio +
  lazy * isLazy +
  flange * isFlange;

mode = selectPreset(modeManual, 0, 0, 1);
delayKnob = selectPreset(delayManual, 0.35, 0.65, 0.40);
wander = selectPreset(wanderManual, 0.35, 0.55, 0.85);
rate = selectPreset(rateManual, 0.35, 0.20, 0.30);
tone = selectPreset(toneManual, 0.65, 0.50, 0.70);
spread = selectPreset(panManual, 0.80, 0.90, 0.0);
mix = selectPreset(mixManual, 0.50, 0.50, 0.50);

process = _,_ : adtStereo
with {
  maxDelay = 8192;
  isFlange = mode > 0.5;
  // Double: 15-60 ms behind. Flange: sweeping around 1-8 ms, crossing near zero.
  baseMs = ba.if(isFlange, 0.6 + delayKnob * 3.0, 15.0 + delayKnob * 45.0);
  wanderHz = 0.05 + rate * rate * 2.5;
  // Varispeed: a smooth random wander, as if the second machine's speed were rocked by hand.
  wobble = no.lfnoise(wanderHz) * 0.7 + os.osc(wanderHz * 0.73) * 0.3;
  wanderMs = ba.if(isFlange, (0.5 + 0.5 * os.osc(wanderHz * 0.5)) * wander * 7.0, wobble * wander * 6.0);

  adtStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    tapeMs = max(0.05, baseMs + wanderMs);
    copy = mono : de.fdelay3(maxDelay, tapeMs * 0.001 * ma.SR)
      : fi.lowpass(2, 4000.0 + tone * tone * 14000.0) : fi.highpass(1, 60.0 + (1.0 - tone) * 80.0);
    // Spread leans the original left and the copy right; at 0 both stay centred (flange).
    copyL = copy * (0.5 - spread * 0.5);
    copyR = copy * (0.5 + spread * 0.5);
    origL = inL;
    origR = inR * (1.0 - spread * 0.5);
    outL = origL * (1.0 - mix * 0.3) + copyL * mix * 1.3;
    outR = origR * (1.0 - mix * 0.3) + copyR * mix * 1.3;
  };
};
