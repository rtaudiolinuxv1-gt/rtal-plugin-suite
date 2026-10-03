import("stdfaust.lib");

declare name "rtal-backwards-sunday";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Reverse delay with crossfaded twin heads, octave-up reverse mode and feedback.";

presetMode = nentry("backwards-sunday/[0]Factory Preset [style:menu{'Manual':0;'Tomorrow Never':1;'Rewind Bells':2;'Mirror Pad':3}]", 0, 0, 3, 1);
modeManual = nentry("backwards-sunday/[1]Mode [style:menu{'Reverse':0;'Reverse Octave':1;'Reverse + Forward':2}]", 0, 0, 2, 1);
timeManual = hslider("backwards-sunday/[2]Time [style:knob]", 0.45, 0.0, 1.0, 0.01);
feedbackManual = hslider("backwards-sunday/[3]Feedback [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
smearManual = hslider("backwards-sunday/[4]Smear [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("backwards-sunday/[5]Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("backwards-sunday/[6]Width [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("backwards-sunday/[7]Mix [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isTomorrow = (presetMode >= 0.5) * (presetMode < 1.5);
isBells = (presetMode >= 1.5) * (presetMode < 2.5);
isMirror = presetMode >= 2.5;

selectPreset(manual, tomorrow, bells, mirror) =
  manual * isManual +
  tomorrow * isTomorrow +
  bells * isBells +
  mirror * isMirror;

mode = int(selectPreset(modeManual, 0, 1, 2));
time = selectPreset(timeManual, 0.50, 0.32, 0.78) : si.smooth(ba.tau2pole(0.2));
feedback = selectPreset(feedbackManual, 0.30, 0.45, 0.62);
smear = selectPreset(smearManual, 0.30, 0.55, 0.85);
tone = selectPreset(toneManual, 0.58, 0.80, 0.45);
width = selectPreset(widthManual, 0.45, 0.70, 0.90);
mix = selectPreset(mixManual, 0.55, 0.42, 0.50);

process = _,_ : reverseStereo
with {
  maxDelay = 524288;

  windowSec = 0.15 * pow(10.0, time);
  // Read head speed relative to the write head: -1 plays back reversed, -2 reversed an octave up.
  readSpeed = ba.if(mode == 1, -2.0, -1.0);
  slope = 1.0 - readSpeed;

  wrap(x) = x - floor(x);
  phasor(hz) = (+(hz / ma.SR) : wrap) ~ _;

  // Complementary raised-cosine fades: head A fades in over the first half of its
  // cycle and out over the second, so A + B (half a cycle apart) always sum to 1.
  // Smear lengthens the crossfades.
  edge = 0.04 + smear * 0.46;
  fade(u) = 0.5 - 0.5 * cos(ma.PI * min(1.0, u));
  window(p) = ba.if(p < 0.5, fade(p / edge), 1.0 - fade((p - 0.5) / edge));

  reverseLine(seconds, x) = headA + headB
  with {
    winSamples = seconds * ma.SR;
    p = phasor(1.0 / seconds);
    head(q) = x : de.fdelay(maxDelay, min(float(maxDelay - 8), 8.0 + slope * q * winSamples)) : *(window(q));
    headA = head(p);
    headB = head(wrap(p + 0.5));
  };

  forwardGain = ba.if(mode == 2, 0.55, 0.0);
  forwardEcho(seconds, x) = x : de.fdelay(maxDelay, min(float(maxDelay - 8), seconds * ma.SR)) : *(forwardGain);

  loopTone = fi.lowpass(2, 1500.0 + tone * 9000.0) : fi.highpass(1, 90.0);

  // Both heads share the loop, so the loop gain is normalised by their combined level.
  channel(seconds, x) = (+(x) <: reverseLine(seconds) + forwardEcho(seconds)) ~ (loopTone : *(feedback * 0.95 / (1.0 + forwardGain)) : ma.tanh);

  reverseStereo(inL, inR) = outL, outR
  with {
    secondsL = windowSec;
    secondsR = windowSec * (1.0 + width * 0.18);
    mono = (inL + inR) * 0.5;
    wetL = (mono * (1.0 - width * 0.5) + inL * width * 0.5) : channel(secondsL) : loopTone;
    wetR = (mono * (1.0 - width * 0.5) + inR * width * 0.5) : channel(secondsR) : loopTone;
    outL = inL * (1.0 - mix * 0.5) + wetL * mix;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix;
  };
};
