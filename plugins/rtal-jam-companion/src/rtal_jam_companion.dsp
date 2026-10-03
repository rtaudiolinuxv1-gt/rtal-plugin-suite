import("stdfaust.lib");

declare name "rtal-jam-companion";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Jam companion: a drummer and bass player that hear your tempo and chords and play along, starting when you start and stopping when you stop.";
// In Always mode the band keeps playing after the guitar stops.
declare rtal_smoke "allow-sustain";

//==========================================================================
// rtal_jam_companion.h tracks tempo, beat, downbeat and chords from the
// guitar. Faust plays the band: sixteen-step drum and bass patterns per
// style, a synthesised kit, and a bass that follows the detected chord.
//==========================================================================

presetMode = nentry("jam-companion/[0]Factory Preset [style:menu{'Manual':0;'Rock Band':1;'Funk Groove':2;'Blues Shuffle':3;'Indie Half-Time':4;'Bossa Lounge':5}]", 0, 0, 5, 1);
pick(manual, p1, p2, p3, p4, p5) = ba.selectn(6, int(presetMode), manual, p1, p2, p3, p4, p5);

styleManual = nentry("jam-companion/[1]Band/[1]Style [style:menu{'Rock':0;'Funk':1;'Shuffle':2;'Half-Time':3;'Ballad':4;'Four on the Floor':5;'Bossa':6;'Punk':7}]", 0, 0, 7, 1);
bandMode = nentry("jam-companion/[1]Band/[2]Band Plays [style:menu{'When I Play':0;'Always':1;'Stopped':2}]", 0, 0, 2, 1);
swingManual = hslider("jam-companion/[1]Band/[3]Swing [style:knob]", 0.0, 0.0, 1.0, 0.01);
complexityManual = hslider("jam-companion/[1]Band/[4]Complexity [style:knob]", 0.4, 0.0, 1.0, 0.01);
humanize = hslider("jam-companion/[1]Band/[5]Humanize [style:knob]", 0.4, 0.0, 1.0, 0.01);

tempoMode = nentry("jam-companion/[2]Listening/[1]Tempo Source [style:menu{'Follow Playing':0;'Hold Tempo':1;'Manual':2}]", 0, 0, 2, 1);
manualBpm = hslider("jam-companion/[2]Listening/[2]Manual Tempo [unit:BPM]", 100, 40, 240, 0.1);
minBpm = hslider("jam-companion/[2]Listening/[3]Slowest Tempo [unit:BPM]", 70, 40, 200, 1);
maxBpm = hslider("jam-companion/[2]Listening/[4]Fastest Tempo [unit:BPM]", 160, 60, 240, 1);
chordMode = nentry("jam-companion/[2]Listening/[5]Chord Source [style:menu{'Detect':0;'Manual':1}]", 0, 0, 1, 1);
manualRoot = nentry("jam-companion/[2]Listening/[6]Manual Root [style:menu{'C':0;'C#':1;'D':2;'D#':3;'E':4;'F':5;'F#':6;'G':7;'G#':8;'A':9;'A#':10;'B':11}]", 9, 0, 11, 1);
manualQuality = nentry("jam-companion/[2]Listening/[7]Manual Chord [style:menu{'Major':0;'Minor':1;'Dominant 7':2;'Major 7':3;'Minor 7':4;'Sus2':5;'Sus4':6;'Diminished':7;'Augmented':8;'Power':9}]", 0, 0, 9, 1);
sensitivity = hslider("jam-companion/[2]Listening/[8]Sensitivity [style:knob]", 0.5, 0.0, 1.0, 0.01);

drumLevel = hslider("jam-companion/[3]Mix/[1]Drums [unit:dB]", -6, -60, 6, 0.1) : si.smoo;
drumTone = hslider("jam-companion/[3]Mix/[2]Drum Tone [style:knob]", 0.5, 0.0, 1.0, 0.01) : si.smoo;
bassLevel = hslider("jam-companion/[3]Mix/[3]Bass [unit:dB]", -6, -60, 6, 0.1) : si.smoo;
bassToneManual = hslider("jam-companion/[3]Mix/[4]Bass Tone [style:knob]", 0.4, 0.0, 1.0, 0.01);
bassOctave = nentry("jam-companion/[3]Mix/[5]Bass Octave", 0, -1, 1, 1);
bassLength = hslider("jam-companion/[3]Mix/[6]Bass Note Length [style:knob]", 0.6, 0.05, 1.0, 0.01);
guitarLevel = hslider("jam-companion/[3]Mix/[7]Guitar [unit:dB]", 0, -60, 6, 0.1) : si.smoo;

bpmMeter = hbargraph("jam-companion/[4]Heard/[1]Tempo [unit:BPM]", 40, 240);
beatMeter = hbargraph("jam-companion/[4]Heard/[2]Beat", 1, 4);
rootMeter = hbargraph("jam-companion/[4]Heard/[3]Root (C=0 ... B=11)", 0, 11);
qualityMeter = hbargraph("jam-companion/[4]Heard/[4]Chord (Maj=0 Min=1 7=2 Maj7=3 m7=4 Sus2=5 Sus4=6 Dim=7 Aug=8 5=9)", 0, 9);
playingMeter = hbargraph("jam-companion/[4]Heard/[5]Band Playing", 0, 1);

