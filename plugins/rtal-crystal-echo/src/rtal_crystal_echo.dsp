import("stdfaust.lib");

declare name "rtal-crystal-echo";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Pitch-climbing echo: every repeat is transposed again, so echoes rise or fall in octaves, fifths or fourths.";

presetMode = nentry("crystal-echo/[0]Factory Preset [style:menu{'Manual':0;'Rising Octaves':1;'Falling Fifths':2;'Crystal Stairs':3}]", 0, 0, 3, 1);
intervalManual = nentry("crystal-echo/[1]Interval [style:menu{'+12':0;'+7':1;'+5':2;'+3':3;'-5':4;'-7':5;'-12':6}]", 0, 0, 6, 1);
timeManual = hslider("crystal-echo/[2]Time [style:knob]", 0.45, 0.0, 1.0, 0.01);
feedbackManual = hslider("crystal-echo/[3]Feedback [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
pureManual = hslider("crystal-echo/[4]Pitch Blend [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("crystal-echo/[5]Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
spreadManual = hslider("crystal-echo/[6]Spread [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("crystal-echo/[7]Mix [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isRising = (presetMode >= 0.5) * (presetMode < 1.5);
isFalling = (presetMode >= 1.5) * (presetMode < 2.5);
isStairs = presetMode >= 2.5;

selectPreset(manual, rising, falling, stairs) =
  manual * isManual +
  rising * isRising +
  falling * isFalling +
  stairs * isStairs;

interval = int(selectPreset(intervalManual, 0, 5, 3));
time = selectPreset(timeManual, 0.45, 0.50, 0.30) : si.smooth(ba.tau2pole(0.12));
feedback = selectPreset(feedbackManual, 0.55, 0.55, 0.70);
pure = selectPreset(pureManual, 1.0, 1.0, 0.85);
tone = selectPreset(toneManual, 0.70, 0.45, 0.65);
spread = selectPreset(spreadManual, 0.70, 0.60, 0.90);
mix = selectPreset(mixManual, 0.40, 0.42, 0.45);

process = _,_ : echoStereo
with {
  maxDelay = 262144;
  semis = ba.selectn(7, interval, 12.0, 7.0, 5.0, 3.0, -5.0, -7.0, -12.0);
  delaySec = 0.08 * pow(15.0, time);

  // The shifter sits in the loop: repeat n is transposed n times.
  loopTone = fi.lowpass(2, 1500.0 + tone * tone * 12000.0) : fi.highpass(1, 120.0);
  shiftPath = _ <: ef.transpose(2048, 512, semis) * pure, *(1.0 - pure) :> _;

  echo(seconds, x) = (+(x) : de.fdelay(maxDelay, min(float(maxDelay - 8), seconds * ma.SR)))
    ~ (shiftPath : loopTone : *(feedback * 0.95) : ma.tanh)
    : shiftPath;

  echoStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    wetL = mono : echo(delaySec);
    wetR = mono : echo(delaySec * (1.0 + spread * 0.33));
    outL = inL * (1.0 - mix * 0.5) + (wetL * (0.5 + spread * 0.5) + wetR * (0.5 - spread * 0.5)) * mix;
    outR = inR * (1.0 - mix * 0.5) + (wetR * (0.5 + spread * 0.5) + wetL * (0.5 - spread * 0.5)) * mix;
  };
};
