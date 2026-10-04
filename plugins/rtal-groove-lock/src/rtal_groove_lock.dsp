import("stdfaust.lib");

declare name "rtal-groove-lock";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Groove-locked effects: hears the tempo of your playing, with no host clock, and locks a rhythmic gate, tremolo, filter sweep and delay to it.";

//==========================================================================
// rtal_groove_lock.h tracks the tempo and beat from the guitar itself and
// returns the position in a 4/4 bar (0..4 beats) every sample. The effects
// below derive all their timing from that position.
//==========================================================================

presetMode = nentry("groove-lock/[0]Factory Preset [style:menu{'Manual':0;'Pulse Tremolo':1;'Trance Gate':2;'Dotted Eighth Echo':3;'Funk Filter':4;'Everything Locked':5}]", 0, 0, 5, 1);
pick(manual, p1, p2, p3, p4, p5) = ba.selectn(6, int(presetMode), manual, p1, p2, p3, p4, p5);

tempoMode = nentry("groove-lock/[1]Tempo/[1]Tempo Source [style:menu{'Follow Playing':0;'Hold Tempo':1;'Manual':2}]", 0, 0, 2, 1);
manualBpm = hslider("groove-lock/[1]Tempo/[2]Manual Tempo [unit:BPM]", 120, 40, 240, 0.1);
minBpm = hslider("groove-lock/[1]Tempo/[3]Slowest Tempo [unit:BPM]", 70, 40, 200, 1);
maxBpm = hslider("groove-lock/[1]Tempo/[4]Fastest Tempo [unit:BPM]", 160, 60, 240, 1);
sensitivity = hslider("groove-lock/[1]Tempo/[5]Sensitivity [style:knob]", 0.5, 0.0, 1.0, 0.01);
bpmMeter = hbargraph("groove-lock/[1]Tempo/[6]Tempo [unit:BPM]", 40, 240);
beatMeter = hbargraph("groove-lock/[1]Tempo/[7]Beat", 1, 4);
lockMeter = hbargraph("groove-lock/[1]Tempo/[8]Lock", 0, 1);

gateDepthManual = hslider("groove-lock/[2]Gate/[1]Depth [style:knob]", 0.0, 0.0, 1.0, 0.01);
gatePatternManual = nentry("groove-lock/[2]Gate/[2]Pattern [style:menu{'Straight 8ths':0;'Straight 16ths':1;'Offbeats':2;'Gallop':3;'Tresillo':4;'Stutter':5;'Half Bar':6;'Broken 16ths':7}]", 1, 0, 7, 1);
gateSwingManual = hslider("groove-lock/[2]Gate/[3]Swing [style:knob]", 0.0, 0.0, 1.0, 0.01);
gateSmooth = hslider("groove-lock/[2]Gate/[4]Smoothing [unit:ms]", 6, 1, 60, 0.5);

tremDepthManual = hslider("groove-lock/[3]Tremolo/[1]Depth [style:knob]", 0.5, 0.0, 1.0, 0.01);
tremDivManual = nentry("groove-lock/[3]Tremolo/[2]Rate [style:menu{'1 Bar':0;'1/2':1;'1/4':2;'1/8':3;'1/8 Triplet':4;'1/16':5;'1/16 Triplet':6;'1/32':7}]", 3, 0, 7, 1);
tremShapeManual = hslider("groove-lock/[3]Tremolo/[3]Shape (Smooth to Chop) [style:knob]", 0.3, 0.0, 1.0, 0.01);
tremStereo = hslider("groove-lock/[3]Tremolo/[4]Stereo Offset [style:knob]", 0.0, 0.0, 0.5, 0.01);

filterDepthManual = hslider("groove-lock/[4]Filter/[1]Depth [style:knob]", 0.0, 0.0, 1.0, 0.01);
filterDivManual = nentry("groove-lock/[4]Filter/[2]Rate [style:menu{'1 Bar':0;'1/2':1;'1/4':2;'1/8':3;'1/8 Triplet':4;'1/16':5;'1/16 Triplet':6;'1/32':7}]", 2, 0, 7, 1);
filterLowManual = hslider("groove-lock/[4]Filter/[3]Low [unit:Hz] [scale:log]", 300, 80, 2000, 1);
filterHighManual = hslider("groove-lock/[4]Filter/[4]High [unit:Hz] [scale:log]", 3000, 500, 9000, 1);
filterResoManual = hslider("groove-lock/[4]Filter/[5]Resonance [style:knob]", 0.5, 0.0, 1.0, 0.01);

