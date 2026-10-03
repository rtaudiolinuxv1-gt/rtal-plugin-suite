import("stdfaust.lib");

declare name "rtal-fold-space";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "West-coast wavefolder distortion with anti-aliased sine folding, symmetry, dynamics and resonant colour filter.";

presetMode = nentry("fold-space/[0]Factory Preset [style:menu{'Manual':0;'Buchla Bounce':1;'Glass Tongue':2;'Fold Storm':3}]", 0, 0, 3, 1);
foldManual = hslider("fold-space/[1]Folds [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
symmetryManual = hslider("fold-space/[2]Symmetry [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
dynamicsManual = hslider("fold-space/[3]Dynamics [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
colorManual = hslider("fold-space/[4]Color [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
resonanceManual = hslider("fold-space/[5]Resonance [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("fold-space/[6]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("fold-space/[7]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBuchla = (presetMode >= 0.5) * (presetMode < 1.5);
isGlass = (presetMode >= 1.5) * (presetMode < 2.5);
isStorm = presetMode >= 2.5;

selectPreset(manual, buchla, glass, storm) =
  manual * isManual +
  buchla * isBuchla +
  glass * isGlass +
  storm * isStorm;

folds = selectPreset(foldManual, 0.45, 0.25, 0.85);
symmetry = selectPreset(symmetryManual, 0.50, 0.70, 0.35);
dynamics = selectPreset(dynamicsManual, 0.70, 0.40, 0.30);
color = selectPreset(colorManual, 0.55, 0.80, 0.50);
resonance = selectPreset(resonanceManual, 0.35, 0.60, 0.50);
level = selectPreset(levelManual, 0.50, 0.50, 0.45);
mix = selectPreset(mixManual, 1.0, 0.90, 1.0);

process = _,_ : foldStereo
with {
  // First-order ADAA sine folder: sin() has antiderivative -cos(), so the
  // folded output is the mean of sin over each sample step.
  adaaSin(u) = ba.if(abs(du) < 0.0001, sin(0.5 * (u + u')), (cos(u') - cos(u)) / du)
  with {
    du = u - u';
  };

  foldVoice(env, x) = out
  with {
    // Harder picking pushes further into the folds when Dynamics is up.
    depth = 1.0 + folds * folds * 14.0 * (1.0 - dynamics * 0.6 + env * dynamics * 1.8);
    bias = (symmetry - 0.5) * 1.6;
    pre = x : fi.highpass(1, 40.0) : fi.lowpass(2, 6000.0);
    folded = adaaSin(pre * depth * ma.PI * 0.5 + bias) - sin(bias) : fi.dcblocker;
    colorHz = 300.0 * pow(30.0, color);
    q = 0.6 + resonance * resonance * 7.0;
    shaped = folded : fi.svf.lp(colorHz, q) : /(max(1.0, sqrt(q)));
    out = shaped * (0.1 + level * level * 0.9);
  };

  foldStereo(inL, inR) = outL, outR
  with {
    env = (inL + inR) * 0.5 : an.amp_follower_ar(0.003, 0.15) : *(4.0) : min(1.0);
    wetL = foldVoice(env, inL);
    wetR = foldVoice(env, inR);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
