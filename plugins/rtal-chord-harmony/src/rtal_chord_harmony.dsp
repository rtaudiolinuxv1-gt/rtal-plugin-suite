import("stdfaust.lib");

declare name "rtal-chord-harmony";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Chord-aware polyphonic harmonizer: recognises the chord you strum and moves every note to other chord tones, so harmonies stay inside the chord.";

//==========================================================================
// The spectral engine (rtal_chord_harmony.h) recognises the chord and builds
// both harmony voices; Faust handles the controls, timing looseness, panning
// and the mix. Harmony voices arrive about 85 ms after the dry signal (the
// analysis window needed to separate the notes of a chord).
//==========================================================================

presetMode = nentry("chord-harmony/[0]Factory Preset [style:menu{'Manual':0;'Third Above':1;'Chord Choir':2;'Stacked Inversions':3;'Low Harmony':4;'Octave Halo':5}]", 0, 0, 5, 1);
pick(manual, p1, p2, p3, p4, p5) = ba.selectn(6, int(presetMode), manual, p1, p2, p3, p4, p5);

chordMode = nentry("chord-harmony/[1]Chord/[1]Chord Source [style:menu{'Detect':0;'Manual':1}]", 0, 0, 1, 1);
manualRoot = nentry("chord-harmony/[1]Chord/[2]Manual Root [style:menu{'C':0;'C#':1;'D':2;'D#':3;'E':4;'F':5;'F#':6;'G':7;'G#':8;'A':9;'A#':10;'B':11}]", 9, 0, 11, 1);
manualQuality = nentry("chord-harmony/[1]Chord/[3]Manual Chord [style:menu{'Major':0;'Minor':1;'Dominant 7':2;'Major 7':3;'Minor 7':4;'Sus2':5;'Sus4':6;'Diminished':7;'Augmented':8;'Power':9}]", 1, 0, 9, 1);
sensitivity = hslider("chord-harmony/[1]Chord/[4]Sensitivity [style:knob]", 0.5, 0.0, 1.0, 0.01);
refA = hslider("chord-harmony/[1]Chord/[5]Reference A [unit:Hz]", 440, 430, 450, 0.1);

stepsMenu1 = nentry("chord-harmony/[2]Voice 1/[1]Interval [style:menu{'3 Chord Tones Down':-3;'2 Chord Tones Down':-2;'1 Chord Tone Down':-1;'Same Note':0;'1 Chord Tone Up':1;'2 Chord Tones Up':2;'3 Chord Tones Up':3}]", 1, -3, 3, 1);
octave1 = nentry("chord-harmony/[2]Voice 1/[2]Octave", 0, -2, 1, 1);
level1 = hslider("chord-harmony/[2]Voice 1/[3]Level [unit:dB]", -3, -60, 6, 0.1);
pan1 = hslider("chord-harmony/[2]Voice 1/[4]Pan [style:knob]", -0.5, -1, 1, 0.01);

stepsMenu2 = nentry("chord-harmony/[3]Voice 2/[1]Interval [style:menu{'3 Chord Tones Down':-3;'2 Chord Tones Down':-2;'1 Chord Tone Down':-1;'Same Note':0;'1 Chord Tone Up':1;'2 Chord Tones Up':2;'3 Chord Tones Up':3}]", -1, -3, 3, 1);
octave2 = nentry("chord-harmony/[3]Voice 2/[2]Octave", 0, -2, 1, 1);
level2 = hslider("chord-harmony/[3]Voice 2/[3]Level [unit:dB]", -60, -60, 6, 0.1);
pan2 = hslider("chord-harmony/[3]Voice 2/[4]Pan [style:knob]", 0.5, -1, 1, 0.01);

looseness = hslider("chord-harmony/[4]Mix/[1]Looseness [style:knob]", 0.3, 0.0, 1.0, 0.01) : si.smoo;
dryLevel = hslider("chord-harmony/[4]Mix/[2]Dry Level [unit:dB]", 0, -60, 6, 0.1);
wetLevel = hslider("chord-harmony/[4]Mix/[3]Harmony Level [unit:dB]", 0, -60, 6, 0.1);

rootMeter = hbargraph("chord-harmony/[5]Detected/[1]Root (C=0 ... B=11)", 0, 11);
qualityMeter = hbargraph("chord-harmony/[5]Detected/[2]Chord (Maj=0 Min=1 7=2 Maj7=3 m7=4 Sus2=5 Sus4=6 Dim=7 Aug=8 5=9)", 0, 9);
confidenceMeter = hbargraph("chord-harmony/[5]Detected/[3]Confidence", 0, 1.2);

// Preset values: voice 1 steps, octave, level; voice 2 steps, octave, level; looseness.
steps1 = int(pick(stepsMenu1, 1, 1, 1, -1, 0));
oct1 = int(pick(octave1, 0, 0, 0, 0, 1));
lvl1 = pick(level1, -3, -4, -4, -3, -6) : si.smoo;
steps2 = int(pick(stepsMenu2, 0, -1, 2, -2, 0));
oct2 = int(pick(octave2, 0, 0, 0, -1, -1));
lvl2 = pick(level2, -60, -4, -6, -5, -6) : si.smoo;
loose = pick(looseness, 0.2, 0.5, 0.3, 0.3, 0.1);

// The modulo makes Faust store the handle once per instance (in
// instanceConstants) instead of re-evaluating the constant every sample.
handle = fconstant(int rtal_ch_open, "rtal_chord_harmony.h") % 65536;
engine = ffunction(float rtal_ch_process(int, float, float, int, int, int, int, int, int, int, float, float), "rtal_chord_harmony.h", "");
voice2 = ffunction(float rtal_ch_voice2(int, float), "rtal_chord_harmony.h", "");
meter = ffunction(float rtal_ch_meter(int, int, float), "rtal_chord_harmony.h", "");

// Slowly wandering extra delay per voice, so the harmonies sit like a second
// player rather than a locked copy.
wander(seed) = no.noises(4, seed) : fi.lowpass(2, 0.7) : *(8.0) : max(-1.0) : min(1.0);
loosen(seed, x) = x : de.fdelay(4096, (0.5 + 0.5 * wander(seed)) * loose * 0.025 * ma.SR + 1.0);

panL(p) = sqrt(0.5 * (1.0 - p));
panR(p) = sqrt(0.5 * (1.0 + p));

process(l, r) = outL, outR
with {
  mono = (l + r) * 0.5;
  v1raw = engine(handle, mono, ma.SR, int(chordMode), int(manualRoot), int(manualQuality),
                 steps1, oct1, steps2, oct2, refA, sensitivity);
  // Passing voice 1 into the getters orders them after the engine call.
  v2raw = voice2(handle, v1raw);
  root = meter(handle, 0, v1raw) : rootMeter;
  quality = meter(handle, 1, v1raw) : qualityMeter;
  conf = meter(handle, 2, v1raw) : confidenceMeter;
  wet = ba.db2linear(wetLevel : si.smoo);
  v1 = v1raw : loosen(0) : *(ba.db2linear(lvl1) * wet);
  v2 = v2raw : loosen(1) : *(ba.db2linear(lvl2) * wet);
  p1 = pan1 : si.smoo;
  p2 = pan2 : si.smoo;
  dry = ba.db2linear(dryLevel : si.smoo);
  outL = l * dry + v1 * panL(p1) + v2 * panL(p2) : attach(_, root) : attach(_, quality) : attach(_, conf);
  outR = r * dry + v1 * panR(p1) + v2 * panR(p2);
};
