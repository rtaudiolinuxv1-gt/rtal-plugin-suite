import("stdfaust.lib");

declare name "rtal-twin-harmony";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Two-voice diatonic harmonizer: tracks your pitch and adds harmonies that stay in key.";

presetMode = nentry("twin-harmony/[0]Factory Preset [style:menu{'Manual':0;'Twin Leads':1;'Power Stack':2;'Choir of Thirds':3}]", 0, 0, 3, 1);
keyManual = nentry("twin-harmony/[1]Key [style:menu{'C':0;'C#':1;'D':2;'D#':3;'E':4;'F':5;'F#':6;'G':7;'G#':8;'A':9;'A#':10;'B':11}]", 4, 0, 11, 1);
scaleManual = nentry("twin-harmony/[2]Scale [style:menu{'Major':0;'Natural Minor':1;'Dorian':2;'Mixolydian':3;'Harmonic Minor':4}]", 1, 0, 4, 1);
voiceAManual = nentry("twin-harmony/[3]Voice A [style:menu{'Unison':0;'Third Up':1;'Fourth Up':2;'Fifth Up':3;'Sixth Up':4;'Octave Up':5;'Third Down':6;'Fourth Down':7;'Sixth Down':8;'Octave Down':9}]", 1, 0, 9, 1);
voiceBManual = nentry("twin-harmony/[4]Voice B [style:menu{'Unison':0;'Third Up':1;'Fourth Up':2;'Fifth Up':3;'Sixth Up':4;'Octave Up':5;'Third Down':6;'Fourth Down':7;'Sixth Down':8;'Octave Down':9}]", 3, 0, 9, 1);
levelAManual = hslider("twin-harmony/[5]Level A [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
levelBManual = hslider("twin-harmony/[6]Level B [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
humanizeManual = hslider("twin-harmony/[7]Humanize [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("twin-harmony/[8]Width [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
dryManual = hslider("twin-harmony/[9]Dry [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isTwin = (presetMode >= 0.5) * (presetMode < 1.5);
isPower = (presetMode >= 1.5) * (presetMode < 2.5);
isChoir = presetMode >= 2.5;

selectPreset(manual, twin, power, choir) =
  manual * isManual +
  twin * isTwin +
  power * isPower +
  choir * isChoir;

// Key and scale always follow the menus so presets work in any song.
key = keyManual;
scale = int(scaleManual);
voiceA = int(selectPreset(voiceAManual, 1, 3, 1));
voiceB = int(selectPreset(voiceBManual, 0, 9, 6));
levelA = selectPreset(levelAManual, 0.80, 0.70, 0.60);
levelB = selectPreset(levelBManual, 0.0, 0.50, 0.55);
humanize = selectPreset(humanizeManual, 0.35, 0.10, 0.60);
width = selectPreset(widthManual, 0.80, 0.40, 1.00);
dry = selectPreset(dryManual, 1.0, 1.0, 0.85);

process = _,_ : harmonyStereo
with {
  // Lookup tables, five scales each: Major, Natural Minor, Dorian, Mixolydian, Harmonic Minor.
  // Semitone of scale degree i (0..6), indexed scale * 7 + i.
  scaleTable = waveform{
    0, 2, 4, 5, 7, 9, 11,
    0, 2, 3, 5, 7, 8, 10,
    0, 2, 3, 5, 7, 9, 10,
    0, 2, 4, 5, 7, 9, 10,
    0, 2, 3, 5, 7, 8, 11};
  // Scale degree for each pitch class, indexed scale * 12 + pc.
  // Out-of-scale notes borrow the degree below.
  degreeTable = waveform{
    0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6,
    0, 0, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6,
    0, 0, 1, 2, 2, 3, 3, 4, 4, 5, 6, 6,
    0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 6, 6,
    0, 0, 1, 2, 2, 3, 3, 4, 5, 5, 5, 6};
  scaleNote(i) = scaleTable, int(scale * 7 + i) : rdtable;
  degreeOf(pc) = degreeTable, int(scale * 12 + pc) : rdtable;

  // Interval menu entries expressed in scale steps.
  stepsTable = waveform{0, 2, 3, 4, 5, 7, -2, -3, -5, -7};
  steps(v) = stepsTable, int(v) : rdtable;

  // Semitones needed to move the played note the chosen number of scale steps.
  harmonyShift(note, v) = target - scaleNote(degree)
  with {
    pc = int(note - key + 120.0) % 12;
    degree = degreeOf(pc);
    t = degree + steps(v);
    octave = floor(t / 7.0);
    target = scaleNote(int(t - octave * 7.0)) + octave * 12.0;
  };

  harmonyStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    env = mono : an.amp_follower_ar(0.002, 0.1);
    voiced = env > 0.004;

    hz = mono : fi.lowpass(2, 1400.0) : an.pitchTracker(2, 0.025) : max(60.0) : min(1500.0);
    // Hold the last confident note between phrases so harmonies don't wander.
    note = 69.0 + 12.0 * log(hz / 440.0) / log(2.0) : ba.sAndH(voiced) : si.smooth(ba.tau2pole(0.012)) : floor(_ + 0.5);

    shiftA = harmonyShift(note, voiceA);
    shiftB = harmonyShift(note, voiceB);

    // Humanize: a little detune drift and timing offset per voice, like a real double.
    driftA = no.lfnoise(0.6) * humanize * 0.10;
    driftB = no.lfnoise(0.5) * humanize * 0.12;
    pitchVoice(shift, drift, lagMs) = mono
      : de.fdelay(4096, (2.0 + lagMs * humanize) * 0.001 * ma.SR)
      : ef.transpose(2048, 384, shift + drift);
    harmA = pitchVoice(shiftA, driftA, 18.0) * levelA;
    harmB = pitchVoice(shiftB, driftB, 27.0) * levelB;

    panA = 0.5 - width * 0.4;
    panB = 0.5 + width * 0.4;
    outL = inL * dry + harmA * (1.0 - panA) + harmB * (1.0 - panB);
    outR = inR * dry + harmA * panA + harmB * panB;
  };
};
