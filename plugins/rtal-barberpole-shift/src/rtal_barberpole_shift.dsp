import("stdfaust.lib");

declare name "rtal-barberpole-shift";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Bode-style frequency shifter with a delayed feedback loop for endless barberpole spirals.";

presetMode = nentry("barberpole-shift/[0]Factory Preset [style:menu{'Manual':0;'Endless Stair':1;'Sideband Chorus':2;'Broken Radio':3}]", 0, 0, 3, 1);
shiftManual = hslider("barberpole-shift/[1]Shift [style:knob]", 0.62, 0.0, 1.0, 0.001) : si.smoo;
fineManual = hslider("barberpole-shift/[2]Fine [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
feedbackManual = hslider("barberpole-shift/[3]Feedback [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
delayManual = hslider("barberpole-shift/[4]Delay [style:knob]", 0.30, 0.0, 1.0, 0.01);
toneManual = hslider("barberpole-shift/[5]Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
spreadManual = hslider("barberpole-shift/[6]Spread [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("barberpole-shift/[7]Mix [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isStair = (presetMode >= 0.5) * (presetMode < 1.5);
isChorus = (presetMode >= 1.5) * (presetMode < 2.5);
isRadio = presetMode >= 2.5;

selectPreset(manual, stair, chorus, radio) =
  manual * isManual +
  stair * isStair +
  chorus * isChorus +
  radio * isRadio;

// Shift knob: 0.5 is no shift; either side sweeps exponentially to +/-1200 Hz.
shiftKnob = selectPreset(shiftManual, 0.60, 0.53, 0.84);
fine = selectPreset(fineManual, 0.50, 0.58, 0.50);
feedback = selectPreset(feedbackManual, 0.78, 0.20, 0.58);
delayKnob = selectPreset(delayManual, 0.42, 0.10, 0.24) : si.smooth(ba.tau2pole(0.12));
tone = selectPreset(toneManual, 0.62, 0.80, 0.30);
spread = selectPreset(spreadManual, 0.50, 1.00, 0.20);
mix = selectPreset(mixManual, 0.55, 0.50, 0.62);

process = _,_ : shifterStereo
with {
  maxDelay = 131072;

  bipolar = (shiftKnob - 0.5) * 2.0;
  shiftHz = ma.signum(bipolar) * (pow(1201.0, abs(bipolar)) - 1.0) + (fine - 0.5) * 6.0;
  delaySamples = (2.0 + 600.0 * delayKnob * delayKnob) * 0.001 * ma.SR;

  // Niemitalo's 90-degree allpass pair, ~15 Hz to ~20 kHz at 44.1/48 kHz.
  section(a) = fi.tf2(a * a, 0.0, -1.0, 0.0, 0.0 - a * a);
  chainI = section(0.6923878) : section(0.9360654322959) : section(0.9882295226860) : section(0.9987488452737) : mem;
  chainQ = section(0.4021921162426) : section(0.8561710882420) : section(0.9722909545651) : section(0.9952884791278);

  wrap(x) = x - floor(x);
  phase(f) = (+(f / ma.SR) : wrap) ~ _;

  shifter(f, x) = i * cos(w) + q * sin(w)
  with {
    i = x : chainI;
    q = x : chainQ;
    w = 2.0 * ma.PI * phase(f);
  };

  loopTone = fi.lowpass(2, 1200.0 + tone * 10000.0) : fi.highpass(2, 60.0 + (1.0 - tone) * 240.0);

  // Each pass through the loop moves the spectrum by another shiftHz.
  spiral(f, x) = (+(x) : shifter(f)) ~ (de.fdelay3(maxDelay, delaySamples) : loopTone : *(feedback * 0.96) : ma.tanh);

  shifterStereo(inL, inR) = outL, outR
  with {
    // Spread pushes the right channel toward the mirrored shift direction.
    fL = shiftHz;
    fR = shiftHz * (1.0 - 2.0 * spread);
    wetL = inL : fi.highpass(1, 40.0) : spiral(fL);
    wetR = inR : fi.highpass(1, 40.0) : spiral(fR);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
