import("stdfaust.lib");

declare name "rtal-gamelan-bells";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Modal resonator: each picked note strikes a tuned bell, gamelan gong, glass or marimba bar that rings at your pitch.";

presetMode = nentry("gamelan-bells/[0]Factory Preset [style:menu{'Manual':0;'Church Bell Lead':1;'Gamelan Shimmer':2;'Glass Harp':3}]", 0, 0, 3, 1);
materialManual = nentry("gamelan-bells/[1]Material [style:menu{'Bell':0;'Gamelan':1;'Glass':2;'Marimba':3}]", 0, 0, 3, 1);
tuningManual = nentry("gamelan-bells/[2]Tuning [style:menu{'Tracked':0;'Key Drone':1}]", 0, 0, 1, 1);
keyManual = nentry("gamelan-bells/[3]Key [style:menu{'C':0;'C#':1;'D':2;'D#':3;'E':4;'F':5;'F#':6;'G':7;'G#':8;'A':9;'A#':10;'B':11}]", 4, 0, 11, 1);
decayManual = hslider("gamelan-bells/[4]Decay [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
brightManual = hslider("gamelan-bells/[5]Brightness [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
strikeManual = hslider("gamelan-bells/[6]Strike [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
spreadManual = hslider("gamelan-bells/[7]Spread [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("gamelan-bells/[8]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isChurch = (presetMode >= 0.5) * (presetMode < 1.5);
isGamelan = (presetMode >= 1.5) * (presetMode < 2.5);
isGlass = presetMode >= 2.5;

selectPreset(manual, church, gamelan, glass) =
  manual * isManual +
  church * isChurch +
  gamelan * isGamelan +
  glass * isGlass;

material = int(selectPreset(materialManual, 0, 1, 2));
// Tuning and key follow the menus so presets work in any song.
tuning = tuningManual;
key = keyManual;
decay = selectPreset(decayManual, 0.70, 0.60, 0.80);
bright = selectPreset(brightManual, 0.55, 0.65, 0.75);
strike = selectPreset(strikeManual, 0.75, 0.65, 0.55);
spread = selectPreset(spreadManual, 0.50, 0.80, 0.70);
mix = selectPreset(mixManual, 0.55, 0.50, 0.50);

process = _,_ : bellStereo
with {
  nModes = 8;
  // Partial frequency ratios for each material, indexed material * 8 + mode.
  ratios = waveform{
    0.5, 1.0, 1.183, 1.506, 2.0, 2.514, 2.662, 3.011,
    1.0, 1.52, 2.0, 2.76, 3.0, 4.07, 5.33, 6.1,
    1.0, 2.32, 4.25, 6.63, 9.38, 12.6, 16.0, 19.8,
    1.0, 3.93, 9.2, 15.5, 2.0, 5.8, 11.4, 19.0};
  ratio(k) = ratios, int(material * nModes + k) : rdtable;

  t60 = 0.4 + decay * decay * 7.0;

  // One mode: a unity-peak resonant bandpass whose bandwidth gives the decay time.
  mode(k, f0, x) = x : fi.resonbp(f, q, 1.0 / q) : *(weight)
  with {
    f = min(ma.SR * 0.45, f0 * ratio(k));
    modeT60 = t60 / (1.0 + k * (1.0 - bright) * 0.8);
    q = max(2.0, ma.PI * f * modeT60 / 6.91);
    weight = pow(0.55 + bright * 0.4, k) * sqrt(q) * 2.5;
  };

  bellStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    // The modes keep ringing after the string stops, so the pitch is captured early in
    // each note (15-120 ms after the pick) and held until the next one; tracking all
    // the way into the release would retune the ringing bell as the estimate collapses.
    fastEnv = mono : abs : an.amp_follower_ar(0.0005, 0.03);
    slowEnv = mono : abs : an.amp_follower_ar(0.03, 0.3);
    onset = fastEnv > slowEnv * 1.6 + 0.003;
    sinceOnset = step ~ _
    with {
      step(c) = ba.if((onset > onset') * (c > 0.08 * ma.SR), 0.0, min(c + 1.0, 100000000.0));
    };
    capture = (sinceOnset > 0.015 * ma.SR) * (sinceOnset < 0.12 * ma.SR);
    hz = mono : fi.lowpass(2, 1300.0) : an.pitchTracker(2, 0.02) : ba.sAndH(capture) : max(60.0) : min(1500.0);
    trackedNote = 69.0 + 12.0 * log(hz / 440.0) / log(2.0) : floor(_ + 0.5);
    keyNote = 52.0 + key;
    note = ba.if(tuning > 0.5, keyNote, trackedNote);
    f0 = 440.0 * pow(2.0, (note - 69.0) / 12.0) : si.smooth(ba.tau2pole(0.003));
    // Strike: only the pick transient excites the modes, like a mallet.
    transient = max(0.0, mono : abs : an.amp_follower_ar(0.0002, 0.01) : -(mono : abs : an.amp_follower_ar(0.01, 0.01)));
    excite = mono * (1.0 - strike) * 0.3 + (mono : fi.highpass(1, 300.0)) * min(1.0, transient * 30.0) * strike;
    modes = par(k, nModes, mode(k, f0, excite));
    pan(k) = 0.5 + spread * 0.45 * (2.0 * (k % 2) - 1.0);
    wetL = modes : par(k, nModes, *(1.0 - pan(k))) :> fi.dcblocker : ma.tanh;
    wetR = modes : par(k, nModes, *(pan(k))) :> fi.dcblocker : ma.tanh;
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
