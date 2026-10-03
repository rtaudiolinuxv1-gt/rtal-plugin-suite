import("stdfaust.lib");

declare name "rtal-human-tune";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Dynamic pitch correction that keeps the player human: a wandering reference around A440, per-note imperfection and vibrato-safe tracking, or a perfect A440 snap.";

presetMode = nentry("human-tune/[00]Factory Preset [style:menu{'Manual':0;'Session Player':1;'Live and Loose':2;'Studio Perfect':3;'Robot Hard Snap':4}]", 0, 0, 4, 1);
modeManual = nentry("human-tune/[01]Mode [style:menu{'Human':0;'Perfect 440':1}]", 0, 0, 1, 1);
keyManual = nentry("human-tune/[02]Key [style:menu{'C':0;'C#':1;'D':2;'D#':3;'E':4;'F':5;'F#':6;'G':7;'G#':8;'A':9;'A#':10;'B':11}]", 4, 0, 11, 1);
scaleManual = nentry("human-tune/[03]Scale [style:menu{'Chromatic':0;'Major':1;'Natural Minor':2;'Minor Pentatonic':3;'Major Pentatonic':4;'Blues':5;'Dorian':6;'Mixolydian':7}]", 0, 0, 7, 1);
referenceHz = hslider("human-tune/[04]Reference A [unit:Hz]", 440, 430, 450, 0.01);
strengthManual = hslider("human-tune/[05]Strength [style:knob]", 0.85, 0.0, 1.0, 0.01) : si.smoo;
retuneManual = hslider("human-tune/[06]Retune Speed [unit:ms]", 60, 0, 400, 1) : si.smoo;
vibratoManual = hslider("human-tune/[07]Vibrato Keep [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
attackManual = hslider("human-tune/[08]Attack Freedom [unit:ms]", 60, 0, 300, 1) : si.smoo;
humanizeManual = hslider("human-tune/[09]Note Humanize [unit:cents]", 4, 0, 25, 0.1) : si.smoo;
wanderManual = hslider("human-tune/[10]Reference Wander [unit:cents]", 4, 0, 15, 0.1) : si.smoo;
wanderRateManual = hslider("human-tune/[11]Wander Rate [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
driftManual = hslider("human-tune/[12]Micro Drift [unit:cents]", 2, 0, 10, 0.1) : si.smoo;
toleranceManual = hslider("human-tune/[13]Tolerance [unit:cents]", 0, 0, 40, 0.5) : si.smoo;
mixManual = hslider("human-tune/[14]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
detectedMeter = hbargraph("human-tune/[15]Played Offset [unit:cents]", -50, 50);
correctionMeter = hbargraph("human-tune/[16]Correction [unit:cents]", -300, 300);
referenceMeter = hbargraph("human-tune/[17]Live Reference A [unit:Hz]", 425, 455);

isManual = presetMode < 0.5;
isSession = (presetMode >= 0.5) * (presetMode < 1.5);
isLoose = (presetMode >= 1.5) * (presetMode < 2.5);
isPerfect = (presetMode >= 2.5) * (presetMode < 3.5);
isRobot = presetMode >= 3.5;

selectPreset(manual, session, loose, perfect, robot) =
  manual * isManual +
  session * isSession +
  loose * isLoose +
  perfect * isPerfect +
  robot * isRobot;

// Key, scale and reference always follow the menus so presets work in any song.
key = keyManual;
scale = int(scaleManual);
mode = selectPreset(modeManual, 0, 0, 1, 1);
strength = selectPreset(strengthManual, 0.80, 0.55, 1.00, 1.00);
retuneMs = selectPreset(retuneManual, 70.0, 140.0, 25.0, 0.0);
vibratoKeep = selectPreset(vibratoManual, 0.65, 0.80, 0.50, 0.0);
attackMs = selectPreset(attackManual, 60.0, 110.0, 30.0, 0.0);
humanizeCents = selectPreset(humanizeManual, 5.0, 11.0, 0.0, 0.0);
wanderCents = selectPreset(wanderManual, 3.0, 7.0, 0.0, 0.0);
wanderRate = selectPreset(wanderRateManual, 0.30, 0.45, 0.0, 0.0);
driftCents = selectPreset(driftManual, 1.5, 4.0, 0.0, 0.0);
toleranceCents = selectPreset(toleranceManual, 4.0, 10.0, 0.0, 0.0);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0, 1.0);

process = _,_ : tuneStereo
with {
  isHuman = mode < 0.5;

  // ---- Scales -------------------------------------------------------------
  // Scales: Chromatic, Major, Natural Minor, Minor Pentatonic, Major Pentatonic,
  // Blues, Dorian, Mixolydian. For each scale, pitch class (relative to the key)
  // and rounding direction (down, up) this holds the step in semitones to the
  // nearest note of the scale, so snapping is a single table read.
  // Indexed scale * 24 + pc * 2 + up.
  nearestTable = waveform{
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, -1, 1, 0, 0, -1, 1, 0, 0, 0, 0, -1, 1, 0, 0, -1, 1, 0, 0, -1, 1, 0, 0,
    0, 0, -1, 1, 0, 0, 0, 0, -1, 1, 0, 0, -1, 1, 0, 0, 0, 0, -1, 1, 0, 0, -1, 1,
    0, 0, -1, -1, 1, 1, 0, 0, -1, 1, 0, 0, -1, 1, 0, 0, -1, -1, 1, 1, 0, 0, -1, 1,
    0, 0, -1, 1, 0, 0, -1, 1, 0, 0, -1, -1, 1, 1, 0, 0, -1, 1, 0, 0, -1, -1, 1, 1,
    0, 0, -1, -1, 1, 1, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, -1, -1, 1, 1, 0, 0, -1, 1,
    0, 0, -1, 1, 0, 0, 0, 0, -1, 1, 0, 0, -1, 1, 0, 0, -1, 1, 0, 0, 0, 0, -1, 1,
    0, 0, -1, 1, 0, 0, -1, 1, 0, 0, 0, 0, -1, 1, 0, 0, -1, 1, 0, 0, 0, 0, -1, 1
};
  nearest(f) = r + (nearestTable, int(scale * 24 + pc * 2 + (f > r)) : rdtable)
  with {
    r = floor(f + 0.5);
    pc = int(r - key + 120.0) % 12;
  };

  // Each stage below is a self-contained block taking its signal as an input.
  // (Recursive closures that capture large outer expressions make the Faust
  // compiler's evaluation blow up, so the stages are kept point-free.)

  envelope = abs : an.amp_follower_ar(0.002, 0.1);

  // ---- Non-repeating randomness ---------------------------------------------
  // Faust's no.noise always starts from the same seed, so every session would
  // replay identical "human" variations. Instead each generator is seeded from
  // OS entropy once per plugin activation (rtal_entropy.h, evaluated at every
  // instance init) and is continuously stirred by the low bits of the incoming
  // audio, whose analog noise is never the same twice.
  activationSeed = fconstant(int rtal_entropy_seed, "rtal_entropy.h");
  firstSample = 1 - 1';
  // Integer LCG; k decorrelates the independent streams. Inputs: audio (for stirring).
  entropyNoise(k, x) = (step ~ _) : float : /(2147483648.0)
  with {
    stir = int(abs(x) * 16777216.0) & 255;
    seed = (activationSeed + k * 7919 + k * k * 104729) * firstSample;
    step(state) = state * 1103515245 + 12345 + seed + stir * (2 * k + 1);
  };
  // Smooth random wander at roughly 'hz': raised-cosine glides between successive
  // random points from the seeded generator. Bounded to +/-1 by construction (a
  // very-low-frequency IIR filter here is numerically unstable in float32).
  entropyWander(k, hz, x) = previous + (current - previous) * (0.5 - 0.5 * cos(ma.PI * phase))
  with {
    wrap(v) = v - floor(v);
    phase = (+(hz / ma.SR) : wrap) ~ _;
    tick = phase < phase';
    current = entropyNoise(k, x) : ba.sAndH(tick);
    previous = current' : ba.sAndH(tick);
  };

  // Holds the last value while 'gate' is 0. Inputs: gate, x.
  hold = ba.sAndH;

  // Snapping follower: averages small cycle-to-cycle noise, jumps on new notes.
  snapSmooth(tau) = _ <: (step ~ _)
  with {
    step(prev, x) = ba.if(abs(x - prev) > 0.03 * prev, x, prev + (x - prev) * (1.0 - exp(-1.0 / (tau * ma.SR))));
  };

  // One-pole follower that jumps when the input moves more than 'thr' at once.
  snapAbs(tau, thr) = _ <: (step ~ _)
  with {
    step(prev, x) = ba.if(abs(x - prev) > thr, x, prev + (x - prev) * (1.0 - exp(-1.0 / (tau * ma.SR))));
  };

  // Smooths a note number without float32 stalling: a slow one-pole on a value near
  // 69.0 makes increments smaller than the float resolution and freezes cents off
  // target, so only the small deviation from an integer anchor note is smoothed.
  smoothNote(tau, x) = anchor + (x - anchor : snapAbs(tau, 0.6))
  with {
    anchor = noteHysteresis(x);
  };

  // Hysteresis on a note number: only moves when the input strays > 0.8 semitone.
  noteHysteresis(x) = (step ~ _)
  with {
    step(held) = ba.if(abs(x - held) > 0.8, floor(x + 0.5), held);
  };

  // ---- Precise pitch detection (same method as rtal-needle-tuner) ---------
  // A coarse zero-crossing-rate estimate picks a lowpass that isolates the
  // fundamental; each cycle is then timed between interpolated zero crossings.
  coarseHz(x) = x : fi.lowpass(2, 1300.0) : an.pitchTracker(2, 0.02) : ba.sAndH(envelope(x) > 0.003)
    : max(50.0) : min(1400.0) : si.smooth(ba.tau2pole(0.04));
  isolate(x) = x : fi.highpass(2, 40.0) : fi.lowpass(4, isolateHz)
  with {
    coarseNote = noteHysteresis(69.0 + 12.0 * log(coarseHz(x) / 440.0) / log(2.0));
    isolateHz = 440.0 * pow(2.0, (coarseNote - 69.0) / 12.0) * 1.6;
  };
  // Samples since the last upward zero crossing. Inputs: cross, frac.
  crossingAge = (step ~ _)
  with {
    step(a, cross, frac) = ba.if(cross, 1.0 - frac, min(a + 1.0, 100000.0));
  };
  periodOf(y, env) = ba.sAndH(cross, age' + frac) : max(20.0)
  with {
    loud = (y : abs : an.amp_follower_ar(0.001, 0.05)) > env * 0.05 + 0.0002;
    cross = (y' < 0.0) * (y >= 0.0) * loud;
    frac = y' / min(-0.0000001, y' - y);
    age = crossingAge(cross, frac);
  };
  // Played pitch in MIDI notes against an exact A440 grid.
  playedNote(x) = ma.SR / periodOf(isolate(x), envelope(x)) : ba.sAndH(envelope(x) > 0.003)
    : snapSmooth(0.008) : max(30.0) : hzToNote
  with {
    hzToNote(hz) = 69.0 + 12.0 * log(hz / 440.0) / log(2.0);
  };

  // Target hysteresis. Inputs: heard (continuous note), candidate (snapped note).
  // The target only moves when the new candidate is clearly nearer (by 6 cents), so
  // a note wavering on the boundary doesn't flip, but no wrong note can stick.
  targetHold = (step ~ _)
  with {
    step(prev, heard, candidate) = ba.if(abs(heard - candidate) + 0.06 < abs(heard - prev), candidate, prev);
  };

  // Samples since the last accepted pick onset. Input: onset (0/1).
  sinceOnset = (step ~ _)
  with {
    step(c, onset) = ba.if((onset > onset') * (c > 0.06 * ma.SR), 0.0, min(c + 1.0, 100000000.0));
  };

  // ---- Correction amount (semitones) for a mono detection signal ----------
  correction(x) = shift
  with {
    voiced = envelope(x) > 0.003;
    played = playedNote(x);
    // Vibrato Keep: correction follows the note's centre, so vibrato passes through.
    centre = smoothNote(0.004 + vibratoKeep * vibratoKeep * 0.35, played);

    // The floating reference: in Human mode the tuning standard wanders a few cents
    // around the reference (slow random walk plus a slow incommensurate sine) and
    // never settles on it. Perfect mode uses the reference exactly.
    wanderHz = 0.02 + wanderRate * wanderRate * 0.5;
    // The slow sine runs from a random starting phase each activation as well.
    wanderPhase = float(activationSeed % 10000) / 10000.0;
    wanderSine = sin(2.0 * ma.PI * (wanderPhase + ((+(wanderHz * 0.618 / ma.SR) : ma.frac) ~ _)));
    wander = (entropyWander(1, wanderHz, x) * 0.75 + wanderSine * 0.25) * wanderCents;
    refCents = 1200.0 * log(referenceHz / 440.0) / log(2.0) + ba.if(isHuman, wander, 0.0);

    heard = centre - refCents / 100.0;
    target = targetHold(heard, nearest(heard));
    newNote = target != target';

    // Human imperfection: a random intonation offset per note, plus micro drift.
    noteOffset = entropyNoise(2, x) : ba.sAndH(newNote) : *(humanizeCents);
    microDrift = (entropyWander(3, 0.7, x) * 0.6 + entropyWander(4, 3.1, x) * 0.4) * driftCents;
    humanCents = ba.if(isHuman, noteOffset + microDrift, 0.0);

    error = target + (refCents + humanCents) / 100.0 - centre;
    // Tolerance: notes already within the window are left alone.
    needed = ba.if(abs(error) * 100.0 < toleranceCents, 0.0, error) : max(-3.0) : min(3.0);
    // Attack Freedom: correction fades in after each pick, keeping natural scoops.
    onset = (x : abs : an.amp_follower_ar(0.0005, 0.03)) > (x : abs : an.amp_follower_ar(0.03, 0.3)) * 1.6 + 0.003;
    attackGate = min(1.0, sinceOnset(onset) / max(1.0, attackMs * 0.001 * ma.SR));
    // Perfect 440 always corrects fully; Strength shapes Human mode only.
    shift = needed * ba.if(isHuman, strength, 1.0) * attackGate * voiced : si.smooth(ba.tau2pole(0.0005 + retuneMs * 0.001))
      : attach(_, (played - floor(played + 0.5)) * 100.0 : detectedMeter)
      : attach(_, 440.0 * pow(2.0, refCents / 1200.0) : referenceMeter);
  };

  tuneStereo(inL, inR) = outL, outR
  with {
    shift = correction((inL + inR) * 0.5);
    wetL = inL : ef.transpose(1536, 384, shift);
    wetR = inR : ef.transpose(1536, 384, shift);
    outL = inL * (1.0 - mix) + wetL * mix : attach(_, shift * 100.0 : correctionMeter);
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
