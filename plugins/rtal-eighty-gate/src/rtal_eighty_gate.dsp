import("stdfaust.lib");

declare name "rtal-eighty-gate";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Eighties gated reverb and reverse-gate: a huge room chopped off by a gate keyed from your playing.";

presetMode = nentry("eighty-gate/[0]Factory Preset [style:menu{'Manual':0;'Big Snare Room':1;'Reverse Gate':2;'Tight Ambience':3}]", 0, 0, 3, 1);
shapeManual = nentry("eighty-gate/[1]Shape [style:menu{'Gated':0;'Reverse':1}]", 0, 0, 1, 1);
sizeManual = hslider("eighty-gate/[2]Size [style:knob]", 0.65, 0.0, 1.0, 0.01) : si.smoo;
gateTimeManual = hslider("eighty-gate/[3]Gate Time [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
releaseManual = hslider("eighty-gate/[4]Gate Release [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
sensManual = hslider("eighty-gate/[5]Sensitivity [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("eighty-gate/[6]Tone [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("eighty-gate/[7]Mix [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isSnare = (presetMode >= 0.5) * (presetMode < 1.5);
isReverse = (presetMode >= 1.5) * (presetMode < 2.5);
isTight = presetMode >= 2.5;

selectPreset(manual, snare, reverse, tight) =
  manual * isManual +
  snare * isSnare +
  reverse * isReverse +
  tight * isTight;

shape = selectPreset(shapeManual, 0, 1, 0);
size = selectPreset(sizeManual, 0.80, 0.70, 0.40);
gateTime = selectPreset(gateTimeManual, 0.45, 0.55, 0.20);
release = selectPreset(releaseManual, 0.10, 0.05, 0.15);
sens = selectPreset(sensManual, 0.55, 0.55, 0.60);
tone = selectPreset(toneManual, 0.60, 0.50, 0.55);
mix = selectPreset(mixManual, 0.45, 0.50, 0.30);

process = _,_ : gateVerbStereo
with {
  // The room itself is long; the gate decides how much of it you hear.
  t60 = 1.5 + size * 5.0;
  room = re.zita_rev1_stereo(10, 200.0, 3000.0 + tone * 7000.0, t60 * 0.8, t60, 192000);

  holdSec = 0.08 + gateTime * gateTime * 0.7;
  releaseSec = 0.004 + release * release * 0.25;
  refractory = 0.06 * ma.SR;

  sinceTrigger(raw) = step ~ _
  with {
    step(c) = ba.if(raw * (c > refractory), 0.0, min(c + 1.0, 100000000.0));
  };

  gateVerbStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    fast = mono : abs : an.amp_follower_ar(0.0005, 0.02);
    slow = mono : abs : an.amp_follower_ar(0.02, 0.25);
    hit = fast > slow * 1.5 + 0.002 + (1.0 - sens) * 0.04;
    count = sinceTrigger(hit > hit');
    open = count < holdSec * ma.SR;
    // Gated: flat then chopped. Reverse: the gate ramps up through the hold, then cuts.
    ramp = min(1.0, count / (holdSec * ma.SR));
    target = open * ba.if(shape > 0.5, ramp * ramp, 1.0);
    // Snap open, close over the release time.
    gateGain = target : step ~ _
      with {
        step(prev, t) = ba.if(t > prev, t, prev + (t - prev) * (1.0 - exp(-1.0 / (releaseSec * ma.SR))));
      };

    wet = inL, inR : room;
    shaped = fi.highpass(1, 150.0 + (1.0 - tone) * 250.0);
    wetL = (wet : _, !) : shaped : *(gateGain * 1.6);
    wetR = (wet : !, _) : shaped : *(gateGain * 1.6);
    outL = inL * (1.0 - mix * 0.5) + wetL * mix;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix;
  };
};
