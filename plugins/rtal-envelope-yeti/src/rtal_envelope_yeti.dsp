import("stdfaust.lib");

declare name "rtal-envelope-yeti";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Envelope filter / auto-wah with state-variable and ladder modes, up or down sweeps.";

presetMode = nentry("envelope-yeti/[0]Factory Preset [style:menu{'Manual':0;'Funk Quack':1;'Ladder Burp':2;'Down Sweep Dub':3}]", 0, 0, 3, 1);
modeManual = nentry("envelope-yeti/[1]Filter [style:menu{'Bandpass':0;'Lowpass':1;'Ladder':2;'Highpass':3}]", 0, 0, 3, 1);
directionManual = nentry("envelope-yeti/[2]Direction [style:menu{'Up':0;'Down':1}]", 0, 0, 1, 1);
sensManual = hslider("envelope-yeti/[3]Sensitivity [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
rangeManual = hslider("envelope-yeti/[4]Range [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
baseManual = hslider("envelope-yeti/[5]Base [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
resonanceManual = hslider("envelope-yeti/[6]Resonance [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
attackManual = hslider("envelope-yeti/[7]Attack [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
decayManual = hslider("envelope-yeti/[8]Decay [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("envelope-yeti/[9]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isFunk = (presetMode >= 0.5) * (presetMode < 1.5);
isBurp = (presetMode >= 1.5) * (presetMode < 2.5);
isDub = presetMode >= 2.5;

selectPreset(manual, funk, burp, dub) =
  manual * isManual +
  funk * isFunk +
  burp * isBurp +
  dub * isDub;

mode = int(selectPreset(modeManual, 0, 2, 1));
direction = selectPreset(directionManual, 0, 0, 1);
sens = selectPreset(sensManual, 0.62, 0.55, 0.50);
range = selectPreset(rangeManual, 0.70, 0.75, 0.65);
base = selectPreset(baseManual, 0.20, 0.10, 0.45);
resonance = selectPreset(resonanceManual, 0.72, 0.65, 0.55);
attack = selectPreset(attackManual, 0.10, 0.25, 0.30);
decay = selectPreset(decayManual, 0.35, 0.45, 0.70);
mix = selectPreset(mixManual, 1.0, 1.0, 0.90);

process = _,_ : yetiStereo
with {
  attackSec = 0.001 + attack * attack * 0.08;
  decaySec = 0.03 + decay * decay * 0.9;
  lowHz = 120.0 * pow(4.0, base);
  octaves = 1.0 + range * 4.5;
  q = 0.8 + resonance * resonance * 9.0;

  filterVoice(fc, x) = ba.selectn(4, mode, bp, lp, ladder, hp) * makeup
  with {
    bp = x : fi.svf.bp(fc, q) : /(q) : *(1.4 + resonance * 1.2);
    lp = x : fi.svf.lp(fc, q * 0.7) : /(pow(q * 0.7, 0.3)) : *(1.4);
    ladderQ = 0.707 + resonance * 18.0;
    ladder = x : ve.moogLadder(min(0.95, fc / (ma.SR * 0.5)), ladderQ) : *(1.0 + resonance * 1.5);
    hp = x : fi.svf.hp(fc, q * 0.7) : /(pow(q * 0.7, 0.3));
    makeup = 1.15;
  };

  yetiStereo(inL, inR) = outL, outR
  with {
    detector = (inL + inR) * 0.5 : fi.highpass(1, 100.0) : abs;
    env = detector : *(1.0 + sens * sens * 40.0) : an.amp_follower_ar(attackSec, decaySec) : min(1.0);
    sweep = ba.if(direction > 0.5, 1.0 - env, env);
    fc = min(ma.SR * 0.42, lowHz * pow(2.0, sweep * octaves));
    wetL = filterVoice(fc, inL);
    wetR = filterVoice(fc, inR);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