delayMixManual = hslider("groove-lock/[5]Delay/[1]Mix [style:knob]", 0.0, 0.0, 1.0, 0.01);
delayDivManual = nentry("groove-lock/[5]Delay/[2]Time [style:menu{'1/16':0;'1/8 Triplet':1;'1/8':2;'Dotted 1/8':3;'1/4':4;'Dotted 1/4':5;'1/2':6}]", 3, 0, 6, 1);
delayFeedbackManual = hslider("groove-lock/[5]Delay/[3]Feedback [style:knob]", 0.35, 0.0, 0.95, 0.01);
delayTone = hslider("groove-lock/[5]Delay/[4]Tone [style:knob]", 0.6, 0.0, 1.0, 0.01);
delayPingPongManual = checkbox("groove-lock/[5]Delay/[5]Ping Pong");

outLevel = hslider("groove-lock/[6]Output/[1]Level [unit:dB]", 0, -30, 12, 0.1) : si.smoo;

// Presets: Manual, Pulse Tremolo, Trance Gate, Dotted Eighth Echo, Funk Filter, Everything Locked.
gateDepth = pick(gateDepthManual, 0.0, 1.0, 0.0, 0.0, 0.7) : si.smoo;
gatePattern = int(pick(gatePatternManual, 1, 1, 1, 1, 7));
gateSwing = pick(gateSwingManual, 0.0, 0.0, 0.0, 0.3, 0.2);
tremDepth = pick(tremDepthManual, 0.8, 0.0, 0.0, 0.0, 0.3) : si.smoo;
tremDiv = int(pick(tremDivManual, 3, 3, 3, 3, 5));
tremShape = pick(tremShapeManual, 0.15, 0.3, 0.3, 0.3, 0.6) : si.smoo;
filterDepth = pick(filterDepthManual, 0.0, 0.0, 0.0, 1.0, 0.6) : si.smoo;
filterDiv = int(pick(filterDivManual, 2, 2, 2, 3, 2));
filterLow = pick(filterLowManual, 300, 300, 300, 350, 250) : si.smoo;
filterHigh = pick(filterHighManual, 3000, 3000, 3000, 2600, 4000) : si.smoo;
filterReso = pick(filterResoManual, 0.5, 0.5, 0.5, 0.75, 0.6) : si.smoo;
delayMix = pick(delayMixManual, 0.0, 0.2, 0.45, 0.0, 0.3) : si.smoo;
delayDiv = int(pick(delayDivManual, 3, 2, 3, 3, 3));
delayFeedback = pick(delayFeedbackManual, 0.35, 0.3, 0.45, 0.35, 0.4) : si.smoo;
delayPingPong = pick(delayPingPongManual, 0, 1, 0, 0, 1);

handle = fconstant(int rtal_gl_open, "rtal_groove_lock.h") % 65536;
tracker = ffunction(float rtal_gl_process(int, float, float, int, float, float, float, float), "rtal_groove_lock.h", "");
info = ffunction(float rtal_gl_info(int, int, float), "rtal_groove_lock.h", "");

frac(x) = x - floor(x);
// LFO cycles per beat for the rate menus.
cyclesPerBeat(d) = ba.selectn(8, d, 0.25, 0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0);
// Delay lengths in beats.
delayBeats(d) = ba.selectn(7, d, 0.25, 1.0 / 3.0, 0.5, 0.75, 1.0, 1.5, 2.0);

// Gate patterns: 8 patterns x 16 sixteenth-steps (1 = open).
gateTable = waveform{
  1,1,0,0, 1,1,0,0, 1,1,0,0, 1,1,0,0,
  1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0,
  0,0,1,1, 0,0,1,1, 0,0,1,1, 0,0,1,1,
  1,0,1,1, 1,0,1,1, 1,0,1,1, 1,0,1,1,
  1,1,0,1, 1,0,1,1, 0,1,1,0, 1,1,0,0,
  1,0,1,0, 1,1,1,1, 1,0,1,0, 1,0,0,0,
  1,1,1,1, 1,1,1,1, 0,0,0,0, 0,0,0,0,
  1,0,1,1, 0,1,1,0, 1,0,0,1, 1,0,1,0};

