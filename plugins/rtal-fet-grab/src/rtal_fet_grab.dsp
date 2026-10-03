import("stdfaust.lib");

declare name "rtal-fet-grab";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "FET-style peak compressor with ultra-fast attack, ratio buttons including all-buttons-in, and gain-dependent colour.";

presetMode = nentry("fet-grab/[0]Factory Preset [style:menu{'Manual':0;'Lead Grab':1;'All Buttons Smash':2;'Parallel Snap':3}]", 0, 0, 3, 1);
inputManual = hslider("fet-grab/[1]Input [unit:dB]", 12, 0, 40, 0.1) : si.smoo;
outputManual = hslider("fet-grab/[2]Output [unit:dB]", 4, -30, 12, 0.1) : si.smoo;
ratioManual = nentry("fet-grab/[3]Ratio [style:menu{'4:1':0;'8:1':1;'12:1':2;'20:1':3;'All Buttons':4}]", 0, 0, 4, 1);
attackManual = hslider("fet-grab/[4]Attack [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
releaseManual = hslider("fet-grab/[5]Release [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
colorManual = hslider("fet-grab/[6]Color [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("fet-grab/[7]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
grMeter = hbargraph("fet-grab/[8]Gain Reduction [unit:dB]", 0, 30);

isManual = presetMode < 0.5;
isLead = (presetMode >= 0.5) * (presetMode < 1.5);
isSmash = (presetMode >= 1.5) * (presetMode < 2.5);
isParallel = presetMode >= 2.5;

selectPreset(manual, lead, smash, parallel) =
  manual * isManual +
  lead * isLead +
  smash * isSmash +
  parallel * isParallel;

inputDb = selectPreset(inputManual, 18.0, 28.0, 22.0);
outputDb = selectPreset(outputManual, 6.0, 7.0, -4.0);
ratioSel = int(selectPreset(ratioManual, 1, 4, 3));
attack = selectPreset(attackManual, 0.30, 0.10, 0.05);
release = selectPreset(releaseManual, 0.35, 0.15, 0.20);
color = selectPreset(colorManual, 0.40, 0.70, 0.50);
mix = selectPreset(mixManual, 1.0, 1.0, 0.45);

process = _,_ : fetStereo
with {
  // Fixed threshold: as on the hardware, you drive the Input into it.
  thresholdDb = -18.0;
  isAllButtons = ratioSel == 4;
  ratio = ba.selectn(5, ratioSel, 4.0, 8.0, 12.0, 20.0, 30.0);
  slope = 1.0 - 1.0 / ratio;
  kneeDb = ba.if(isAllButtons, 2.0, 6.0);
  attackSec = 0.00002 + attack * attack * 0.0008;
  releaseSec = 0.05 + release * release * 1.05;

  computeGr(levelDb) = ba.if(over <= 0.0 - kneeDb * 0.5, 0.0,
    ba.if(over >= kneeDb * 0.5, slope * over, slope * (over + kneeDb * 0.5) * (over + kneeDb * 0.5) / (2.0 * kneeDb)))
  with {
    over = levelDb - thresholdDb;
  };

  // All-buttons mode releases in a lurching two-stage curve, which gives the pumping 'nuke' sound.
  ballistics(target) = step ~ _
  with {
    step(prev) = prev + (target - prev) * ba.if(target > prev, aAtt, aRel)
    with {
      aAtt = 1.0 - exp(-1.0 / (attackSec * ma.SR));
      lurch = ba.if(isAllButtons * (prev > 10.0), 0.35, 1.0);
      aRel = 1.0 - exp(-1.0 / (releaseSec * lurch * ma.SR));
    };
  };

  fetStereo(inL, inR) = outL, outR
  with {
    gIn = ba.db2linear(inputDb);
    driveL = inL * gIn;
    driveR = inR * gIn;
    detector = max(abs(driveL), abs(driveR));
    levelDb = detector : max(0.000001) : ba.linear2db;
    gr = levelDb : computeGr : ballistics : grMeter;
    g = ba.db2linear(0.0 - gr);
    // FET colour: second-harmonic bias that grows with gain reduction.
    fet(x) = x + bias * x * x - bias * (x * x : fi.lowpass(1, 20.0))
    with {
      bias = color * 0.25 * min(1.0, gr / 12.0 + 0.1);
    };
    gOut = ba.db2linear(outputDb);
    wetL = driveL * g : fet : ma.tanh : *(gOut);
    wetR = driveR * g : fet : ma.tanh : *(gOut);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
