import("stdfaust.lib");

declare name "rtal-endless-stair";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Barberpole flanger: a Shepard-style sweep that rises or falls forever without ever resetting.";

presetMode = nentry("endless-stair/[0]Factory Preset [style:menu{'Manual':0;'Rising Forever':1;'Falling Jet':2;'Slow Cathedral Stair':3}]", 0, 0, 3, 1);
directionManual = nentry("endless-stair/[1]Direction [style:menu{'Up':0;'Down':1}]", 0, 0, 1, 1);
rateManual = hslider("endless-stair/[2]Rate [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
rangeManual = hslider("endless-stair/[3]Range [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
feedbackManual = hslider("endless-stair/[4]Feedback [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
voicesManual = nentry("endless-stair/[5]Voices [style:menu{'3':0;'4':1;'6':2}]", 1, 0, 2, 1);
widthManual = hslider("endless-stair/[6]Width [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("endless-stair/[7]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isRising = (presetMode >= 0.5) * (presetMode < 1.5);
isFalling = (presetMode >= 1.5) * (presetMode < 2.5);
isSlow = presetMode >= 2.5;

selectPreset(manual, rising, falling, slow) =
  manual * isManual +
  rising * isRising +
  falling * isFalling +
  slow * isSlow;

direction = selectPreset(directionManual, 0, 1, 0);
rate = selectPreset(rateManual, 0.40, 0.50, 0.15);
range = selectPreset(rangeManual, 0.75, 0.70, 0.85);
feedback = selectPreset(feedbackManual, 0.60, 0.70, 0.50);
voicesSel = int(selectPreset(voicesManual, 1, 1, 2));
width = selectPreset(widthManual, 0.60, 0.70, 0.90);
mix = selectPreset(mixManual, 0.50, 0.50, 0.50);

process = _,_ : stairStereo
with {
  maxDelay = 2048;
  maxVoices = 6;
  nVoices = ba.selectn(3, voicesSel, 3.0, 4.0, 6.0);
  // One full climb takes 30 s down to 1.5 s.
  sweepHz = 1.0 / (30.0 * pow(0.05, rate));
  shortMs = 0.25;
  longMs = shortMs * pow(2.0, 2.0 + range * 4.0);

  wrap(x) = x - floor(x);
  basePhase = (+(sweepHz / ma.SR) : wrap) ~ _;

  // Each voice glides exponentially from long to short delay (notches rise) and
  // fades in and out with a raised-cosine window, so the sum never jumps.
  voice(v, x) = comb * window * active
  with {
    p = wrap(basePhase + v / nVoices);
    travel = ba.if(direction > 0.5, p, 1.0 - p);
    delayMs = shortMs * pow(longMs / shortMs, travel);
    comb = x : (+ : de.fdelay3(maxDelay, delayMs * 0.001 * ma.SR)) ~ (*(feedback * 0.85) : ma.tanh);
    window = 0.5 - 0.5 * cos(2.0 * ma.PI * p);
    active = v < nVoices;
  };

  stairStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    voices = par(v, maxVoices, voice(v, mono));
    pan(v) = 0.5 + width * 0.4 * (2.0 * (v % 2) - 1.0);
    norm = 2.0 / nVoices;
    wetL = voices : par(v, maxVoices, *(1.0 - pan(v))) :> *(norm);
    wetR = voices : par(v, maxVoices, *(pan(v))) :> *(norm);
    fbNorm = 1.0 / (1.0 + feedback * 0.8);
    outL = (inL * (1.0 - mix) + (wetL + mono * 0.5) * mix) * fbNorm * 1.3;
    outR = (inR * (1.0 - mix) + (wetR + mono * 0.5) * mix) * fbNorm * 1.3;
  };
};
