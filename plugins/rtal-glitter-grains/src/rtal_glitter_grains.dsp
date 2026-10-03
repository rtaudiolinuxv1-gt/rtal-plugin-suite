import("stdfaust.lib");

declare name "rtal-glitter-grains";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Eight-voice granular cloud delay with pitch sets, reverse grains and feedback.";

presetMode = nentry("glitter-grains/[0]Factory Preset [style:menu{'Manual':0;'Dust Halo':1;'Octave Swarm':2;'Backwards Snow':3}]", 0, 0, 3, 1);
pitchSetManual = nentry("glitter-grains/[1]Pitch Set [style:menu{'Unison':0;'Octave Up':1;'Octave Down':2;'Octaves':3;'Fifths':4;'Shimmer':5}]", 0, 0, 5, 1);
sizeManual = hslider("glitter-grains/[2]Size [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
densityManual = hslider("glitter-grains/[3]Density [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
sprayManual = hslider("glitter-grains/[4]Spray [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
detuneManual = hslider("glitter-grains/[5]Detune [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
reverseManual = hslider("glitter-grains/[6]Reverse [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
feedbackManual = hslider("glitter-grains/[7]Feedback [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("glitter-grains/[8]Width [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("glitter-grains/[9]Mix [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isDust = (presetMode >= 0.5) * (presetMode < 1.5);
isSwarm = (presetMode >= 1.5) * (presetMode < 2.5);
isSnow = presetMode >= 2.5;

selectPreset(manual, dust, swarm, snow) =
  manual * isManual +
  dust * isDust +
  swarm * isSwarm +
  snow * isSnow;

pitchSet = int(selectPreset(pitchSetManual, 0, 3, 5));
size = selectPreset(sizeManual, 0.30, 0.55, 0.72);
density = selectPreset(densityManual, 0.85, 0.70, 0.55);
spray = selectPreset(sprayManual, 0.55, 0.35, 0.80);
detune = selectPreset(detuneManual, 0.35, 0.10, 0.20);
reverse = selectPreset(reverseManual, 0.10, 0.20, 0.85);
feedback = selectPreset(feedbackManual, 0.25, 0.45, 0.50);
width = selectPreset(widthManual, 0.90, 0.80, 1.00);
mix = selectPreset(mixManual, 0.45, 0.42, 0.50);

process = _,_ : grainStereo
with {
  maxDelay = 262144;
  nVoices = 8;

  grainMs = 25.0 * pow(16.0, size);
  grainSamples = grainMs * 0.001 * ma.SR;
  grainHz = 1000.0 / grainMs;
  sprayLimit = min(1.4 * ma.SR, float(maxDelay) * 0.5);
  active = 1.0 + density * (nVoices - 1);

  wrap(x) = x - floor(x);
  basePhase = (+(grainHz / ma.SR) : wrap) ~ _;

  // Map a uniform random value in [0,1) to a semitone offset for the chosen set.
  pick(r, a, b, c) = ba.if(r < 0.333, a, ba.if(r < 0.666, b, c));
  semis(r) = ba.selectn(6, pitchSet,
    0.0,
    12.0,
    -12.0,
    pick(r, -12.0, 0.0, 12.0),
    pick(r, 0.0, 7.0, 12.0),
    pick(r, 12.0, 19.0, 24.0));

  grain(v, x) = left, right
  with {
    p = wrap(basePhase + v / nVoices);
    trig = p < p';
    rnd(k) = no.noises(nVoices * 4, v * 4 + k) : ba.sAndH(trig) : *(0.5) : +(0.5);
    rPos = rnd(0);
    rPitch = rnd(1);
    rPan = rnd(2);
    rDir = rnd(3);

    dir = ba.if(rDir < reverse, -1.0, 1.0);
    ratio = pow(2.0, (semis(rPitch) + (rPan - 0.5) * detune * 0.6) / 12.0) * dir;
    // Head start so a rising grain never reads ahead of the write head.
    headroom = max(0.0, ratio - 1.0) * grainSamples + 64.0;
    start = headroom + rPos * spray * sprayLimit;
    d = min(float(maxDelay - 8), start + (1.0 - ratio) * p * grainSamples);

    window = sin(ma.PI * p) * sin(ma.PI * p);
    on = min(1.0, max(0.0, active - v)) : si.smoo;
    sig = x : de.fdelay(maxDelay, d) : *(window * on);
    pan = 0.5 + (rPan - 0.5) * width;
    left = sig * (1.0 - pan);
    right = sig * pan;
  };

  cloud(x) = par(v, nVoices, grain(v, x)) :> *(norm), *(norm)
  with {
    norm = 1.6 / sqrt(active);
  };

  feedbackPath = + : *(feedback * 0.42) : fi.highpass(1, 120.0) : fi.lowpass(1, 9000.0) : ma.tanh;

  grainStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    wet = (+(mono) : cloud) ~ feedbackPath;
    wetL = wet : _, !;
    wetR = wet : !, _;
    outL = inL * (1.0 - mix * 0.5) + wetL * mix;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix;
  };
};
