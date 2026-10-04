import("stdfaust.lib");

declare name "rtal-poly-synth";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Polyphonic guitar synth: picks the separate notes out of the chords you play and gives each one its own synth voice, up to six at once.";

//==========================================================================
// rtal_poly_synth.h finds up to six notes per analysis frame (iterative
// multi-pitch estimation) and keeps each on a stable voice slot. Faust renders
// the six voices: oscillators, ladder filter, envelopes and stereo spread.
//==========================================================================

presetMode = nentry("poly-synth/[0]Factory Preset [style:menu{'Manual':0;'Poly Pad':1;'Brass Section':2;'Square Organ':3;'Sub Bass Synth':4;'Glass Keys':5}]", 0, 0, 5, 1);
pick(manual, p1, p2, p3, p4, p5) = ba.selectn(6, int(presetMode), manual, p1, p2, p3, p4, p5);

sensitivity = hslider("poly-synth/[1]Tracking/[1]Sensitivity [style:knob]", 0.5, 0.0, 1.0, 0.01);
maxNotes = nentry("poly-synth/[1]Tracking/[2]Max Notes", 6, 1, 6, 1);
snapManual = hslider("poly-synth/[1]Tracking/[3]Pitch Snap [style:knob]", 0.0, 0.0, 1.0, 0.01);
glideManual = hslider("poly-synth/[1]Tracking/[4]Glide [unit:ms]", 15, 0, 500, 1);
octaveManual = nentry("poly-synth/[1]Tracking/[5]Octave", 0, -2, 1, 1);
refA = hslider("poly-synth/[1]Tracking/[6]Reference A [unit:Hz]", 440, 430, 450, 0.1);

waveManual = hslider("poly-synth/[2]Oscillators/[1]Saw to Square [style:knob]", 0.2, 0.0, 1.0, 0.01);
pwManual = hslider("poly-synth/[2]Oscillators/[2]Pulse Width [style:knob]", 0.5, 0.1, 0.9, 0.01);
detuneManual = hslider("poly-synth/[2]Oscillators/[3]Detune [unit:cents]", 8, 0, 40, 0.1);
subManual = hslider("poly-synth/[2]Oscillators/[4]Sub Octave [style:knob]", 0.2, 0.0, 1.0, 0.01);

cutoffManual = hslider("poly-synth/[3]Filter/[1]Cutoff [unit:Hz] [scale:log]", 1800, 100, 12000, 1);
resoManual = hslider("poly-synth/[3]Filter/[2]Resonance [style:knob]", 0.35, 0.0, 0.95, 0.01);
fenvManual = hslider("poly-synth/[3]Filter/[3]Envelope Amount [style:knob]", 0.5, 0.0, 1.0, 0.01);
keytrack = hslider("poly-synth/[3]Filter/[4]Key Tracking [style:knob]", 0.5, 0.0, 1.0, 0.01);

attackManual = hslider("poly-synth/[4]Envelope/[1]Attack [unit:ms]", 20, 1, 2000, 1);
decayManual = hslider("poly-synth/[4]Envelope/[2]Decay [unit:ms]", 400, 10, 4000, 1);
sustainManual = hslider("poly-synth/[4]Envelope/[3]Sustain [style:knob]", 0.7, 0.0, 1.0, 0.01);
releaseManual = hslider("poly-synth/[4]Envelope/[4]Release [unit:ms]", 300, 10, 5000, 1);
dynamicsManual = hslider("poly-synth/[4]Envelope/[5]Pick Dynamics [style:knob]", 0.5, 0.0, 1.0, 0.01);

spread = hslider("poly-synth/[5]Mix/[1]Stereo Spread [style:knob]", 0.6, 0.0, 1.0, 0.01) : si.smoo;
synthLevel = hslider("poly-synth/[5]Mix/[2]Synth Level [unit:dB]", -6, -60, 6, 0.1) : si.smoo;
dryLevel = hslider("poly-synth/[5]Mix/[3]Guitar Level [unit:dB]", -60, -60, 6, 0.1) : si.smoo;
notesMeter = hbargraph("poly-synth/[5]Mix/[4]Notes Playing", 0, 6);

