import("stdfaust.lib");

declare name "rtal-snap-tune";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Scale-snapping pitch correction for single-note lines: from gentle tuning help to the hard robotic snap.";

presetMode = nentry("snap-tune/[0]Factory Preset [style:menu{'Manual':0;'Robot Snap':1;'Gentle Tune':2;'Pentatonic Lock':3}]", 0, 0, 3, 1);
keyManual = nentry("snap-tune/[1]Key [style:menu{'C':0;'C#':1;'D':2;'D#':3;'E':4;'F':5;'F#':6;'G':7;'G#':8;'A':9;'A#':10;'B':11}]", 4, 0, 11, 1);
scaleManual = nentry("snap-tune/[2]Scale [style:menu{'Chromatic':0;'Major':1;'Natural Minor':2;'Minor Pentatonic':3;'Major Pentatonic':4;'Blues':5}]", 1, 0, 5, 1);
retuneManual = hslider("snap-tune/[3]Retune Speed [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
amountManual = hslider("snap-tune/[4]Amount [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
toleranceManual = hslider("snap-tune/[5]Tolerance [unit:cents]", 0, 0, 50, 1) : si.smoo;
mixManual = hslider("snap-tune/[6]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isRobot = (presetMode >= 0.5) * (presetMode < 1.5);
isGentle = (presetMode >= 1.5) * (presetMode < 2.5);
isPenta = presetMode >= 2.5;

selectPreset(manual, robot, gentle, penta) =
  manual * isManual +
  robot * isRobot +
  gentle * isGentle +
  penta * isPenta;

// Key always follows the menu.
key = keyManual;
scale = int(selectPreset(scaleManual, scaleManual, scaleManual, 3));
retune = selectPreset(retuneManual, 0.0, 0.65, 0.20);
amount = selectPreset(amountManual, 1.0, 0.70, 1.0);
toleranceCents = selectPreset(toleranceManual, 0.0, 15.0, 0.0);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : tuneStereo
with {
  // 1 where a pitch class (relative to the key) is allowed, indexed scale * 12 + pc.
  allowedTable = waveform{
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1,
    1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0,
    1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0,
    1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0,
    1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0};
  allowed(n) = allowedTable, int(scale * 12 + (int(n - key + 120.0) % 12)) : rdtable;

  // Nearest allowed note to a continuous MIDI pitch; every scale here has gaps of
  // at most three semitones, so searching +/-2 around the rounded note is enough.
  nearest(f) = ba.if(allowed(r), r,
      ba.if(allowed(r + 1.0) * allowed(r - 1.0), ba.if(f > r, r + 1.0, r - 1.0),
      ba.if(allowed(r + 1.0), r + 1.0,
      ba.if(allowed(r - 1.0), r - 1.0,
      ba.if(allowed(r + 2.0) * allowed(r - 2.0), ba.if(f > r, r + 2.0, r - 2.0),
      ba.if(allowed(r + 2.0), r + 2.0, r - 2.0))))))
  with {
    r = floor(f + 0.5);
  };

  tuneStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    env = mono : an.amp_follower_ar(0.002, 0.1);
    voiced = env > 0.004;
    hz = mono : fi.lowpass(2, 1400.0) : an.pitchTracker(2, 0.015) : ba.sAndH(voiced) : max(60.0) : min(1500.0);
    noteF = 69.0 + 12.0 * log(hz / 440.0) / log(2.0) : si.smooth(ba.tau2pole(0.006));
    error = nearest(noteF) - noteF;
    // Leave notes alone when they are already within the tolerance.
    needed = ba.if(abs(error) * 100.0 < toleranceCents, 0.0, error) : max(-2.0) : min(2.0);
    retuneSec = 0.001 + retune * retune * 0.25;
    shift = needed * amount * voiced : si.smooth(ba.tau2pole(retuneSec));
    wetL = inL : ef.transpose(1024, 256, shift);
    wetR = inR : ef.transpose(1024, 256, shift);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
