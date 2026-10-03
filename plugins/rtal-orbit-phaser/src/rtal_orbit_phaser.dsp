import("stdfaust.lib");

declare name "rtal-orbit-phaser";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Stereo 4/6/8/12-stage phaser with feedback, envelope sweep and orbiting LFOs.";

presetMode = nentry("orbit-phaser/[0]Factory Preset [style:menu{'Manual':0;'Script Ninety':1;'Liquid Orbit':2;'Jet Funk':3}]", 0, 0, 3, 1);
stagesManual = nentry("orbit-phaser/[1]Stages [style:menu{'4':0;'6':1;'8':2;'12':3}]", 0, 0, 3, 1);
rateManual = hslider("orbit-phaser/[2]Rate [style:knob]", 0.36, 0.0, 1.0, 0.01) : si.smoo;
depthManual = hslider("orbit-phaser/[3]Depth [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
centerManual = hslider("orbit-phaser/[4]Center [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
feedbackManual = hslider("orbit-phaser/[5]Feedback [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
envelopeManual = hslider("orbit-phaser/[6]Envelope [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
spreadManual = hslider("orbit-phaser/[7]Spread [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("orbit-phaser/[8]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isScript = (presetMode >= 0.5) * (presetMode < 1.5);
isLiquid = (presetMode >= 1.5) * (presetMode < 2.5);
isJet = presetMode >= 2.5;

selectPreset(manual, script, liquid, jet) =
  manual * isManual +
  script * isScript +
  liquid * isLiquid +
  jet * isJet;

stages = selectPreset(stagesManual, 0, 2, 3);
rate = selectPreset(rateManual, 0.42, 0.18, 0.30);
depth = selectPreset(depthManual, 0.72, 0.90, 0.80);
center = selectPreset(centerManual, 0.42, 0.50, 0.38);
// Feedback knob is bipolar: below 0.5 inverts the loop for hollow notches.
feedbackKnob = selectPreset(feedbackManual, 0.50, 0.78, 0.22);
envelope = selectPreset(envelopeManual, 0.0, 0.15, 0.72);
spread = selectPreset(spreadManual, 0.0, 0.60, 0.35);
mix = selectPreset(mixManual, 0.50, 0.50, 0.55);

process = _,_ : phaserStereo
with {
  rateHz = 0.03 * pow(300.0, rate);
  feedback = (feedbackKnob - 0.5) * 1.84;
  centerHz = 180.0 * pow(10.0, center * 1.3);

  wrap(x) = x - floor(x);
  lfoPhase = (+(rateHz / ma.SR) : wrap) ~ _;
  // Rounded triangle: sine body with a slightly sharpened top, like an OTA phaser.
  shape(p) = s * (1.0 + 0.25 * (1.0 - s * s))
  with {
    s = sin(2.0 * ma.PI * p);
  };

  allpass(f) = fi.tf1(a, 1.0, a)
  with {
    t = tan(ma.PI * f / ma.SR);
    a = (t - 1.0) / (t + 1.0);
  };

  // All stage counts are computed and the menu picks one output inside the loop.
  stageBank(f, x) = ba.selectn(4, int(stages), s4, s6, s8, s12)
  with {
    s4 = x : seq(i, 4, allpass(f));
    s6 = s4 : seq(i, 2, allpass(f));
    s8 = s6 : seq(i, 2, allpass(f));
    s12 = s8 : seq(i, 4, allpass(f));
  };

  phaserVoice(env, offset, x) = wet
  with {
    sweep = shape(wrap(lfoPhase + offset)) * depth * 1.6 + env * envelope * 3.2;
    f = min(ma.SR * 0.42, max(30.0, centerHz * pow(2.0, sweep)));
    wet = x : (+ : stageBank(f)) ~ (*(feedback) : ma.tanh);
  };

  phaserStereo(inL, inR) = outL, outR
  with {
    env = (inL + inR) * 0.5 : an.amp_follower_ar(0.004, 0.16) : *(4.0) : min(1.0);
    wetL = phaserVoice(env, 0.0, inL : fi.dcblocker);
    wetR = phaserVoice(env, spread * 0.5, inR : fi.dcblocker);
    norm = 1.0 / (1.0 + abs(feedback) * 0.6);
    outL = (inL * (1.0 - mix) + wetL * mix) * (1.0 + mix * 0.35) * norm;
    outR = (inR * (1.0 - mix) + wetR * mix) * (1.0 + mix * 0.35) * norm;
  };
};
