import("stdfaust.lib");

declare name "rtal-harmonic-forge";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Harmonic mixer: Chebyshev waveshaping adds exactly the 2nd, 3rd, 4th and 5th harmonics you dial in.";

presetMode = nentry("harmonic-forge/[0]Factory Preset [style:menu{'Manual':0;'Tube Warmth':1;'Hollow Clarinet':2;'Bright Organ':3}]", 0, 0, 3, 1);
fundManual = hslider("harmonic-forge/[1]Fundamental [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
h2Manual = hslider("harmonic-forge/[2]2nd [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
h3Manual = hslider("harmonic-forge/[3]3rd [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
h4Manual = hslider("harmonic-forge/[4]4th [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
h5Manual = hslider("harmonic-forge/[5]5th [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
focusManual = hslider("harmonic-forge/[6]Focus [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("harmonic-forge/[7]Mix [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isTube = (presetMode >= 0.5) * (presetMode < 1.5);
isClarinet = (presetMode >= 1.5) * (presetMode < 2.5);
isOrgan = presetMode >= 2.5;

selectPreset(manual, tube, clarinet, organ) =
  manual * isManual +
  tube * isTube +
  clarinet * isClarinet +
  organ * isOrgan;

fund = selectPreset(fundManual, 1.0, 1.0, 0.9);
h2 = selectPreset(h2Manual, 0.40, 0.0, 0.50);
h3 = selectPreset(h3Manual, 0.10, 0.55, 0.30);
h4 = selectPreset(h4Manual, 0.10, 0.0, 0.40);
h5 = selectPreset(h5Manual, 0.0, 0.35, 0.20);
focus = selectPreset(focusManual, 0.40, 0.45, 0.50);
mix = selectPreset(mixManual, 0.55, 0.75, 0.70);

process = _,_ : forgeStereo
with {
  // For x = cos(t), T_n(x) = cos(n t): Chebyshev polynomials turn a sine
  // into exactly its nth harmonic. Constant terms are dropped so silence stays silent.
  t2(x) = 2.0 * x * x;
  t3(x) = 4.0 * x * x * x - 3.0 * x;
  t4(x) = 8.0 * x * x * x * x - 8.0 * x * x;
  t5(x) = 16.0 * x * x * x * x * x - 20.0 * x * x * x + 5.0 * x;

  forgeVoice(x) = out
  with {
    // Focus isolates the fundamental so the generated harmonics are clean.
    focusHz = 300.0 * pow(10.0, focus);
    core = x : fi.lowpass(4, focusHz);
    // Normalise to full scale for the polynomials, then restore the level.
    env = core : abs : an.amp_follower_ar(0.0008, 0.12) : max(0.0005);
    u = core / env : max(-1.0) : min(1.0);
    shaped = u * fund + t2(u) * h2 + t3(u) * h3 + t4(u) * h4 + t5(u) * h5 : fi.dcblocker;
    norm = 1.0 / (1.0 + (h2 + h3 + h4 + h5) * 0.6);
    // Above the focus band the original guitar passes through untouched.
    out = shaped * env * norm + (x : fi.highpass(4, focusHz));
  };

  forgeStereo(inL, inR) = outL, outR
  with {
    outL = inL * (1.0 - mix) + forgeVoice(inL) * mix;
    outR = inR * (1.0 - mix) + forgeVoice(inR) * mix;
  };
};
