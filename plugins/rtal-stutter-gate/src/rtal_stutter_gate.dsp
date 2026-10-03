import("stdfaust.lib");

declare name "rtal-stutter-gate";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Sixteen-step rhythmic slicer with pattern bank, swing, duty and stereo ping-pong.";

presetMode = nentry("stutter-gate/[0]Factory Preset [style:menu{'Manual':0;'Trance Chop':1;'Gallop Gate':2;'Ping Pong Glitch':3}]", 0, 0, 3, 1);
bpmManual = hslider("stutter-gate/[1]BPM", 120, 40, 240, 0.1);
divisionManual = nentry("stutter-gate/[2]Division [style:menu{'1/8':0;'1/16':1;'1/16 Triplet':2;'1/32':3}]", 1, 0, 3, 1);
patternManual = nentry("stutter-gate/[3]Pattern [style:menu{'Straight':0;'Gallop':1;'Offbeat':2;'Trance':3;'Broken':4;'Stutter':5;'Sparse':6;'Sixteenths':7}]", 3, 0, 7, 1);
depthManual = hslider("stutter-gate/[4]Depth [style:knob]", 0.90, 0.0, 1.0, 0.01) : si.smoo;
dutyManual = hslider("stutter-gate/[5]Duty [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
smoothManual = hslider("stutter-gate/[6]Smooth [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
swingManual = hslider("stutter-gate/[7]Swing [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
stereoManual = hslider("stutter-gate/[8]Ping Pong [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isTrance = (presetMode >= 0.5) * (presetMode < 1.5);
isGallop = (presetMode >= 1.5) * (presetMode < 2.5);
isGlitch = presetMode >= 2.5;

selectPreset(manual, trance, gallop, glitch) =
  manual * isManual +
  trance * isTrance +
  gallop * isGallop +
  glitch * isGlitch;

// Tempo always follows the BPM control so presets stay in time with the song.
bpm = bpmManual;
division = int(selectPreset(divisionManual, 1, 1, 3));
pattern = int(selectPreset(patternManual, 3, 1, 4));
depth = selectPreset(depthManual, 1.00, 0.85, 0.95);
duty = selectPreset(dutyManual, 0.65, 0.80, 0.45);
smooth = selectPreset(smoothManual, 0.20, 0.30, 0.08);
swing = selectPreset(swingManual, 0.0, 0.0, 0.25);
stereo = selectPreset(stereoManual, 0.0, 0.0, 1.0);

process = _,_ : gateStereo
with {
  // Bit n of each mask opens step n:
  //   Straight   x.x.x.x.x.x.x.x.    Gallop  x.xxx.xxx.xxx.xx
  //   Offbeat    ..x...x...x...x.    Trance  xx.xx.xx.xx.x.xx
  //   Broken     x..x..x.x.xx..x.    Stutter xxxx....xxxx....
  //   Sparse     x.....x.x....x..    Sixteenths (all on)
  mask = ba.selectn(8, pattern, 21845, 56797, 17476, 55003, 19785, 3855, 8513, 65535);

  stepsPerBeat = ba.selectn(4, division, 2.0, 4.0, 6.0, 8.0);
  stepHz = bpm / 60.0 * stepsPerBeat;

  wrap(x) = x - floor(x);
  // Phase across a 16-step bar.
  barPhase = (+(stepHz / 16.0 / ma.SR) : wrap) ~ _;

  // Swing stretches the first step of each pair and shortens the second.
  pairPos = barPhase * 8.0;
  pairIndex = floor(pairPos);
  inPair = pairPos - pairIndex;
  split = 0.5 + swing * 0.25;
  second = inPair >= split;
  stepIndex = int(pairIndex * 2.0 + second) % 16;
  stepPhase = ba.if(second, (inPair - split) / (1.0 - split), inPair / split);

  bit(i) = (mask >> i) & 1;
  open = bit(stepIndex) * (stepPhase < (0.1 + duty * 0.9));
  // Ping Pong sends alternate steps to alternate sides.
  oddStep = stepIndex % 2;
  gateL = open * (1.0 - stereo * oddStep);
  gateR = open * (1.0 - stereo * (1 - oddStep));

  smoothTau = 0.0008 + smooth * smooth * 0.03;
  shape(g) = g : si.smooth(ba.tau2pole(smoothTau));
  gain(g) = 1.0 - depth * (1.0 - shape(g));

  gateStereo(inL, inR) = inL * gain(gateL), inR * gain(gateR);
};
