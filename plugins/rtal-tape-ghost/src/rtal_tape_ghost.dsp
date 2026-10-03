import("stdfaust.lib");

declare name "rtal-tape-ghost";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Three-head tape echo with wow, flutter, saturation and aging tape.";

presetMode = nentry("tape-ghost/[0]Factory Preset [style:menu{'Manual':0;'Slapback Shed':1;'Space Haunt':2;'Melted Reel':3}]", 0, 0, 3, 1);
timeManual = hslider("tape-ghost/[1]Time [style:knob]", 0.42, 0.0, 1.0, 0.01);
headsManual = hslider("tape-ghost/[2]Heads [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
feedbackManual = hslider("tape-ghost/[3]Feedback [style:knob]", 0.42, 0.0, 1.0, 0.01) : si.smoo;
wowManual = hslider("tape-ghost/[4]Wow [style:knob]", 0.28, 0.0, 1.0, 0.01) : si.smoo;
flutterManual = hslider("tape-ghost/[5]Flutter [style:knob]", 0.22, 0.0, 1.0, 0.01) : si.smoo;
ageManual = hslider("tape-ghost/[6]Age [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("tape-ghost/[7]Width [style:knob]", 0.65, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("tape-ghost/[8]Mix [style:knob]", 0.32, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isSlap = (presetMode >= 0.5) * (presetMode < 1.5);
isSpace = (presetMode >= 1.5) * (presetMode < 2.5);
isMelt = presetMode >= 2.5;

selectPreset(manual, slap, space, melt) =
  manual * isManual +
  slap * isSlap +
  space * isSpace +
  melt * isMelt;

// Time glides slowly so knob moves pitch-bend the repeats like a real tape transport.
time = selectPreset(timeManual, 0.08, 0.52, 0.66) : si.smooth(ba.tau2pole(0.28));
heads = selectPreset(headsManual, 0.0, 1.0, 0.55);
feedback = selectPreset(feedbackManual, 0.12, 0.62, 0.74);
wow = selectPreset(wowManual, 0.10, 0.30, 0.86);
flutter = selectPreset(flutterManual, 0.18, 0.24, 0.58);
age = selectPreset(ageManual, 0.22, 0.46, 0.82);
width = selectPreset(widthManual, 0.30, 0.82, 0.70);
mix = selectPreset(mixManual, 0.30, 0.36, 0.44);

process = _,_ : tapeStereo
with {
  maxDelay = 262144;

  // 40 ms .. 900 ms on the longest head, exponential feel.
  longestMs = 40.0 * pow(22.5, time);
  baseSamples = longestMs * 0.001 * ma.SR;

  // Transport speed variation shared by every head.
  wowSig = os.osc(0.55) * 0.7 + no.lfnoise(1.3) * 0.3;
  flutterSig = os.osc(6.7) * 0.6 + os.osc(11.3) * 0.25 + no.lfnoise(18.0) * 0.15;
  speedMod = 1.0 + wowSig * wow * 0.010 + flutterSig * flutter * 0.0022;

  head(ratio) = de.fdelay3(maxDelay, max(4.0, min(float(maxDelay - 8), baseSamples * ratio * speedMod)));

  // Head 3 is always on; Heads brings in head 2 then head 1.
  g2 = min(1.0, heads * 2.0);
  g1 = max(0.0, heads * 2.0 - 1.0);
  headNorm = 1.0 / (1.0 + 0.55 * (g1 + g2));

  drive = 1.0 + age * 3.5;
  tapeSat(x) = ma.tanh(x * drive) / drive * (1.0 + age * 0.6);
  loopTone = fi.lowpass(2, 9500.0 - age * 7200.0) : fi.highpass(1, 70.0 + age * 160.0);

  // Bump around 120 Hz from the playback head gap.
  headBump = fi.peak_eq_cq(2.5 + age * 2.0, 120.0, 0.9);

  tapeEngine(x) = (+(x) : tapeSat : headBump <: head(0.333), head(0.666), head(1.0)) ~ feedbackPath
  with {
    feedbackPath(h1, h2, h3) = (h1 * g1 * 0.4 + h2 * g2 * 0.5 + h3) * feedback * 0.98 : loopTone;
  };

  tapeStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    taps = mono : tapeEngine;
    h1 = taps : _, !, ! : *(g1);
    h2 = taps : !, _, ! : *(g2);
    h3 = taps : !, !, _;

    wetL = (h1 * (0.5 + width * 0.5) + h2 * (0.5 - width * 0.5) + h3) * headNorm : loopTone;
    wetR = (h1 * (0.5 - width * 0.5) + h2 * (0.5 + width * 0.5) + h3) * headNorm : loopTone;

    outL = inL * (1.0 - mix * 0.5) + wetL * mix;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix;
  };
};
