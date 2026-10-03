import("stdfaust.lib");

declare name "rtal-treble-boost";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Germanium-style range booster: a single-transistor treble, mid or full-range boost with gentle, lopsided grit.";

presetMode = nentry("treble-boost/[0]Factory Preset [style:menu{'Manual':0;'British Treble':1;'Mid Lead Kick':2;'Clean Full Lift':3}]", 0, 0, 3, 1);
rangeManual = nentry("treble-boost/[1]Range [style:menu{'Treble':0;'Mid':1;'Full':2}]", 0, 0, 2, 1);
boostManual = hslider("treble-boost/[2]Boost [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
biasManual = hslider("treble-boost/[3]Bias [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
gritManual = hslider("treble-boost/[4]Grit [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("treble-boost/[5]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBritish = (presetMode >= 0.5) * (presetMode < 1.5);
isMid = (presetMode >= 1.5) * (presetMode < 2.5);
isClean = presetMode >= 2.5;

selectPreset(manual, british, midKick, clean) =
  manual * isManual +
  british * isBritish +
  midKick * isMid +
  clean * isClean;

range = int(selectPreset(rangeManual, 0, 1, 2));
boost = selectPreset(boostManual, 0.75, 0.65, 0.50);
bias = selectPreset(biasManual, 0.45, 0.35, 0.10);
grit = selectPreset(gritManual, 0.45, 0.35, 0.05);
level = selectPreset(levelManual, 0.45, 0.50, 0.50);

process = _,_ : boostStereo
with {
  // The input capacitor sets what gets boosted: small for treble, larger for mids, huge for full range.
  cornerHz = ba.selectn(3, range, 2200.0, 700.0, 60.0);
  boostDb = boost * 22.0;

  boostVoice(x) = out
  with {
    shaped = x : fi.highpass(1, cornerHz * 0.25) : fi.high_shelf(boostDb, cornerHz);
    // A lightly biased germanium stage: asymmetric soft clip, more lopsided with Bias.
    b = bias * 0.6;
    g = 0.6 + grit * 5.0;
    transistor = (ma.tanh(shaped * g + b) - ma.tanh(b)) / g;
    out = transistor : fi.lowpass(1, 12000.0) : fi.dcblocker : *(0.3 + level * level * 1.4);
  };

  boostStereo(inL, inR) = boostVoice(inL), boostVoice(inR);
};
