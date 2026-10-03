import("stdfaust.lib");

declare name "rtal-crybaby-ghost";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Wah pedal with an automatable treadle plus LFO and envelope 'ghost foot' modes, in three voicings.";

presetMode = nentry("crybaby-ghost/[0]Factory Preset [style:menu{'Manual':0;'Shaft Groove':1;'Slow Ghost Foot':2;'Vocal Talker':3}]", 0, 0, 3, 1);
voiceManual = nentry("crybaby-ghost/[1]Voicing [style:menu{'Cry':0;'Four-Pole':1;'Vocal':2}]", 0, 0, 2, 1);
pedal = hslider("crybaby-ghost/[2]Pedal", 0.50, 0.0, 1.0, 0.001) : si.smooth(ba.tau2pole(0.01));
envManual = hslider("crybaby-ghost/[3]Envelope [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
lfoManual = hslider("crybaby-ghost/[4]LFO Depth [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
rateManual = hslider("crybaby-ghost/[5]LFO Rate [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
rangeManual = hslider("crybaby-ghost/[6]Range [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
boostManual = hslider("crybaby-ghost/[7]Boost [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("crybaby-ghost/[8]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isShaft = (presetMode >= 0.5) * (presetMode < 1.5);
isGhost = (presetMode >= 1.5) * (presetMode < 2.5);
isVocal = presetMode >= 2.5;

selectPreset(manual, shaft, ghost, vocal) =
  manual * isManual +
  shaft * isShaft +
  ghost * isGhost +
  vocal * isVocal;

voice = int(selectPreset(voiceManual, 0, 1, 2));
envAmt = selectPreset(envManual, 0.75, 0.0, 0.55);
lfoAmt = selectPreset(lfoManual, 0.0, 0.85, 0.15);
rate = selectPreset(rateManual, 0.40, 0.25, 0.30);
range = selectPreset(rangeManual, 0.70, 0.75, 0.60);
boost = selectPreset(boostManual, 0.45, 0.40, 0.45);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : wahStereo
with {
  wrap(x) = x - floor(x);
  lfoHz = 0.08 * pow(80.0, rate);
  lfo = 0.5 - 0.5 * cos(2.0 * ma.PI * ((+(lfoHz / ma.SR) : wrap) ~ _));

  wahVoice(pos, x) = ba.selectn(3, voice, cry, fourPole, vocal) * (0.7 + boost * 1.3)
  with {
    // Range narrows the sweep around the centre of the treadle.
    p = 0.5 + (pos - 0.5) * (0.4 + range * 0.6);
    cry = x : ve.crybaby(p) : *(0.45);
    freq = 350.0 * pow(2.0, p * 2.6);
    fourPole = x : ve.wah4(freq) : *(0.7);
    vocalQ = 6.0 + p * 6.0;
    vocal = x : fi.svf.bp(freq, vocalQ) : /(vocalQ) : *(3.8) : +(x * 0.08);
  };

  wahStereo(inL, inR) = outL, outR
  with {
    env = (inL + inR) * 0.5 : an.amp_follower_ar(0.004, 0.18) : *(5.0) : min(1.0);
    // The pedal is the base position; the envelope and LFO push from there.
    pos = (pedal + env * envAmt + (lfo - 0.5) * lfoAmt) : max(0.0) : min(1.0);
    wetL = wahVoice(pos, inL);
    wetR = wahVoice(pos, inR);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
