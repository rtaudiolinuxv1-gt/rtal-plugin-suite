import("stdfaust.lib");

declare name "rtal-step-ladder";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Tempo-synced 16-step sequenced ladder filter with glide, accent envelope and drive.";

presetMode = nentry("step-ladder/[0]Factory Preset [style:menu{'Manual':0;'Acid Rhythm':1;'Gallop Sweep':2;'Slow Wave Pad':3}]", 0, 0, 3, 1);
bpmManual = hslider("step-ladder/[1]BPM", 120, 40, 240, 0.1);
divisionManual = nentry("step-ladder/[2]Division [style:menu{'1/4':0;'1/8':1;'1/16':2;'1/8 Triplet':3}]", 2, 0, 3, 1);
patternManual = nentry("step-ladder/[3]Pattern [style:menu{'Rise':0;'Fall':1;'Bounce':2;'Acid':3;'Gallop':4;'Scatter':5;'Pulse':6;'Wave':7}]", 3, 0, 7, 1);
baseManual = hslider("step-ladder/[4]Base [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
rangeManual = hslider("step-ladder/[5]Range [style:knob]", 0.65, 0.0, 1.0, 0.01) : si.smoo;
resonanceManual = hslider("step-ladder/[6]Resonance [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
glideManual = hslider("step-ladder/[7]Glide [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
accentManual = hslider("step-ladder/[8]Accent [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
driveManual = hslider("step-ladder/[9]Drive [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("step-ladder/[10]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isAcid = (presetMode >= 0.5) * (presetMode < 1.5);
isGallop = (presetMode >= 1.5) * (presetMode < 2.5);
isWave = presetMode >= 2.5;

selectPreset(manual, acid, gallop, wave) =
  manual * isManual +
  acid * isAcid +
  gallop * isGallop +
  wave * isWave;

// Tempo always follows the BPM control.
bpm = bpmManual;
division = int(selectPreset(divisionManual, 2, 2, 1));
pattern = int(selectPreset(patternManual, 3, 4, 7));
base = selectPreset(baseManual, 0.15, 0.20, 0.25);
range = selectPreset(rangeManual, 0.75, 0.60, 0.55);
resonance = selectPreset(resonanceManual, 0.75, 0.55, 0.45);
glide = selectPreset(glideManual, 0.15, 0.25, 0.80);
accent = selectPreset(accentManual, 0.50, 0.30, 0.10);
drive = selectPreset(driveManual, 0.50, 0.40, 0.20);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : ladderStereo
with {
  // Eight 16-step cutoff patterns, values 0..1, indexed pattern * 16 + step.
  patternTable = waveform{
    0, 0.0666667, 0.133333, 0.2, 0.266667, 0.333333, 0.4, 0.466667, 0.533333, 0.6, 0.666667, 0.733333, 0.8, 0.866667, 0.933333, 1,
    1, 0.933333, 0.866667, 0.8, 0.733333, 0.666667, 0.6, 0.533333, 0.466667, 0.4, 0.333333, 0.266667, 0.2, 0.133333, 0.0666667, 0,
    0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
    0.2, 0.8, 0.4, 1, 0.1, 0.6, 0.3, 0.9, 0.2, 0.7, 0.5, 1, 0.1, 0.8, 0.3, 0.6,
    1, 0.25, 0.55, 1, 0.25, 0.55, 1, 0.25, 0.55, 1, 0.25, 0.55, 1, 0.25, 0.55, 1,
    0.62, 0.15, 0.91, 0.38, 0.74, 0.05, 0.53, 0.84, 0.27, 0.96, 0.43, 0.12, 0.69, 0.33, 0.88, 0.21,
    1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
    0.5, 0.691, 0.854, 0.962, 1, 0.962, 0.854, 0.691, 0.5, 0.309, 0.146, 0.038, 0, 0.038, 0.146, 0.309};

  stepsPerBeat = ba.selectn(4, division, 1.0, 2.0, 4.0, 3.0);
  stepHz = bpm / 60.0 * stepsPerBeat;
  wrap(x) = x - floor(x);
  barPhase = (+(stepHz / 16.0 / ma.SR) : wrap) ~ _;
  stepIndex = min(15, int(barPhase * 16.0));
  stepValue = patternTable, int(pattern * 16 + stepIndex) : rdtable;

  glideSec = 0.001 + glide * glide * 0.25;
  baseHz = 80.0 * pow(10.0, base * 1.3);
  octaves = range * 6.0;
  q = 0.707 + resonance * resonance * 20.0;

  ladderVoice(cutoffHz, x) = x * (1.0 + drive * 3.0) : ma.tanh
    : ve.moogLadder(min(0.9, cutoffHz / (ma.SR * 0.5)), q)
    : *((1.0 + resonance * 1.4) / (1.0 + drive * 1.2));

  ladderStereo(inL, inR) = outL, outR
  with {
    env = (inL + inR) * 0.5 : an.amp_follower_ar(0.002, 0.12) : *(4.0) : min(1.0);
    position = stepValue : si.smooth(ba.tau2pole(glideSec));
    cutoff = baseHz * pow(2.0, position * octaves + env * accent * 2.5) : min(18000.0);
    wetL = ladderVoice(cutoff, inL);
    wetR = ladderVoice(cutoff, inR);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
