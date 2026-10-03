import("stdfaust.lib");

declare name "rtal-digital-dust";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Degrading digital delay: every repeat is re-crushed, so echoes crumble into bit dust.";

presetMode = nentry("digital-dust/[0]Factory Preset [style:menu{'Manual':0;'Early Sampler Echo':1;'Crumbling Repeats':2;'Glitch Cascade':3}]", 0, 0, 3, 1);
timeManual = hslider("digital-dust/[1]Time [style:knob]", 0.45, 0.0, 1.0, 0.01);
feedbackManual = hslider("digital-dust/[2]Feedback [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
crushManual = hslider("digital-dust/[3]Crush [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
decimateManual = hslider("digital-dust/[4]Decimate [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
jitterManual = hslider("digital-dust/[5]Jitter [style:knob]", 0.10, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("digital-dust/[6]Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("digital-dust/[7]Width [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("digital-dust/[8]Mix [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isSampler = (presetMode >= 0.5) * (presetMode < 1.5);
isCrumble = (presetMode >= 1.5) * (presetMode < 2.5);
isGlitch = presetMode >= 2.5;

selectPreset(manual, sampler, crumble, glitch) =
  manual * isManual +
  sampler * isSampler +
  crumble * isCrumble +
  glitch * isGlitch;

time = selectPreset(timeManual, 0.40, 0.50, 0.20) : si.smooth(ba.tau2pole(0.1));
feedback = selectPreset(feedbackManual, 0.40, 0.75, 0.70);
crush = selectPreset(crushManual, 0.25, 0.60, 0.80);
decimate = selectPreset(decimateManual, 0.35, 0.40, 0.75);
jitter = selectPreset(jitterManual, 0.05, 0.15, 0.60);
tone = selectPreset(toneManual, 0.50, 0.55, 0.65);
width = selectPreset(widthManual, 0.40, 0.70, 0.90);
mix = selectPreset(mixManual, 0.35, 0.40, 0.45);

process = _,_ : dustStereo
with {
  maxDelay = 262144;
  delaySec = 0.04 * pow(30.0, time);

  wrap(x) = x - floor(x);

  // The degrader sits inside the feedback loop, so each pass loses more resolution.
  degrade(seed, x) = x : ma.tanh : quantize : ba.sAndH(tick) : fi.lowpass(2, 1500.0 + tone * tone * 14000.0)
  with {
    bits = 14.0 - crush * 11.0;
    steps = pow(2.0, bits - 1.0);
    quantize(v) = floor(v * steps + 0.5) / steps;
    rateHz = 44100.0 / (1.0 + decimate * decimate * 14.0) * (1.0 + no.noises(2, seed) * jitter * 0.3);
    clock = (+(min(0.999, rateHz / ma.SR)) : wrap) ~ _;
    tick = clock < clock';
  };

  echo(seed, seconds, x) = (+(x) : de.fdelay(maxDelay, min(float(maxDelay - 8), seconds * ma.SR)) : degrade(seed)) ~ (*(feedback * 0.97) : fi.highpass(1, 100.0));

  dustStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    wetL = (mono * (1.0 - width * 0.5) + inL * width * 0.5) : echo(0, delaySec);
    wetR = (mono * (1.0 - width * 0.5) + inR * width * 0.5) : echo(1, delaySec * (1.0 + width * 0.25));
    outL = inL * (1.0 - mix * 0.5) + wetL * mix;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix;
  };
};