// Presets: Manual, Rock Band, Funk Groove, Blues Shuffle, Indie Half-Time, Bossa Lounge.
style = int(pick(styleManual, 0, 1, 2, 3, 6));
swing = pick(swingManual, 0.0, 0.15, 0.65, 0.0, 0.1);
complexity = pick(complexityManual, 0.4, 0.6, 0.35, 0.3, 0.3);
bassTone = pick(bassToneManual, 0.4, 0.6, 0.35, 0.3, 0.25) : si.smoo;

handle = fconstant(int rtal_jc_open, "rtal_jam_companion.h") % 65536;
engine = ffunction(float rtal_jc_process(int, float, float, int, float, float, float, float, int, int, int), "rtal_jam_companion.h", "");
info = ffunction(float rtal_jc_info(int, int, float), "rtal_jam_companion.h", "");

// ---- Patterns: 8 styles x 16 sixteenth steps --------------------------------
kickTable = waveform{
  1,0,0,0, 0,0,0,0, 1,0,1,0, 0,0,0,0,
  1,0,0,.6, 0,0,1,0, 0,0,1,0, 0,.6,0,0,
  1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,.5,0,
  1,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0,
  1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0,
  1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0,
  1,0,0,.6, 1,0,0,.6, 1,0,0,.6, 1,0,0,.6,
  1,0,1,0, 0,0,1,0, 1,0,1,0, 0,0,1,0};
snareTable = waveform{
  0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0,
  0,0,0,0, 1,0,0,.3, 0,.3,0,0, 1,0,0,.3,
  0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0,
  0,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0,
  0,0,0,0, .6,0,0,0, 0,0,0,0, .6,0,0,0,
  0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0,
  .7,0,0,.7, 0,0,.7,0, 0,0,.7,0, 0,.7,0,0,
  0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0};
hatTable = waveform{
  .8,0,.5,0, .8,0,.5,0, .8,0,.5,0, .8,0,.5,0,
  .7,.4,.7,.4, .7,.4,.7,.4, .7,.4,.7,.4, .7,.4,.7,.4,
  .8,0,.5,0, .8,0,.5,0, .8,0,.5,0, .8,0,.5,0,
  .8,0,.6,0, .8,0,.6,0, .8,0,.6,0, .8,0,.6,0,
  .5,0,.3,0, .5,0,.3,0, .5,0,.3,0, .5,0,.3,0,
  .4,.3,0,.3, .4,.3,0,.3, .4,.3,0,.3, .4,.3,0,.3,
  .5,0,.5,0, .5,0,.5,0, .5,0,.5,0, .5,0,.5,0,
  .9,0,.9,0, .9,0,.9,0, .9,0,.9,0, .9,0,.9,0};
openHatTable = waveform{
  0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,.6,0,
  0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
  0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
  0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
  0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
  0,0,.7,0, 0,0,.7,0, 0,0,.7,0, 0,0,.7,0,
  0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
  0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0};
// Bass: 0 rest, 1 root, 2 fifth, 3 octave, 4 third, 5 seventh.
bassTable = waveform{
  1,0,1,0, 1,0,1,0, 1,0,1,0, 2,0,3,0,
  1,0,0,3, 0,0,1,0, 0,1,2,0, 0,3,0,5,
  1,0,4,0, 2,0,3,0, 1,0,4,0, 2,0,5,0,
  1,0,0,0, 0,0,0,0, 1,0,0,1, 0,0,0,0,
  1,0,0,0, 0,0,0,0, 2,0,0,0, 0,0,0,0,
  0,0,1,0, 0,0,1,3, 0,0,1,0, 0,0,1,2,
  1,0,0,2, 2,0,0,1, 1,0,0,2, 2,0,0,1,
  1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0};

lookup(table, s, st) = table, int(s * 16 + st) : rdtable;

// One-pole decaying envelope fired by a velocity impulse.
decayEnv(decaySec, trigVel) = trigVel : (+ ~ *(exp(-1.0 / (decaySec * ma.SR)))) : min(1.5);

noiseS(s) = no.noises(8, s);

