import("stdfaust.lib");

declare name "rtal-glass-squeeze";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Opto-flavoured guitar compressor with program-dependent release, soft knee, sidechain filter and parallel blend.";

presetMode = nentry("glass-squeeze/[0]Factory Preset [style:menu{'Manual':0;'Country Squash':1;'Studio Glue':2;'Infinite Sustain':3}]", 0, 0, 3, 1);
squeezeManual = hslider("glass-squeeze/[1]Squeeze [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
ratioManual = hslider("glass-squeeze/[2]Ratio [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
attackManual = hslider("glass-squeeze/[3]Attack [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
releaseManual = hslider("glass-squeeze/[4]Release [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
scManual = hslider("glass-squeeze/[5]Sidechain HPF [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
blendManual = hslider("glass-squeeze/[6]Blend [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
outputManual = hslider("glass-squeeze/[7]Output [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
grMeter = hbargraph("glass-squeeze/[8]Gain Reduction [unit:dB]", 0, 30);

isManual = presetMode < 0.5;
isCountry = (presetMode >= 0.5) * (presetMode < 1.5);
isGlue = (presetMode >= 1.5) * (presetMode < 2.5);
isSustain = presetMode >= 2.5;

selectPreset(manual, country, glue, sustain) =
  manual * isManual +
  country * isCountry +
  glue * isGlue +
  sustain * isSustain;

squeeze = selectPreset(squeezeManual, 0.65, 0.35, 0.85);
ratioKnob = selectPreset(ratioManual, 0.60, 0.30, 0.85);
attack = selectPreset(attackManual, 0.05, 0.45, 0.20);
release = selectPreset(releaseManual, 0.30, 0.50, 0.65);
sc = selectPreset(scManual, 0.25, 0.40, 0.30);
blend = selectPreset(blendManual, 0.85, 1.0, 1.0);
output = selectPreset(outputManual, 0.50, 0.50, 0.62);

process = _,_ : compStereo
with {
  thresholdDb = 0.0 - squeeze * 42.0;
  ratio = 1.5 * pow(12.0, ratioKnob);
  slope = 1.0 - 1.0 / ratio;
  kneeDb = 8.0;
  attackSec = 0.0003 + attack * attack * 0.05;
  releaseSec = 0.04 + release * release * 1.2;

  // Soft-knee static curve: gain reduction in dB for a detector level in dB.
  computeGr(levelDb) = ba.if(over <= 0.0 - kneeDb * 0.5, 0.0,
    ba.if(over >= kneeDb * 0.5, slope * over, slope * (over + kneeDb * 0.5) * (over + kneeDb * 0.5) / (2.0 * kneeDb)))
  with {
    over = levelDb - thresholdDb;
  };

  // Ballistics in the dB domain. Release slows down the deeper and longer the
  // compressor has been working, like an optical cell's memory.
  ballistics(target) = step ~ _
  with {
    step(prev) = prev + (target - prev) * ba.if(target > prev, aAtt, aRel)
    with {
      aAtt = 1.0 - exp(-1.0 / (attackSec * ma.SR));
      memory = min(1.0, prev / 18.0);
      aRel = 1.0 - exp(-1.0 / (releaseSec * (1.0 + memory * 3.0) * ma.SR));
    };
  };

  compStereo(inL, inR) = outL, outR
  with {
    scHz = 20.0 + sc * sc * 380.0;
    detector = max(abs(inL : fi.highpass(2, scHz)), abs(inR : fi.highpass(2, scHz)));
    levelDb = detector : an.amp_follower_ar(0.0005, 0.03) : max(0.00001) : ba.linear2db;
    gr = levelDb : computeGr : ballistics : grMeter;
    makeupDb = (0.0 - thresholdDb) * slope * 0.6 + (output - 0.5) * 24.0;
    g = ba.db2linear(makeupDb - gr);
    dryGain = ba.db2linear((output - 0.5) * 24.0);
    // 2 ms lookahead so the gain reduction is already in place when a pick attack arrives.
    lookahead = de.delay(1024, int(0.002 * ma.SR));
    aheadL = inL : lookahead;
    aheadR = inR : lookahead;
    outL = aheadL * g * blend + aheadL * dryGain * (1.0 - blend);
    outR = aheadR * g * blend + aheadR * dryGain * (1.0 - blend);
  };
};
