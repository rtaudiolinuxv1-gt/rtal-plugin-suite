import("stdfaust.lib");

declare name "rtal-pixel-rot";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Bit crusher and sample-rate reducer with clock jitter, glitch freezes and tone shaping.";

presetMode = nentry("pixel-rot/[0]Factory Preset [style:menu{'Manual':0;'Handheld Console':1;'Dusty Sampler':2;'Broken Modem':3}]", 0, 0, 3, 1);
bitsManual = hslider("pixel-rot/[1]Bits", 8.0, 1.0, 16.0, 0.01) : si.smoo;
rateManual = hslider("pixel-rot/[2]Rate [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
jitterManual = hslider("pixel-rot/[3]Jitter [style:knob]", 0.10, 0.0, 1.0, 0.01) : si.smoo;
driveManual = hslider("pixel-rot/[4]Drive [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
glitchManual = hslider("pixel-rot/[5]Glitch [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("pixel-rot/[6]Tone [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("pixel-rot/[7]Mix [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isConsole = (presetMode >= 0.5) * (presetMode < 1.5);
isSampler = (presetMode >= 1.5) * (presetMode < 2.5);
isModem = presetMode >= 2.5;

selectPreset(manual, console, sampler, modem) =
  manual * isManual +
  console * isConsole +
  sampler * isSampler +
  modem * isModem;

bits = selectPreset(bitsManual, 4.0, 12.0, 3.0);
rate = selectPreset(rateManual, 0.45, 0.62, 0.20);
jitter = selectPreset(jitterManual, 0.0, 0.08, 0.60);
drive = selectPreset(driveManual, 0.30, 0.20, 0.55);
glitch = selectPreset(glitchManual, 0.0, 0.0, 0.70);
tone = selectPreset(toneManual, 0.85, 0.45, 0.60);
mix = selectPreset(mixManual, 1.0, 1.0, 0.90);

process = _,_ : crushStereo
with {
  wrap(x) = x - floor(x);

  // Target sample rate 400 Hz .. 44.1 kHz with exponential feel; jitter wobbles the clock.
  targetHz = 400.0 * pow(110.0, rate) * (1.0 + no.lfnoise(300.0) * jitter * 0.45);
  clockPhase = (+(min(0.999, targetHz / ma.SR)) : wrap) ~ _;
  // Glitch occasionally stops the clock, freezing a sample into a buzz.
  frozen = (no.lfnoise(3.0 + glitch * 9.0) * 0.5 + 0.5) > (1.0 - glitch * 0.45);
  tick = (clockPhase < clockPhase') * (1 - frozen);

  quantize(x) = floor(x * steps + 0.5) / steps
  with {
    steps = pow(2.0, bits - 1.0);
  };

  crush(x) = x : ma.tanh : quantize : ba.sAndH(tick);

  crushStereo(inL, inR) = outL, outR
  with {
    g = 1.0 + drive * drive * 8.0;
    pre(x) = x * g / (1.0 + drive * 2.0);
    post = fi.lowpass(2, 1200.0 + tone * tone * 16000.0) : fi.dcblocker;
    wetL = inL : pre : crush : post;
    wetR = inR : pre : crush : post;
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
