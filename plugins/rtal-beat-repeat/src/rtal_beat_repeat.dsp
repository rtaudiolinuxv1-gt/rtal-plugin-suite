import("stdfaust.lib");

declare name "rtal-beat-repeat";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Performance beat repeat: hold the switch to loop the last slice in time, with decay and falling-pitch glitch.";

presetMode = nentry("beat-repeat/[0]Factory Preset [style:menu{'Manual':0;'Eighth Stutter':1;'Tape Wind-Down':2;'Machine Gun':3}]", 0, 0, 3, 1);
repeat = checkbox("beat-repeat/[1]Repeat");
bpmManual = hslider("beat-repeat/[2]BPM", 120, 40, 240, 0.1);
divisionManual = nentry("beat-repeat/[3]Slice [style:menu{'1/4':0;'1/8':1;'1/16':2;'1/32':3;'1/8 Triplet':4}]", 1, 0, 4, 1);
decayManual = hslider("beat-repeat/[4]Decay [style:knob]", 0.10, 0.0, 1.0, 0.01) : si.smoo;
pitchManual = hslider("beat-repeat/[5]Pitch Drop [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
fadeManual = hslider("beat-repeat/[6]Slice Fade [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("beat-repeat/[7]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isEighth = (presetMode >= 0.5) * (presetMode < 1.5);
isWind = (presetMode >= 1.5) * (presetMode < 2.5);
isGun = presetMode >= 2.5;

selectPreset(manual, eighth, wind, gun) =
  manual * isManual +
  eighth * isEighth +
  wind * isWind +
  gun * isGun;

// Tempo always follows the BPM control.
bpm = bpmManual;
division = int(selectPreset(divisionManual, 1, 1, 3));
decay = selectPreset(decayManual, 0.05, 0.25, 0.0);
pitchDrop = selectPreset(pitchManual, 0.0, 0.60, 0.0);
fade = selectPreset(fadeManual, 0.30, 0.40, 0.10);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : repeatStereo
with {
  maxDelay = 524288;
  beats = ba.selectn(5, division, 1.0, 0.5, 0.25, 0.125, 0.3333333);
  sliceSamples = 60.0 / bpm * beats * ma.SR;
  // Repeats are limited by the buffer: each repeat reads one slice further back.
  maxRepeats = floor(float(maxDelay - 16) / sliceSamples) - 1.0;

  engaged = repeat > 0.5;
  // Samples since the switch went down (0 while released).
  elapsed = step ~ _
  with {
    step(c) = ba.if(engaged, c + 1.0, 0.0);
  };
  repeatIndex = min(maxRepeats, floor(elapsed / sliceSamples));
  inSlice = elapsed - floor(elapsed / sliceSamples) * sliceSamples;
  // Reading slice k means looking back (k + 1) slices from now.
  readDelay = sliceSamples * (repeatIndex + 1.0);

  fadeSamples = 16.0 + fade * fade * sliceSamples * 0.25;
  sliceWindow = min(1.0, min(inSlice / fadeSamples, (sliceSamples - inSlice) / fadeSamples));
  repeatGain = pow(1.0 - decay * 0.5, repeatIndex);
  semis = 0.0 - repeatIndex * pitchDrop * 1.5;
  wet = ba.if(engaged, 1.0, 0.0) : si.smooth(ba.tau2pole(0.004));

  voice(x) = x : de.fdelay(maxDelay, min(float(maxDelay - 8), readDelay))
    : ef.transpose(2048, 512, max(-24.0, semis))
    : *(sliceWindow * repeatGain);

  repeatStereo(inL, inR) = outL, outR
  with {
    outL = inL * (1.0 - wet * mix) + voice(inL) * wet * mix;
    outR = inR * (1.0 - wet * mix) + voice(inR) * wet * mix;
  };
};
