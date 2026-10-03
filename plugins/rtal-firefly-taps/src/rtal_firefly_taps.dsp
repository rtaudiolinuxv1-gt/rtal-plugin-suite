import("stdfaust.lib");

declare name "rtal-firefly-taps";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Eight-tap scattered delay with rhythmic tap patterns, swelling or fading tap shapes and stereo spread.";

presetMode = nentry("firefly-taps/[0]Factory Preset [style:menu{'Manual':0;'Bouncing Ball':1;'Golden Scatter':2;'Reverse Swell Taps':3}]", 0, 0, 3, 1);
patternManual = nentry("firefly-taps/[1]Pattern [style:menu{'Even':0;'Golden':1;'Accelerando':2;'Ritardando':3;'Scatter':4;'Bounce':5}]", 0, 0, 5, 1);
lengthManual = hslider("firefly-taps/[2]Length [style:knob]", 0.50, 0.0, 1.0, 0.01);
shapeManual = hslider("firefly-taps/[3]Shape [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
feedbackManual = hslider("firefly-taps/[4]Feedback [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
spreadManual = hslider("firefly-taps/[5]Spread [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("firefly-taps/[6]Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("firefly-taps/[7]Mix [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBall = (presetMode >= 0.5) * (presetMode < 1.5);
isGolden = (presetMode >= 1.5) * (presetMode < 2.5);
isSwell = presetMode >= 2.5;

selectPreset(manual, ball, golden, swell) =
  manual * isManual +
  ball * isBall +
  golden * isGolden +
  swell * isSwell;

pattern = int(selectPreset(patternManual, 5, 1, 3));
length = selectPreset(lengthManual, 0.55, 0.60, 0.50) : si.smooth(ba.tau2pole(0.15));
shape = selectPreset(shapeManual, 0.85, 0.60, 0.05);
feedback = selectPreset(feedbackManual, 0.10, 0.30, 0.15);
spread = selectPreset(spreadManual, 0.60, 0.90, 0.80);
tone = selectPreset(toneManual, 0.60, 0.55, 0.50);
mix = selectPreset(mixManual, 0.40, 0.38, 0.40);

process = _,_ : tapStereo
with {
  maxDelay = 262144;
  nTaps = 8;
  lengthSec = 0.2 * pow(12.0, length);

  // Tap positions as fractions of Length, indexed pattern * 8 + tap.
  positions = waveform{
    0.1250, 0.2500, 0.3750, 0.5000, 0.6250, 0.7500, 0.8750, 1.0000,
    0.0902, 0.2361, 0.3262, 0.4721, 0.6180, 0.7082, 0.8541, 0.9443,
    0.2222, 0.4167, 0.5833, 0.7222, 0.8333, 0.9167, 0.9722, 1.0000,
    0.0278, 0.0833, 0.1667, 0.2778, 0.4167, 0.5833, 0.7778, 1.0000,
    0.0900, 0.2100, 0.3800, 0.4400, 0.6100, 0.7300, 0.8600, 1.0000,
    0.3885, 0.6293, 0.7787, 0.8713, 0.9287, 0.9643, 0.9863, 1.0000};
  position(k) = positions, int(pattern * nTaps + k) : rdtable;

  // Shape: 1 fades the taps out, 0 swells them in, 0.5 keeps them flat.
  tapGain(k) = ba.if(shape >= 0.5, pow(1.0 - (shape - 0.5) * 1.6, k), pow(1.0 - (0.5 - shape) * 1.6, nTaps - 1 - k));
  tapPan(k) = 0.5 + spread * 0.45 * (2.0 * (k % 2) - 1.0) * (0.4 + 0.6 * k / (nTaps - 1));

  loopTone = fi.lowpass(2, 1500.0 + tone * tone * 12000.0) : fi.highpass(1, 90.0);

  tapStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    tap(k, x) = x : de.fdelay(maxDelay, min(float(maxDelay - 8), position(k) * lengthSec * ma.SR)) : *(tapGain(k));
    // The last tap feeds back so patterns can repeat.
    line = (+(mono) <: par(k, nTaps, tap(k))) ~ (si.bus(nTaps) : (si.block(nTaps - 1), _) : *(feedback * 0.9) : loopTone);
    norm = 1.0 / (1.0 + 0.25 * nTaps * (0.3 + abs(shape - 0.5)));
    wetL = line : par(k, nTaps, *(1.0 - tapPan(k))) :> loopTone : *(norm * 1.6);
    wetR = line : par(k, nTaps, *(tapPan(k))) :> loopTone : *(norm * 1.6);
    outL = inL * (1.0 - mix * 0.5) + wetL * mix;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix;
  };
};
