import("stdfaust.lib");

declare name "rtal-vowel-mouth";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Talkbox-style formant filter that morphs through A-E-I-O-U from a knob, LFO or pick envelope.";

presetMode = nentry("vowel-mouth/[0]Factory Preset [style:menu{'Manual':0;'Talk Box':1;'Choir Robot':2;'Yeah Yeah':3}]", 0, 0, 3, 1);
vowelManual = hslider("vowel-mouth/[1]Vowel [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
talkManual = hslider("vowel-mouth/[2]Talk [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
rateManual = hslider("vowel-mouth/[3]LFO Rate [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
lfoManual = hslider("vowel-mouth/[4]LFO Depth [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
throatManual = hslider("vowel-mouth/[5]Throat [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
resonanceManual = hslider("vowel-mouth/[6]Resonance [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
driveManual = hslider("vowel-mouth/[7]Drive [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("vowel-mouth/[8]Mix [style:knob]", 0.85, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isTalk = (presetMode >= 0.5) * (presetMode < 1.5);
isChoir = (presetMode >= 1.5) * (presetMode < 2.5);
isYeah = presetMode >= 2.5;

selectPreset(manual, talk, choir, yeah) =
  manual * isManual +
  talk * isTalk +
  choir * isChoir +
  yeah * isYeah;

vowelKnob = selectPreset(vowelManual, 0.75, 0.10, 0.25);
talk = selectPreset(talkManual, 0.80, 0.0, 1.00);
rate = selectPreset(rateManual, 0.30, 0.25, 0.30);
lfo = selectPreset(lfoManual, 0.0, 0.70, 0.0);
throat = selectPreset(throatManual, 0.45, 0.30, 0.55);
resonance = selectPreset(resonanceManual, 0.60, 0.75, 0.70);
drive = selectPreset(driveManual, 0.55, 0.25, 0.65);
mix = selectPreset(mixManual, 1.00, 0.90, 1.00);

process = _,_ : mouthStereo
with {
  nVowels = 5;

  // Male-voice formant targets for U, O, A, E, I (ordered so a sweep goes closed-open-bright).
  f1Table = (325.0, 450.0, 800.0, 400.0, 290.0);
  f2Table = (700.0, 800.0, 1150.0, 1700.0, 1870.0);
  f3Table = (2530.0, 2830.0, 2900.0, 2600.0, 2800.0);
  a2Table = (0.25, 0.32, 0.50, 0.30, 0.20);
  a3Table = (0.08, 0.10, 0.14, 0.20, 0.25);

  lookup(table, pos) = ba.selectn(nVowels, i0, table) * (1.0 - frac) + ba.selectn(nVowels, i1, table) * frac
  with {
    p = max(0.0, min(nVowels - 1.001, pos));
    i0 = int(floor(p));
    i1 = min(nVowels - 1, i0 + 1);
    frac = p - floor(p);
  };

  wrap(x) = x - floor(x);
  lfoHz = 0.05 * pow(120.0, rate);
  lfoSig = 0.5 + 0.5 * sin(2.0 * ma.PI * ((+(lfoHz / ma.SR) : wrap) ~ _));

  mouthStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    // Fast attack, slower release: each pick opens the mouth and lets it close.
    env = mono : an.amp_follower_ar(0.006, 0.22) : *(5.0) : min(1.0);
    pos = (vowelKnob + talk * env + lfo * lfoSig) : min(1.0) : *(nVowels - 1);
    scale = 0.78 + throat * 0.5;

    f1 = lookup(f1Table, pos) * scale;
    f2 = lookup(f2Table, pos) * scale;
    f3 = lookup(f3Table, pos) * scale;
    a2 = lookup(a2Table, pos);
    a3 = lookup(a3Table, pos);

    q = 4.0 + resonance * 14.0;
    // Drive enriches the harmonics so the formants have something to shape.
    source = ma.tanh(mono * (1.0 + drive * 8.0)) / (1.0 + drive * 1.5);
    // resonbp peaks at gain * Q, so gains are divided by Q for unity-peak formants.
    voiced = source <: fi.resonbp(f1, q, 1.0 / q), fi.resonbp(f2, q * 1.3, a2 * 2.0 / (q * 1.3)), fi.resonbp(f3, q * 1.6, a3 * 3.0 / (q * 1.6)) :> _;
    wet = voiced * (2.4 + resonance * 0.7) : fi.highpass(1, 80.0);

    outL = inL * (1.0 - mix) + wet * mix;
    outR = inR * (1.0 - mix) + wet * mix;
  };
};
