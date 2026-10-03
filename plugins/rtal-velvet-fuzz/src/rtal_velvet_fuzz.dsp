import("stdfaust.lib");

declare name "rtal-velvet-fuzz";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Two-stage fuzz with bias starve, sputter gate, octave fuzz and a scoopable tone stack, using anti-aliased clipping.";

presetMode = nentry("velvet-fuzz/[0]Factory Preset [style:menu{'Manual':0;'Round Face':1;'Muffin Wall':2;'Velcro Splatter':3}]", 0, 0, 3, 1);
fuzzManual = hslider("velvet-fuzz/[1]Fuzz [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
starveManual = hslider("velvet-fuzz/[2]Starve [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
gateManual = hslider("velvet-fuzz/[3]Gate [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
octaveManual = hslider("velvet-fuzz/[4]Octave [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("velvet-fuzz/[5]Tone [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
midsManual = hslider("velvet-fuzz/[6]Mids [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("velvet-fuzz/[7]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isFace = (presetMode >= 0.5) * (presetMode < 1.5);
isMuff = (presetMode >= 1.5) * (presetMode < 2.5);
isVelcro = presetMode >= 2.5;

selectPreset(manual, face, muff, velcro) =
  manual * isManual +
  face * isFace +
  muff * isMuff +
  velcro * isVelcro;

fuzz = selectPreset(fuzzManual, 0.55, 0.80, 0.70);
starve = selectPreset(starveManual, 0.10, 0.05, 0.85);
gate = selectPreset(gateManual, 0.10, 0.25, 0.55);
octave = selectPreset(octaveManual, 0.0, 0.0, 0.40);
tone = selectPreset(toneManual, 0.45, 0.55, 0.60);
mids = selectPreset(midsManual, 0.70, 0.15, 0.45);
level = selectPreset(levelManual, 0.50, 0.50, 0.50);

process = _,_ : fuzzStereo
with {
  // First-order antiderivative anti-aliasing for tanh: average the clipper's
  // antiderivative across each sample step instead of sampling it.
  logCosh(x) = abs(x) + log(1.0 + exp(-2.0 * abs(x))) - log(2.0);
  adaaTanh(x) = ba.if(abs(dx) < 0.0001, ma.tanh(0.5 * (x + x')), (logCosh(x) - logCosh(x')) / dx)
  with {
    dx = x - x';
  };

  // A starved transistor clips earlier and lopsided; bias shifts the operating point.
  stage(gain, bias, x) = (adaaTanh(x * gain + bias) - ma.tanh(bias)) : fi.dcblocker;

  fuzzVoice(x) = out
  with {
    gainA = 2.0 + fuzz * fuzz * 60.0;
    gainB = 1.5 + fuzz * 6.0;
    bias = starve * 0.9;

    clean = x : fi.highpass(1, 60.0 + starve * 140.0);
    // Sputter gate: when Starve is up the gate chatters on decaying notes.
    env = clean : an.amp_follower_ar(0.002, 0.05);
    threshold = gate * gate * 0.06;
    gateGain = (env - threshold) / max(0.0001, threshold * 0.5 + 0.0005) : max(0.0) : min(1.0) : si.smooth(ba.tau2pole(0.002 + (1.0 - starve) * 0.01));

    // Octave fuzz: rectifier before the clipper folds the wave and doubles the pitch.
    folded = clean * (1.0 - octave) + abs(clean) * octave * 1.6;

    first = folded * gateGain : stage(gainA, bias);
    second = first : fi.lowpass(1, 5500.0) : stage(gainB, bias * 0.5);

    // Muff-style tone stack: blend a lowpass and a highpass; Mids fills the scoop back in.
    low = second : fi.lowpass(1, 600.0);
    high = second : fi.highpass(1, 1100.0);
    scooped = low * (1.0 - tone) + high * tone;
    toned = scooped * (1.0 - mids) + second * mids;
    out = toned : fi.lowpass(2, 7500.0) : *(0.12 + level * level * 1.2);
  };

  fuzzStereo(inL, inR) = out, out
  with {
    out = (inL + inR) * 0.5 : fuzzVoice;
  };
};
