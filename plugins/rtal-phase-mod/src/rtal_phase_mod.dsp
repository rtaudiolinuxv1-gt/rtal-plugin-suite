import("stdfaust.lib");

declare name "rtal-phase-mod";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "FM guitar: audio-rate phase modulation locked to your pitch, for DX-style bells, brass and metallic clangs.";

presetMode = nentry("phase-mod/[0]Factory Preset [style:menu{'Manual':0;'Electric Piano':1;'Brassy Growl':2;'Inharmonic Clang':3}]", 0, 0, 3, 1);
ratioManual = nentry("phase-mod/[1]Ratio [style:menu{'0.5':0;'1':1;'2':2;'3':3;'3.5':4;'1.41':5;'7':6}]", 1, 0, 6, 1);
indexManual = hslider("phase-mod/[2]Index [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
dynamicsManual = hslider("phase-mod/[3]Dynamics [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
decayManual = hslider("phase-mod/[4]Index Decay [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("phase-mod/[5]Tone [style:knob]", 0.65, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("phase-mod/[6]Mix [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isPiano = (presetMode >= 0.5) * (presetMode < 1.5);
isBrass = (presetMode >= 1.5) * (presetMode < 2.5);
isClang = presetMode >= 2.5;

selectPreset(manual, piano, brass, clang) =
  manual * isManual +
  piano * isPiano +
  brass * isBrass +
  clang * isClang;

ratioSel = int(selectPreset(ratioManual, 1, 1, 5));
index = selectPreset(indexManual, 0.45, 0.65, 0.70);
dynamics = selectPreset(dynamicsManual, 0.80, 0.50, 0.40);
decay = selectPreset(decayManual, 0.30, 0.60, 0.45);
tone = selectPreset(toneManual, 0.60, 0.50, 0.75);
mix = selectPreset(mixManual, 0.75, 0.80, 0.70);

process = _,_ : pmStereo
with {
  maxDelay = 4096;
  ratio = ba.selectn(7, ratioSel, 0.5, 1.0, 2.0, 3.0, 3.5, 1.41421, 7.0);
  wrap(x) = x - floor(x);

  pmStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    env = mono : an.amp_follower_ar(0.002, 0.1);
    hz = mono : fi.lowpass(2, 1300.0) : an.pitchTracker(2, 0.02) : ba.sAndH(env > 0.004) : max(50.0) : min(1500.0)
      : si.smooth(ba.tau2pole(0.005));
    modHz = hz * ratio;
    modulator = sin(2.0 * ma.PI * ((+(modHz / ma.SR) : wrap) ~ _));

    // Index (beta) follows each note: it starts bright on the pick and decays,
    // just like an FM operator envelope. Dynamics ties it to how hard you play.
    fast = mono : abs : an.amp_follower_ar(0.0005, 0.03);
    slow = mono : abs : an.amp_follower_ar(0.03, 0.3);
    onset = fast > slow * 1.6 + 0.003;
    indexEnv = (onset > onset') : en.ar(0.002, 0.08 + decay * decay * 2.0);
    level = env * 6.0 : min(1.0);
    beta = index * 6.0 * ((1.0 - dynamics) + dynamics * level) * (0.35 + 0.65 * indexEnv);

    // Phase modulation as audio-rate delay modulation: a delay swing of
    // beta / (2 pi f) seconds gives a phase deviation of beta radians.
    swingSamples = beta / (2.0 * ma.PI * modHz) * ma.SR;
    baseDelay = min(float(maxDelay) * 0.5, 6.0 / (2.0 * ma.PI * 50.0) * ma.SR) + 4.0;
    pm(x) = x : de.fdelay3(maxDelay, baseDelay + swingSamples * modulator);
    post = fi.lowpass(2, 1500.0 + tone * tone * 14000.0) : fi.dcblocker;
    outL = inL * (1.0 - mix) + (inL : pm : post) * mix;
    outR = inR * (1.0 - mix) + (inR : pm : post) * mix;
  };
};