process(l, r) = outL, outR
with {
  mono = (l + r) * 0.5;
  bar = engine(handle, mono, ma.SR, int(tempoMode), manualBpm, minBpm, maxBpm, sensitivity,
               int(chordMode), int(manualRoot), int(manualQuality)) : max(0.0) : min(3.9999);
  bpm = info(handle, 0, bar);
  root = int(info(handle, 1, bar));
  quality = int(info(handle, 2, bar));
  idle = info(handle, 3, bar);
  barSec = 240.0 / max(bpm, 30.0);

  // Start and stop on bar lines.
  barWrap = bar < bar' - 2.0;
  wantOn = ba.selectn(3, int(bandMode), idle < barSec * 1.5, 1, 0);
  bandOn = ba.sAndH(barWrap | (wantOn < 0.5), wantOn);
  bandGain = bandOn : si.smooth(ba.tau2pole(0.03));
  barCount = (+(barWrap) : %(4)) ~ _;

  // Sixteenth step with swing (the second sixteenth of each pair starts late).
  s16 = bar * 4.0;
  pairIdx = floor(s16 * 0.5);
  inPair = s16 - pairIdx * 2.0;
  step = int(pairIdx * 2.0 + (inPair >= 1.0 + swing * 0.5)) : min(15);
  // Fire only when the step moves forward (or wraps to the next bar).
  stepTrig = ((step > step') | (step < step' - 8)) * bandOn;
  rnd(seed) = ba.sAndH(stepTrig, noiseS(seed) * 0.5 + 0.5);
  vary = 1.0 - humanize * 0.35 * rnd(1);

  // Complexity: ghost snares, extra sixteenth hats and a snare fill in the last bar of four.
  fill = (barCount == 3) * (step >= 12) * (rnd(2) < complexity * 0.9) * (0.35 + 0.15 * (step - 12));
  ghost = (rnd(3) < complexity * 0.22) * 0.22;
  extraHat = (step % 2 == 1) * (rnd(4) < complexity * 0.5) * 0.3;

  kVel = lookup(kickTable, style, step);
  sVel = max(lookup(snareTable, style, step), max(fill, ghost * (lookup(kickTable, style, step) == 0)));
  hVel = max(lookup(hatTable, style, step), extraHat);
  oVel = lookup(openHatTable, style, step);
  trigK = stepTrig * kVel * vary;
  trigS = stepTrig * sVel * vary;
  trigH = stepTrig * hVel * vary;
  trigO = stepTrig * oVel * vary;

  // Kit.
  kEnv = decayEnv(0.18 + drumTone * 0.25, trigK);
  kPitch = decayEnv(0.025, trigK);
  kick = os.osc(42.0 + 120.0 * min(1.0, kPitch)) * min(1.0, kEnv) * 1.1
       + (noiseS(5) : fi.highpass(2, 2500.0)) * decayEnv(0.003, trigK) * 0.4;
  sEnv = decayEnv(0.09 + drumTone * 0.12, trigS);
  snare = (noiseS(6) : fi.bandpass(1, 1200.0, 6000.0 + drumTone * 4000.0)) * min(1.0, sEnv) * 0.7
        + os.osc(185.0) * min(1.0, decayEnv(0.05, trigS)) * 0.4;
  closedEnv = decayEnv(0.03 + drumTone * 0.02, trigH);
  // A closed hat chokes a ringing open hat.
  openEnv = trigO : (+ ~ *(exp(-1.0 / (0.28 * ma.SR)) * (1.0 - (trigH > 0.0)))) : min(1.0);
  hatNoise = noiseS(7) : fi.highpass(2, 6500.0 + drumTone * 2500.0);
  hats = hatNoise * (min(1.0, closedEnv) * 0.35 + openEnv * 0.25);

  // Bass: chord-aware notes, held until the next note or the note length.
  code = int(lookup(bassTable, style, step));
  trigB = stepTrig * (code > 0);
  third = ba.selectn(10, quality, 4, 3, 4, 4, 3, 2, 5, 3, 4, 7);
  seventh = ba.selectn(10, quality, 10, 10, 10, 11, 10, 10, 10, 9, 10, 10);
  interval = ba.selectn(6, code, 0, 0, 7, 12, third, seventh);
  rootPc = (root - 4 + 12) % 12;
  note = 28.0 + rootPc + interval + 12.0 * bassOctave;
  heldNote = ba.sAndH(trigB, note) : max(20.0);
  bassF = 440.0 * pow(2.0, (heldNote - 69.0) / 12.0);
  stepSec = barSec / 16.0;
  gateLen = (+(1.0 / ma.SR) : *(1.0 - trigB)) ~ _;
  bassGate = (gateLen < stepSec * (0.3 + bassLength * 3.5)) * bandOn;
  bassAmp = en.adsr(0.004, 0.25, 0.65, 0.06, bassGate);
  bassOsc = os.sawtooth(bassF) * 0.6 + os.osc(bassF) * 0.8;
  bass = bassOsc * bassAmp : ve.moogLadder(min(0.9, (120.0 + bassTone * 1600.0) * (1.0 + bassAmp * 2.0) / (ma.SR * 0.5)), 1.2);

  drums = (kick + snare) * ba.db2linear(drumLevel) * bandGain;
  hatsOut = hats * ba.db2linear(drumLevel) * bandGain;
  bassOut = bass * ba.db2linear(bassLevel) * bandGain * 0.8;
  gtr = ba.db2linear(guitarLevel);
  safe(x) = ma.tanh(x * 0.5) * 2.0;
  meters = attach(_, bpm : bpmMeter) : attach(_, floor(bar) + 1.0 : beatMeter) : attach(_, root : rootMeter)
         : attach(_, quality : qualityMeter) : attach(_, bandOn : playingMeter);
  outL = l * gtr + drums + bassOut + hatsOut * 0.8 : safe : meters;
  outR = r * gtr + drums + bassOut + hatsOut * 1.2 : safe;
};