process(l, r) = outL, outR
with {
  mono = (l + r) * 0.5;
  bar = tracker(handle, mono, ma.SR, int(tempoMode), manualBpm, minBpm, maxBpm, sensitivity) : max(0.0) : min(3.9999);
  bpm = info(handle, 0, bar) : max(30.0) : min(300.0);
  lock = info(handle, 1, bar);
  beatSec = 60.0 / bpm;

  // Rhythmic gate with swing: the second sixteenth of each pair starts late.
  s16 = bar * 4.0;
  pair = floor(s16 * 0.5);
  inPair = s16 - pair * 2.0;
  step = int(pair * 2.0 + (inPair >= 1.0 + gateSwing * 0.5)) : min(15);
  gateOpen = gateTable, gatePattern * 16 + step : rdtable;
  gateGain = 1.0 - gateDepth * (1.0 - gateOpen) : si.smooth(ba.tau2pole(gateSmooth * 0.001));

  // Tremolo: raised cosine morphing into a chopped square.
  tremPhase(offset) = frac(bar * cyclesPerBeat(tremDiv) + offset);
  smoothWave(p) = 0.5 + 0.5 * cos(2.0 * ma.PI * p);
  chopWave(p) = p < 0.5;
  tremWave(p) = smoothWave(p) * (1.0 - tremShape) + chopWave(p) * tremShape : si.smooth(ba.tau2pole(0.002));
  tremGain(offset) = 1.0 - tremDepth * (1.0 - tremWave(tremPhase(offset)));

  // Filter sweep: resonant lowpass swept between Low and High on the beat.
  fPhase = frac(bar * cyclesPerBeat(filterDiv));
  sweep = 0.5 - 0.5 * cos(2.0 * ma.PI * fPhase);
  fc = filterLow * pow(filterHigh / filterLow, sweep) : min(ma.SR * 0.4);
  q = 0.7 + filterReso * 6.0;
  filt(x) = x * (1.0 - filterDepth) + (x : fi.resonlp(fc, q, 1.0) : *(1.0 / sqrt(q))) * filterDepth;

  // Tempo-synced delay (stereo or ping-pong), time glides on tempo changes.
  dTime = beatSec * delayBeats(delayDiv) * ma.SR : si.smooth(ba.tau2pole(0.25)) : max(16.0) : min(131000.0);
  damp = fi.lowpass(1, 1500.0 + delayTone * 9000.0);
  // The loop's first inputs are the feedback (A ~ B feeds B into A's first inputs).
  echoes = (route(4, 4, (1, 1), (2, 3), (3, 2), (4, 4)) : +, +
            : de.fdelay(131072, dTime), de.fdelay(131072, dTime) : damp, damp) ~ feedback
  with {
    // Ping-pong swaps the channels in the loop; straight keeps them.
    feedback(a, b) = (a * (1.0 - delayPingPong) + b * delayPingPong) * delayFeedback,
                     (b * (1.0 - delayPingPong) + a * delayPingPong) * delayFeedback;
  };

  gatedL = l * gateGain * tremGain(0.0) : filt;
  gatedR = r * gateGain * tremGain(tremStereo) : filt;
  // Ping-pong feeds the delay from the left only so the first repeat starts on one side.
  wetIn = (gatedL + gatedR * (1.0 - delayPingPong)), gatedR * (1.0 - delayPingPong);
  wet = wetIn : echoes;
  level = ba.db2linear(outLevel);
  meterBeat = floor(bar) + 1.0;
  outL = (gatedL + ba.selector(0, 2, wet) * delayMix) * level
    : attach(_, bpm : bpmMeter) : attach(_, meterBeat : beatMeter) : attach(_, lock : lockMeter);
  outR = (gatedR + ba.selector(1, 2, wet) * delayMix) * level;
};
