import("stdfaust.lib");

declare name "rtal-chord-vocoder";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Sixteen-band vocoder: your guitar articulates a synth chord pad, fixed in a key or following the note you play.";

presetMode = nentry("chord-vocoder/[0]Factory Preset [style:menu{'Manual':0;'Robot Strings':1;'Following Choir':2;'Whisper Pad':3}]", 0, 0, 3, 1);
rootModeManual = nentry("chord-vocoder/[1]Root [style:menu{'Key':0;'Tracked':1}]", 0, 0, 1, 1);
keyManual = nentry("chord-vocoder/[2]Key [style:menu{'C':0;'C#':1;'D':2;'D#':3;'E':4;'F':5;'F#':6;'G':7;'G#':8;'A':9;'A#':10;'B':11}]", 4, 0, 11, 1);
chordManual = nentry("chord-vocoder/[3]Chord [style:menu{'Major':0;'Minor':1;'Sus2':2;'Power':3;'Maj7':4;'Min7':5}]", 1, 0, 5, 1);
octaveManual = nentry("chord-vocoder/[4]Octave [style:menu{'Low':0;'Mid':1;'High':2}]", 1, 0, 2, 1);
sharpManual = hslider("chord-vocoder/[5]Formant Sharpness [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
releaseManual = hslider("chord-vocoder/[6]Release [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
breathManual = hslider("chord-vocoder/[7]Breath [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("chord-vocoder/[8]Vocoder Level [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
dryManual = hslider("chord-vocoder/[9]Dry [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isRobot = (presetMode >= 0.5) * (presetMode < 1.5);
isChoir = (presetMode >= 1.5) * (presetMode < 2.5);
isWhisper = presetMode >= 2.5;

selectPreset(manual, robot, choir, whisper) =
  manual * isManual +
  robot * isRobot +
  choir * isChoir +
  whisper * isWhisper;

// Key always follows the menu so presets work in any song.
key = keyManual;
rootMode = selectPreset(rootModeManual, 0, 1, 0);
chord = int(selectPreset(chordManual, chordManual, 0, 4));
octaveSel = int(selectPreset(octaveManual, 1, 1, 2));
sharp = selectPreset(sharpManual, 0.60, 0.45, 0.35);
release = selectPreset(releaseManual, 0.25, 0.45, 0.70);
breath = selectPreset(breathManual, 0.10, 0.20, 0.70);
level = selectPreset(levelManual, 0.75, 0.70, 0.60);
dry = selectPreset(dryManual, 0.20, 0.30, 0.40);

process = _,_ : vocoderStereo
with {
  nBands = 16;
  lowHz = 110.0;
  highHz = 7500.0;
  bandHz(i) = lowHz * pow(highHz / lowHz, i / (nBands - 1));
  q = 3.0 + sharp * 9.0;
  // Unity-peak bandpass: resonbp's peak gain is gain * Q.
  band(i) = fi.resonbp(bandHz(i), q, 1.0 / q);

  chordTable = waveform{
    0, 4, 7, 12,
    0, 3, 7, 12,
    0, 2, 7, 12,
    0, 7, 12, 19,
    0, 4, 7, 11,
    0, 3, 7, 10};
  interval(v) = chordTable, int(chord * 4 + v) : rdtable;

  vocoderStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    env = mono : an.amp_follower_ar(0.003, 0.12);
    // Clamp after the hold: the hold starts at 0, and log(0) would poison the root with NaN.
    trackedHz = mono : fi.lowpass(2, 1300.0) : an.pitchTracker(2, 0.02) : ba.sAndH(env > 0.004) : max(50.0) : min(1200.0);
    trackedNote = 69.0 + 12.0 * log(trackedHz / 440.0) / log(2.0) : floor(_ + 0.5);
    keyNote = 48.0 + key + ba.selectn(3, octaveSel, -12.0, 0.0, 12.0);
    // Tracked root keeps the chord inside the chosen octave band.
    trackedRoot = keyNote + ((trackedNote - keyNote) - 12.0 * floor((trackedNote - keyNote) / 12.0));
    root = ba.if(rootMode > 0.5, trackedRoot, keyNote) : si.smooth(ba.tau2pole(0.02));
    voiceHz(v, detune) = 440.0 * pow(2.0, (root + interval(v) - 69.0 + detune) / 12.0);
    // Two slightly detuned saws per chord note, plus breath noise for consonants.
    carrier = par(v, 4, os.sawtooth(voiceHz(v, 0.06)) + os.sawtooth(voiceHz(v, -0.06))) :> *(0.18)
      : +(no.noise * breath * 0.5);

    relSec = 0.02 + release * release * 0.6;
    // Each band: the guitar's energy in that band shapes the carrier's same band.
    bandOut(i) = carrier : band(i) : *(mono : band(i) : an.amp_follower_ar(0.002, relSec) : *(q * 1.5));
    voc = par(i, nBands, bandOut(i)) :> *(level * 1.8) : ma.tanh;
    outL = inL * dry + voc;
    outR = inR * dry + voc;
  };
};
