import("stdfaust.lib");

declare name "rtal-synth-ghost";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Monophonic guitar synth: tracks your pitch and plays a saw/square oscillator through an enveloped ladder filter.";

presetMode = nentry("synth-ghost/[0]Factory Preset [style:menu{'Manual':0;'Fat Bass Lead':1;'Square Chiptune':2;'Brass Swell':3}]", 0, 0, 3, 1);
waveManual = nentry("synth-ghost/[1]Wave [style:menu{'Saw':0;'Square':1;'Saw + Sub':2;'Pulse Wide':3}]", 0, 0, 3, 1);
octaveManual = nentry("synth-ghost/[2]Octave [style:menu{'-2':0;'-1':1;'0':2;'+1':3}]", 2, 0, 3, 1);
glideManual = hslider("synth-ghost/[3]Glide [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
cutoffManual = hslider("synth-ghost/[4]Cutoff [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
resonanceManual = hslider("synth-ghost/[5]Resonance [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
envAmtManual = hslider("synth-ghost/[6]Filter Env [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
decayManual = hslider("synth-ghost/[7]Env Decay [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
synthManual = hslider("synth-ghost/[8]Synth Level [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
dryManual = hslider("synth-ghost/[9]Dry [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBass = (presetMode >= 0.5) * (presetMode < 1.5);
isChip = (presetMode >= 1.5) * (presetMode < 2.5);
isBrass = presetMode >= 2.5;

selectPreset(manual, bass, chip, brass) =
  manual * isManual +
  bass * isBass +
  chip * isChip +
  brass * isBrass;

wave = int(selectPreset(waveManual, 2, 1, 0));
octaveSel = int(selectPreset(octaveManual, 1, 3, 2));
glide = selectPreset(glideManual, 0.20, 0.0, 0.25);
cutoff = selectPreset(cutoffManual, 0.25, 0.70, 0.20);
resonance = selectPreset(resonanceManual, 0.55, 0.20, 0.35);
envAmt = selectPreset(envAmtManual, 0.70, 0.30, 0.80);
decay = selectPreset(decayManual, 0.30, 0.15, 0.70);
synthLevel = selectPreset(synthManual, 0.80, 0.65, 0.75);
dry = selectPreset(dryManual, 0.20, 0.30, 0.35);

process = _,_ : synthStereo
with {
  octaveMul = ba.selectn(4, octaveSel, 0.25, 0.5, 1.0, 2.0);
  glideSec = 0.001 + glide * glide * 0.4;
  wrap(x) = x - floor(x);

  // Band-limited saw (polynomial transition) and a pulse built from the
  // difference of a saw and a copy of itself delayed by the pulse width.
  saw(f) = os.sawtooth(f);
  pulse(f, width) = (s - (s : de.fdelay(8192, min(8000.0, width * ma.SR / max(f, 20.0))))) * 0.5 : fi.dcblocker
  with {
    s = saw(f);
  };

  synthStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    env = mono : an.amp_follower_ar(0.003, 0.12);
    gate = env > 0.004;
    // Clamp after the hold: the hold starts at 0 and the note math takes a log.
    trackedHz = mono : fi.lowpass(2, 1300.0) : an.pitchTracker(2, 0.02) : ba.sAndH(gate)
      : max(40.0) : min(1500.0);
    // Quantise to the nearest semitone so the synth is in tune, then glide.
    note = 69.0 + 12.0 * log(trackedHz / 440.0) / log(2.0) : floor(_ + 0.5);
    hz = 440.0 * pow(2.0, (note - 69.0) / 12.0) * octaveMul : si.smooth(ba.tau2pole(glideSec));

    osc = ba.selectn(4, wave,
      saw(hz),
      pulse(hz, 0.5) * 1.6,
      saw(hz) * 0.7 + pulse(hz * 0.5, 0.5) * 0.8,
      pulse(hz, 0.25) * 1.6);

    // Amplitude follows the guitar; filter envelope fires on each new note.
    amp = env : *(6.0) : min(1.0) : si.smooth(ba.tau2pole(0.004));
    fast = mono : abs : an.amp_follower_ar(0.0005, 0.03);
    slow = mono : abs : an.amp_follower_ar(0.03, 0.3);
    onset = fast > slow * 1.6 + 0.003;
    filterEnv = (onset > onset') : en.ar(0.003, 0.05 + decay * decay * 1.5);
    cutoffHz = 80.0 * pow(2.0, cutoff * 7.0 + filterEnv * envAmt * 5.0) : min(16000.0);
    q = 0.707 + resonance * resonance * 18.0;
    voiced = osc * amp : ve.moogLadder(min(0.9, cutoffHz / (ma.SR * 0.5)), q) : *(1.0 + resonance) : *(synthLevel * 0.45);

    outL = inL * dry + voiced;
    outR = inR * dry + voiced;
  };
};