// Presets: Manual, Poly Pad, Brass Section, Square Organ, Sub Bass Synth, Glass Keys.
snap = pick(snapManual, 0.3, 0.5, 1.0, 1.0, 0.2);
glide = pick(glideManual, 40, 25, 0, 10, 0);
octave = int(pick(octaveManual, 0, 0, 0, -1, 1));
wave = pick(waveManual, 0.1, 0.0, 1.0, 0.6, 0.85) : si.smoo;
pw = pick(pwManual, 0.5, 0.5, 0.5, 0.35, 0.25) : si.smoo;
detune = pick(detuneManual, 14, 9, 2, 4, 6) : si.smoo;
sub = pick(subManual, 0.15, 0.2, 0.3, 0.9, 0.0) : si.smoo;
cutoff = pick(cutoffManual, 1400, 1100, 3500, 700, 4500) : si.smoo;
reso = pick(resoManual, 0.25, 0.3, 0.1, 0.5, 0.3) : si.smoo;
fenv = pick(fenvManual, 0.3, 0.8, 0.1, 0.6, 0.7) : si.smoo;
attack = pick(attackManual, 450, 60, 5, 5, 2) * 0.001;
decay = pick(decayManual, 1500, 500, 200, 300, 900) * 0.001;
sustain = pick(sustainManual, 0.85, 0.7, 1.0, 0.6, 0.25);
release = pick(releaseManual, 1500, 250, 80, 120, 900) * 0.001;
dynamics = pick(dynamicsManual, 0.3, 0.7, 0.2, 0.6, 0.8) : si.smoo;

handle = fconstant(int rtal_ps_open, "rtal_poly_synth.h") % 65536;
engine = ffunction(float rtal_ps_process(int, float, float, float, int, float), "rtal_poly_synth.h", "");
voiceFreq = ffunction(float rtal_ps_freq(int, int, float, float, int, float), "rtal_poly_synth.h", "");
voiceAmp = ffunction(float rtal_ps_amp(int, int, float), "rtal_poly_synth.h", "");

// One synth voice from the engine's frequency/level for that slot.
voice(i, tie) = out
with {
  fIn = voiceFreq(handle, i, tie, snap, octave, refA);
  aIn = voiceAmp(handle, i, tie);
  gate = fIn > 0.0;
  // Keep the last pitch through the release; clamp after the hold (it starts at 0).
  held = ba.sAndH(gate, fIn) : max(20.0);
  f = held : si.smooth(ba.tau2pole(glide * 0.001 + 0.0005)) : max(15.0);
  det = pow(2.0, detune / 1200.0);
  // Filter key tracking from the held pitch: cheap power-law via exp/log of a slow signal.
  keyFactor = exp(keytrack * log(held / 220.0));
  saws = (os.sawtooth(f * det) + os.sawtooth(f / det)) * 0.5;
  osc = saws * (1.0 - wave) + os.pulsetrain(f, pw) * wave + os.square(f * 0.5) * sub * 0.7;
  env = en.adsr(attack, decay, sustain, release, gate);
  // Pick dynamics: follow how hard each string sounds (spectral level, ~0.003 to 0.3).
  level = aIn : si.smooth(ba.tau2pole(0.02));
  heldLevel = ba.sAndH(gate, level);
  dyn = 1.0 - dynamics + dynamics * min(1.0, sqrt(heldLevel * 12.0));
  fc = cutoff * keyFactor * (1.0 + fenv * env * 4.0) : max(40.0) : min(ma.SR * 0.42);
  out = osc * env * dyn : ve.moogLadder(min(0.9, fc / (ma.SR * 0.5)), 0.7 + reso * 3.0);
};

// First voices sit near the centre so single notes are not lopsided.
voicePan(i) = ba.take(i + 1, (0.0, -0.6, 0.6, -1.0, 1.0, -0.3)) * spread;

process(l, r) = outL, outR
with {
  mono = (l + r) * 0.5;
  count = engine(handle, mono, ma.SR, sensitivity, int(maxNotes), refA);
  voices = par(i, 6, voice(i, count));
  gainSynth = ba.db2linear(synthLevel) * 0.7 * pick(1.0, 1.0, 1.0, 0.45, 0.75, 1.1);
  synthL = voices : par(i, 6, *(sqrt(0.5 * (1.0 - voicePan(i))))) :> *(gainSynth);
  synthR = voices : par(i, 6, *(sqrt(0.5 * (1.0 + voicePan(i))))) :> *(gainSynth);
  dry = ba.db2linear(dryLevel);
  safe(x) = ma.tanh(x * 0.5) * 2.0;
  outL = synthL + l * dry : safe : attach(_, count : notesMeter);
  outR = synthR + r * dry : safe;
};
