import("stdfaust.lib");

declare name "rtal-inverse-cathedral";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Reverse reverb: a big hall's tail is cut into windows and played backwards, so every phrase swells up out of nothing.";

presetMode = nentry("inverse-cathedral/[0]Factory Preset [style:menu{'Manual':0;'Classic Reverse Verb':1;'Long Inhale':2;'Ghost Choir':3}]", 0, 0, 3, 1);
swellManual = hslider("inverse-cathedral/[1]Swell Length [style:knob]", 0.45, 0.0, 1.0, 0.01);
sizeManual = hslider("inverse-cathedral/[2]Size [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
smoothManual = hslider("inverse-cathedral/[3]Smoothness [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
forwardManual = hslider("inverse-cathedral/[4]Forward Tail [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("inverse-cathedral/[5]Tone [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("inverse-cathedral/[6]Mix [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isClassic = (presetMode >= 0.5) * (presetMode < 1.5);
isInhale = (presetMode >= 1.5) * (presetMode < 2.5);
isGhost = presetMode >= 2.5;

selectPreset(manual, classic, inhale, ghost) =
  manual * isManual +
  classic * isClassic +
  inhale * isInhale +
  ghost * isGhost;

swell = selectPreset(swellManual, 0.40, 0.80, 0.55) : si.smooth(ba.tau2pole(0.2));
size = selectPreset(sizeManual, 0.60, 0.80, 0.90);
smoothness = selectPreset(smoothManual, 0.45, 0.70, 0.85);
forward = selectPreset(forwardManual, 0.10, 0.05, 0.35);
tone = selectPreset(toneManual, 0.55, 0.45, 0.65);
mix = selectPreset(mixManual, 0.45, 0.50, 0.55);

process = _,_ : inverseStereo
with {
  maxDelay = 524288;
  windowSec = 0.25 * pow(8.0, swell);
  t60 = 1.5 + size * 6.0;
  hall = re.zita_rev1_stereo(10, 150.0, 2500.0 + tone * 7000.0, t60 * 0.8, t60, 192000);

  wrap(x) = x - floor(x);
  phasor(hz) = (+(hz / ma.SR) : wrap) ~ _;
  // Complementary raised-cosine windows (as in rtal-backwards-sunday): A + B == 1.
  edge = 0.05 + smoothness * 0.45;
  fade(u) = 0.5 - 0.5 * cos(ma.PI * min(1.0, u));
  window(p) = ba.if(p < 0.5, fade(p / edge), 1.0 - fade((p - 0.5) / edge));

  reverse(x) = head(p) + head(wrap(p + 0.5))
  with {
    winSamples = windowSec * ma.SR;
    p = phasor(1.0 / windowSec);
    // Reading backwards: the delay grows twice as fast as time passes.
    head(q) = x : de.fdelay(maxDelay, min(float(maxDelay - 8), 8.0 + 2.0 * q * winSamples)) : *(window(q));
  };

  inverseStereo(inL, inR) = outL, outR
  with {
    tail = inL, inR : hall;
    tailL = tail : _, !;
    tailR = tail : !, _;
    shape = fi.highpass(1, 120.0) : fi.lowpass(2, 2000.0 + tone * tone * 12000.0);
    wetL = (tailL : reverse) + tailL * forward : shape;
    wetR = (tailR : reverse) + tailR * forward : shape;
    outL = inL * (1.0 - mix * 0.5) + wetL * mix * 1.3;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix * 1.3;
  };
};
