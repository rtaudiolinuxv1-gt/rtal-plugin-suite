import("stdfaust.lib");

declare name "rtal-forge-rig";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Guitar multi-effects rig: twelve effects in any order, ten preamps, ten power amps, six cabinets and two placeable virtual microphones.";
// With every control at maximum (amp gain, master, +12 dB amp and output levels,
// near-unity echo feedback, 12 s reverb) the rig is loud and long by request.
declare rtal_smoke "allow-gain allow-sustain";

//==========================================================================
// Effect and model indices
//   Effects: 1 Echo, 2 Delay, 3 Ping Pong, 4 Chorus, 5 Compressor, 6 Auto-Wah,
//            7 Phaser, 8 Flanger, 9 Tremolo, 10 Reverb, 11 Noise Cancel, 12 Fuzz Box
//   Node 13 is the amp (preamp, tone stack, power amp, cabinet and microphones).
//==========================================================================


//--------------------------------------------------------------------------
// Rig presets: they set the chain, amp, cabinet and amp controls. Effect
// settings always come from each effect's own controls.
//--------------------------------------------------------------------------
presetMode = nentry("forge-rig/[0]Rig/[0]Factory Preset [style:menu{'Manual':0;'Glassy Clean':1;'Blues Breakup':2;'Plexi Classic Rock':3;'Modern Metal':4;'Nu Metal Drop':5;'Psych Fuzz Lead':6;'Ambient Swell':7}]", 0, 0, 7, 1);
nPresets = 8;
pick(manual, p1, p2, p3, p4, p5, p6, p7) = ba.selectn(nPresets, int(presetMode), manual, p1, p2, p3, p4, p5, p6, p7);

//--------------------------------------------------------------------------
// Chain: twelve slots, each runs any effect. The amp sits after slot N.
//--------------------------------------------------------------------------
slotManual(k) = nentry("forge-rig/[1]Chain/[%kk]Slot %k1 [style:menu{'Off':0;'Echo':1;'Delay':2;'Ping Pong':3;'Chorus':4;'Compressor':5;'Auto-Wah':6;'Phaser':7;'Flanger':8;'Tremolo':9;'Reverb':10;'Noise Cancel':11;'Fuzz Box':12}]", ba.take(k + 1, (11, 5, 12, 6, 0, 4, 7, 0, 2, 10, 0, 0)), 0, 12, 1)
with {
  k1 = k + 1;
  kk = k + 10;
};
ampAfterManual = nentry("forge-rig/[1]Chain/[30]Amp After Slot", 12, 0, 12, 1);

// Preset chains (slot contents for presets 1..7).
slotPreset(k) = pick(slotManual(k),
  ba.take(k + 1, (11, 5, 0, 0, 0, 4, 0, 0, 2, 10, 0, 0)),
  ba.take(k + 1, (11, 5, 0, 0, 0, 0, 0, 0, 1, 10, 0, 0)),
  ba.take(k + 1, (11, 0, 0, 0, 0, 0, 0, 0, 2, 10, 0, 0)),
  ba.take(k + 1, (11, 5, 0, 0, 0, 0, 0, 0, 2, 10, 0, 0)),
  ba.take(k + 1, (11, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0)),
  ba.take(k + 1, (12, 6, 0, 7, 0, 0, 0, 0, 1, 10, 0, 0)),
  ba.take(k + 1, (11, 5, 0, 4, 0, 0, 0, 0, 3, 10, 0, 0)));
slot(k) = int(slotPreset(k));
ampAfter = int(pick(ampAfterManual, 12, 12, 12, 12, 12, 12, 12));

//--------------------------------------------------------------------------
// Router. The chain logic (first-occurrence slots, amp insertion point) lives in
// rtal_router.h: it is control logic, and as a foreign function it is evaluated
// once per block and compiles instantly, where the same logic written as nested
// Faust selects made the compiler's range analysis crawl.
//--------------------------------------------------------------------------
nNodes = 13;
route_fn = ffunction(int rtal_route(int, int, int, int, int, int, int, int, int, int, int, int, int, int), "rtal_router.h", "");
routeOf(node) = route_fn(node, slot(0), slot(1), slot(2), slot(3), slot(4), slot(5), slot(6), slot(7), slot(8), slot(9), slot(10), slot(11), ampAfter);
sourceOf(i) = routeOf(i);
lastNode = routeOf(14);

//==========================================================================
// Shared building blocks
//==========================================================================
logCosh(x) = abs(x) + log(1.0 + exp(-2.0 * abs(x))) - log(2.0);
// First-order antiderivative anti-aliased tanh.
adaaTanh(x) = ba.if(abs(dx) < 0.0001, ma.tanh(0.5 * (x + x')), (logCosh(x) - logCosh(x')) / dx)
with {
  dx = x - x';
};
wrap(x) = x - floor(x);
phasor(hz) = (+(hz / ma.SR) : wrap) ~ _;
stereoMix(mix, dl, dr, wl, wr) = dl * (1.0 - mix) + wl * mix, dr * (1.0 - mix) + wr * mix;

//==========================================================================
// 1. Echo: tape echo with wow, saturation and darkening repeats
//==========================================================================
echoTime = hslider("forge-rig/[2]Effects/[01]Echo/[1]Time [unit:ms]", 380, 50, 900, 1) : si.smooth(ba.tau2pole(0.25));
echoFeedback = hslider("forge-rig/[2]Effects/[01]Echo/[2]Feedback [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
echoWow = hslider("forge-rig/[2]Effects/[01]Echo/[3]Wow [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
echoTone = hslider("forge-rig/[2]Effects/[01]Echo/[4]Tone [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
echoMix = hslider("forge-rig/[2]Effects/[01]Echo/[5]Mix [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;

echoLine(seed, x) = (+(x) : de.fdelay3(131072, d) : ma.tanh) ~ (fi.lowpass(1, 1500.0 + echoTone * 6000.0) : fi.highpass(1, 120.0) : *(echoFeedback * 0.95))
with {
  wow = (os.osc(0.6 + seed * 0.13) * 0.7 + os.osc(5.7 + seed) * 0.15) * echoWow * 0.006;
  d = min(130000.0, echoTime * (1.0 + seed * 0.04) * 0.001 * ma.SR * (1.0 + wow));
};
echo(l, r) = stereoMix(echoMix, l, r, echoLine(0, l), echoLine(1, r));

//==========================================================================
// 2. Delay: clean digital delay
//==========================================================================
delayTime = hslider("forge-rig/[2]Effects/[02]Delay/[1]Time [unit:ms]", 450, 20, 1500, 1) : si.smooth(ba.tau2pole(0.15));
delayFeedback = hslider("forge-rig/[2]Effects/[02]Delay/[2]Feedback [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
delayTone = hslider("forge-rig/[2]Effects/[02]Delay/[3]Tone [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
delayMix = hslider("forge-rig/[2]Effects/[02]Delay/[4]Mix [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;

delayLine(x) = (+(x) : de.fdelay(131072, min(130000.0, delayTime * 0.001 * ma.SR))) ~ (fi.lowpass(1, 1500.0 + delayTone * 16000.0) : *(delayFeedback * 0.97));
delayFx(l, r) = stereoMix(delayMix, l, r, delayLine(l), delayLine(r));

//==========================================================================
// 3. Ping Pong: repeats bounce between left and right
//==========================================================================
pingTime = hslider("forge-rig/[2]Effects/[03]Ping Pong/[1]Time [unit:ms]", 375, 20, 1500, 1) : si.smooth(ba.tau2pole(0.15));
pingFeedback = hslider("forge-rig/[2]Effects/[03]Ping Pong/[2]Feedback [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
pingTone = hslider("forge-rig/[2]Effects/[03]Ping Pong/[3]Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
pingMix = hslider("forge-rig/[2]Effects/[03]Ping Pong/[4]Mix [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;

// Inputs: feedback from right, feedback from left, mono input.
pingCore(x, fbFromR, fbFromL) = l, r
with {
  dly = de.fdelay(131072, min(130000.0, pingTime * 0.001 * ma.SR));
  l = (x + fbFromR) : dly;
  r = fbFromL : dly;
};
pingTone2 = fi.lowpass(1, 1500.0 + pingTone * 12000.0) : *(pingFeedback * 0.96);
pingPong(l, r) = stereoMix(pingMix, l, r, wetL, wetR)
with {
  wet = (l + r) * 0.5 : (pingCore ~ (pingTone2, pingTone2) : (_, _) <: (_, _, _, _) : (_, !, !, _)) ;
  wetL = wet : _, !;
  wetR = wet : !, _;
};

//==========================================================================
// 4. Chorus: two quadrature voices, one per side
//==========================================================================
chorusRate = hslider("forge-rig/[2]Effects/[04]Chorus/[1]Rate [unit:Hz]", 0.8, 0.05, 6.0, 0.01) : si.smoo;
chorusDepth = hslider("forge-rig/[2]Effects/[04]Chorus/[2]Depth [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
chorusMix = hslider("forge-rig/[2]Effects/[04]Chorus/[3]Mix [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;

chorusVoice(offset, x) = x : de.fdelay3(2048, (7.0 + sin(2.0 * ma.PI * wrap(phasor(chorusRate) + offset)) * chorusDepth * 5.0) * 0.001 * ma.SR)
  : fi.lowpass(1, 9000.0);
chorus(l, r) = l * (1.0 - chorusMix * 0.5) + chorusVoice(0.0, l) * chorusMix * 0.8,
               r * (1.0 - chorusMix * 0.5) + chorusVoice(0.25, r) * chorusMix * 0.8;

//==========================================================================
// 5. Compressor: stereo-linked, soft knee, automatic makeup, blend
//==========================================================================
compSustain = hslider("forge-rig/[2]Effects/[05]Compressor/[1]Sustain [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
compAttack = hslider("forge-rig/[2]Effects/[05]Compressor/[2]Attack [unit:ms]", 8, 0.5, 60, 0.1) : si.smoo;
compRelease = hslider("forge-rig/[2]Effects/[05]Compressor/[3]Release [unit:ms]", 180, 30, 1200, 1) : si.smoo;
compLevel = hslider("forge-rig/[2]Effects/[05]Compressor/[4]Level [unit:dB]", 0, -12, 12, 0.1) : si.smoo;
compBlend = hslider("forge-rig/[2]Effects/[05]Compressor/[5]Blend [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

compGain(l, r) = gr : ballistics : (0.0 - _) : +(makeup) : ba.db2linear
with {
  thr = 0.0 - compSustain * 40.0;
  ratio = 2.0 + compSustain * 8.0;
  slope = 1.0 - 1.0 / ratio;
  level = max(abs(l), abs(r)) : an.amp_follower_ar(0.0005, 0.03) : max(0.00001) : ba.linear2db;
  over = level - thr;
  gr = ba.if(over <= -4.0, 0.0, ba.if(over >= 4.0, slope * over, slope * (over + 4.0) * (over + 4.0) / 16.0));
  ballistics = step ~ _
  with {
    step(prev, t) = prev + (t - prev) * ba.if(t > prev, 1.0 - exp(-1.0 / (compAttack * 0.001 * ma.SR)), 1.0 - exp(-1.0 / (compRelease * 0.001 * ma.SR)));
  };
  makeup = (0.0 - thr) * slope * 0.5 + compLevel;
};
compressor(l, r) = l * g * compBlend + l * (1.0 - compBlend), r * g * compBlend + r * (1.0 - compBlend)
with {
  g = compGain(l, r);
};

//==========================================================================
// 6. Auto-Wah: envelope-swept bandpass
//==========================================================================
wahSens = hslider("forge-rig/[2]Effects/[06]Auto-Wah/[1]Sensitivity [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
wahRange = hslider("forge-rig/[2]Effects/[06]Auto-Wah/[2]Range [style:knob]", 0.65, 0.0, 1.0, 0.01) : si.smoo;
wahReso = hslider("forge-rig/[2]Effects/[06]Auto-Wah/[3]Resonance [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
wahMix = hslider("forge-rig/[2]Effects/[06]Auto-Wah/[4]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

autoWah(l, r) = stereoMix(wahMix, l, r, voice(l), voice(r))
with {
  env = (l + r) * 0.5 : abs : *(1.0 + wahSens * wahSens * 40.0) : an.amp_follower_ar(0.003, 0.15) : min(1.0);
  fc = 250.0 * pow(2.0, env * (1.0 + wahRange * 4.0)) : min(ma.SR * 0.4);
  q = 1.5 + wahReso * 8.0;
  voice(x) = x : fi.svf.bp(fc, q) : /(q) : *(2.2 + wahReso);
};

//==========================================================================
// 7. Phaser: six first-order allpass stages with feedback
//==========================================================================
phaserRate = hslider("forge-rig/[2]Effects/[07]Phaser/[1]Rate [unit:Hz]", 0.5, 0.03, 8.0, 0.01) : si.smoo;
phaserDepth = hslider("forge-rig/[2]Effects/[07]Phaser/[2]Depth [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
phaserFeedback = hslider("forge-rig/[2]Effects/[07]Phaser/[3]Feedback [style:knob]", 0.50, 0.0, 0.95, 0.01) : si.smoo;
phaserMix = hslider("forge-rig/[2]Effects/[07]Phaser/[4]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

allpass1(f) = fi.tf1(a, 1.0, a)
with {
  t = tan(ma.PI * min(f, ma.SR * 0.45) / ma.SR);
  a = (t - 1.0) / (t + 1.0);
};
phaserVoice(offset, x) = x : fi.dcblocker : (+ : seq(i, 6, allpass1(f))) ~ *(phaserFeedback)
with {
  f = 300.0 * pow(2.0, sin(2.0 * ma.PI * wrap(phasor(phaserRate) + offset)) * phaserDepth * 2.2);
};
phaser(l, r) = stereoMix(phaserMix, l, r, phaserVoice(0.0, l), phaserVoice(0.15, r)) : *(1.0 / (1.0 + phaserFeedback * 0.5)), *(1.0 / (1.0 + phaserFeedback * 0.5));

//==========================================================================
// 8. Flanger: swept short comb with feedback
//==========================================================================
flangerRate = hslider("forge-rig/[2]Effects/[08]Flanger/[1]Rate [unit:Hz]", 0.25, 0.02, 5.0, 0.01) : si.smoo;
flangerDepth = hslider("forge-rig/[2]Effects/[08]Flanger/[2]Depth [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
flangerManual = hslider("forge-rig/[2]Effects/[08]Flanger/[3]Manual [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
flangerFeedback = hslider("forge-rig/[2]Effects/[08]Flanger/[4]Feedback [style:knob]", 0.55, 0.0, 0.95, 0.01) : si.smoo;
flangerMix = hslider("forge-rig/[2]Effects/[08]Flanger/[5]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

flangerVoice(offset, x) = x : fi.dcblocker : (+ : de.fdelay3(2048, d)) ~ (*(flangerFeedback) : ma.tanh)
with {
  tri = 1.0 - 4.0 * abs(wrap(phasor(flangerRate) + offset + 0.25) - 0.5);
  d = (0.3 + flangerManual * 3.0) * (1.0 + flangerDepth * (0.5 + 0.5 * tri) * 3.0) * 0.001 * ma.SR;
};
flanger(l, r) = stereoMix(flangerMix, l, r, flangerVoice(0.0, l), flangerVoice(0.25, r)) : *(norm), *(norm)
with {
  norm = 1.2 / (1.0 + flangerFeedback * 0.6);
};

//==========================================================================
// 9. Tremolo: shape-morphing amplitude modulation, optional stereo pan
//==========================================================================
tremRate = hslider("forge-rig/[2]Effects/[09]Tremolo/[1]Rate [unit:Hz]", 5.0, 0.5, 15.0, 0.01) : si.smoo;
tremDepth = hslider("forge-rig/[2]Effects/[09]Tremolo/[2]Depth [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
tremShape = hslider("forge-rig/[2]Effects/[09]Tremolo/[3]Shape [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
tremStereo = hslider("forge-rig/[2]Effects/[09]Tremolo/[4]Stereo Pan [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;

tremolo(l, r) = l * gain(0.0), r * gain(tremStereo * 0.5)
with {
  wave(o) = sin(2.0 * ma.PI * wrap(phasor(tremRate) + o));
  shaped(o) = ma.tanh(wave(o) * (1.0 + tremShape * 8.0)) / ma.tanh(1.0 + tremShape * 8.0);
  gain(o) = (1.0 - tremDepth * (0.5 + 0.5 * shaped(o))) * (1.0 + tremDepth * 0.5);
};

//==========================================================================
// 10. Reverb: stereo FDN hall
//==========================================================================
// Clamped after smoothing: the smoother starts at 0, and a zero decay time makes
// the FDN divide by zero and latch NaN in its feedback.
reverbSize = hslider("forge-rig/[2]Effects/[10]Reverb/[1]Decay [unit:s]", 2.2, 0.3, 12.0, 0.01) : si.smoo : max(0.3);
reverbDamp = hslider("forge-rig/[2]Effects/[10]Reverb/[2]Damping [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
reverbPre = hslider("forge-rig/[2]Effects/[10]Reverb/[3]Pre-Delay [unit:ms]", 20, 0, 150, 1) : si.smoo;
reverbMix = hslider("forge-rig/[2]Effects/[10]Reverb/[4]Mix [style:knob]", 0.22, 0.0, 1.0, 0.01) : si.smoo;

reverb(l, r) = stereoMix(reverbMix, l, r, wetL, wetR)
with {
  pre = de.fdelay(8192, reverbPre * 0.001 * ma.SR);
  wet = (l : pre), (r : pre) : re.zita_rev1_stereo(0, 200.0, 12000.0 * pow(0.15, reverbDamp), reverbSize * 0.8, reverbSize, 192000);
  wetL = wet : _, !;
  wetR = wet : !, _;
};

//==========================================================================
// 11. Noise Cancel: hysteresis gate with hum notches
//==========================================================================
gateThreshold = hslider("forge-rig/[2]Effects/[11]Noise Cancel/[1]Threshold [unit:dB]", -60, -90, -20, 0.1) : si.smoo;
gateRelease = hslider("forge-rig/[2]Effects/[11]Noise Cancel/[2]Release [unit:ms]", 120, 5, 1000, 1) : si.smoo;
gateRange = hslider("forge-rig/[2]Effects/[11]Noise Cancel/[3]Range [unit:dB]", -60, -90, 0, 0.1) : si.smoo;
humMode = nentry("forge-rig/[2]Effects/[11]Noise Cancel/[4]Hum Filter [style:menu{'Off':0;'50 Hz':1;'60 Hz':2}]", 0, 0, 2, 1);

gateOpen(levelDb) = (step ~ (_, _)) : _, !
with {
  step(open, held) = newOpen, newHeld
  with {
    above = levelDb > gateThreshold;
    newHeld = ba.if(above, 0.0, held + 1.0);
    newOpen = ba.if(above, 1.0, ba.if((levelDb < gateThreshold - 6.0) * (newHeld > 0.05 * ma.SR), 0.0, open));
  };
};
humChain = seq(k, 4, ba.bypass1(humMode < 0.5, fi.notchw(3.0 + k * 2.0, ba.if(humMode > 1.5, 60.0, 50.0) * (k + 1))));
noiseCancel(l, r) = (l : humChain) * g, (r : humChain) * g
with {
  level = max(abs(l), abs(r)) : fi.highpass(1, 80.0) : an.amp_follower_ar(0.0002, 0.02) : max(0.000001) : ba.linear2db;
  floorGain = ba.db2linear(gateRange);
  open = gateOpen(level) : step ~ _
  with {
    step(prev, t) = prev + (t - prev) * ba.if(t > prev, 0.3, 1.0 - exp(-1.0 / (gateRelease * 0.001 * ma.SR)));
  };
  g = floorGain + (1.0 - floorGain) * open;
};

//==========================================================================
// 12. Fuzz Box: two ADAA clipping stages, octave and tone
//==========================================================================
fuzzAmount = hslider("forge-rig/[2]Effects/[12]Fuzz Box/[1]Fuzz [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
fuzzTone = hslider("forge-rig/[2]Effects/[12]Fuzz Box/[2]Tone [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
fuzzOctave = hslider("forge-rig/[2]Effects/[12]Fuzz Box/[3]Octave [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
fuzzLevel = hslider("forge-rig/[2]Effects/[12]Fuzz Box/[4]Level [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;

fuzzVoice(x) = out
with {
  clean = x : fi.highpass(1, 80.0);
  folded = clean * (1.0 - fuzzOctave) + abs(clean) * fuzzOctave * 1.6;
  g1 = 3.0 + fuzzAmount * fuzzAmount * 80.0;
  s1 = adaaTanh(folded * g1 + 0.1) - ma.tanh(0.1) : fi.dcblocker : fi.lowpass(1, 6000.0);
  s2 = adaaTanh(s1 * (2.0 + fuzzAmount * 5.0)) : fi.dcblocker;
  toned = (s2 : fi.lowpass(1, 700.0)) * (1.0 - fuzzTone) + (s2 : fi.highpass(1, 1000.0)) * fuzzTone + s2 * 0.25;
  out = toned : fi.lowpass(2, 7500.0) : *(0.1 + fuzzLevel * fuzzLevel * 1.2);
};
fuzzBox(l, r) = fuzzVoice(l), fuzzVoice(r);

//==========================================================================
// 13. Amp: preamp + tone stack + power amp + cabinet + two microphones
//==========================================================================

preModel = int(pick(nentry("forge-rig/[3]Amp/[01]Preamp [style:menu{'Glass Tube Pre':0;'Plex Lead 59':1;'Rectangle Triple':2;'Vex Top-30':3;'Citrus Rocker':4;'Furnace 50-50':5;'Nu Rage':6;'Blueline Deluxe':7;'Dark Star 100':8;'Boulevard Blues':9}]", 1, 0, 9, 1), 7, 9, 1, 2, 6, 4, 0));
powerModel = int(pick(nentry("forge-rig/[3]Amp/[02]Power Amp [style:menu{'Brit Iron 34':0;'Yankee 6L6':1;'Chime 84 Class A':2;'Small Box 6V6':3;'Big Bottle 88':4;'Heavy Bottle 65':5;'Transistor Slab':6;'Spongy Rectifier':7;'Brit Iron Modern':8;'Single End 6V6':9}]", 0, 0, 9, 1), 1, 3, 0, 5, 5, 0, 2));
ampGain = pick(hslider("forge-rig/[3]Amp/[03]Gain [style:knob]", 0.55, 0.0, 1.0, 0.01), 0.25, 0.55, 0.65, 0.75, 0.85, 0.60, 0.30) : si.smoo;
ampBass = pick(hslider("forge-rig/[3]Amp/[04]Bass [style:knob]", 0.55, 0.0, 1.0, 0.01), 0.50, 0.55, 0.55, 0.65, 0.70, 0.55, 0.50) : si.smoo;
ampMid = pick(hslider("forge-rig/[3]Amp/[05]Middle [style:knob]", 0.55, 0.0, 1.0, 0.01), 0.50, 0.60, 0.65, 0.40, 0.25, 0.70, 0.50) : si.smoo;
ampTreble = pick(hslider("forge-rig/[3]Amp/[06]Treble [style:knob]", 0.55, 0.0, 1.0, 0.01), 0.60, 0.55, 0.60, 0.60, 0.60, 0.50, 0.55) : si.smoo;
ampPresence = pick(hslider("forge-rig/[3]Amp/[07]Presence [style:knob]", 0.50, 0.0, 1.0, 0.01), 0.50, 0.45, 0.55, 0.60, 0.60, 0.40, 0.50) : si.smoo;
ampDepth = pick(hslider("forge-rig/[3]Amp/[08]Depth [style:knob]", 0.45, 0.0, 1.0, 0.01), 0.40, 0.45, 0.45, 0.65, 0.70, 0.40, 0.40) : si.smoo;
ampMaster = pick(hslider("forge-rig/[3]Amp/[09]Master [style:knob]", 0.45, 0.0, 1.0, 0.01), 0.30, 0.55, 0.65, 0.45, 0.50, 0.60, 0.35) : si.smoo;
ampLevel = hslider("forge-rig/[3]Amp/[10]Amp Level [unit:dB]", 0, -24, 12, 0.1) : si.smoo;

//--------------------------------------------------------------------------
// Preamp model table, 16 values per model:
//   0 input HPF Hz | 1 bright freq | 2 bright dB | 3 stage-1 max gain | 4 stage-1 bias
//   5 stage-1 LPF  | 6 stage-2 max gain | 7 stage-2 bias | 8 stage-2 LPF
//   9 stage-3 max gain (0 = no third stage) | 10 stage-3 bias
//   11 bass freq | 12 mid freq | 13 built-in mid voicing dB | 14 treble freq | 15 output trim
//--------------------------------------------------------------------------
preTable = waveform{
  40, 2500, 2, 8, 0.15, 12000, 6, 0.10, 9000, 0, 0, 120, 500, -2, 3000, 1.0,
  80, 3000, 4, 20, 0.10, 9000, 30, 0.20, 7000, 0, 0, 110, 650, -1, 2600, 1.1,
  60, 2200, 3, 30, 0.20, 8000, 40, 0.25, 6500, 25, 0.15, 90, 750, -6, 3000, 1.0,
  70, 2800, 5, 14, 0.05, 11000, 18, 0.05, 8500, 0, 0, 130, 900, -1, 3500, 0.9,
  60, 2000, 2, 25, 0.25, 7500, 35, 0.30, 6000, 0, 0, 100, 800, 2, 2500, 1.1,
  90, 2600, 3, 35, 0.15, 7500, 45, 0.20, 6000, 20, 0.10, 100, 700, -3, 2800, 1.0,
  110, 2400, 4, 40, 0.20, 7000, 50, 0.25, 5500, 30, 0.20, 85, 800, -9, 3200, 1.1,
  40, 3500, 3, 5, 0.05, 13000, 3, 0.05, 10000, 0, 0, 140, 450, -5, 3500, 1.1,
  70, 2700, 3, 25, 0.12, 8500, 35, 0.18, 6800, 15, 0.12, 100, 750, -2, 3000, 1.0,
  50, 3000, 3, 10, 0.10, 10000, 12, 0.12, 8000, 0, 0, 120, 550, -3, 3200, 0.95};
preParam(p) = preTable, int(preModel * 16 + p) : rdtable : si.smooth(ba.tau2pole(0.03));

//--------------------------------------------------------------------------
// Power amp model table, 11 values per model:
//   0 max drive | 1 asymmetry | 2 sag | 3 crossover | 4 hardness (negative feedback)
//   5 transformer low cut | 6 high cut | 7 resonance freq | 8 resonance dB
//   9 presence freq | 10 output trim
//--------------------------------------------------------------------------
powerTable = waveform{
  8, 0.05, 0.40, 0.020, 0.40, 70, 9000, 100, 3, 3200, 1.0,
  6, 0.03, 0.30, 0.020, 0.60, 60, 10000, 90, 2, 4000, 1.0,
  10, 0.12, 0.50, 0.000, 0.30, 80, 8000, 110, 2, 3000, 1.0,
  9, 0.08, 0.60, 0.030, 0.30, 75, 7000, 110, 3, 3000, 1.0,
  4, 0.02, 0.15, 0.010, 0.70, 50, 11000, 80, 3, 4500, 1.0,
  5, 0.03, 0.20, 0.015, 0.75, 55, 10000, 85, 4, 4000, 1.0,
  3, 0.00, 0.00, 0.040, 0.95, 50, 12000, 100, 0, 5000, 1.0,
  8, 0.06, 0.90, 0.020, 0.35, 70, 8500, 100, 3, 3200, 1.0,
  7, 0.04, 0.25, 0.015, 0.65, 65, 9500, 95, 4, 3500, 1.0,
  10, 0.25, 0.70, 0.000, 0.25, 90, 6500, 120, 2, 2800, 1.0};
powerParam(p) = powerTable, int(powerModel * 11 + p) : rdtable : si.smooth(ba.tau2pole(0.03));

// One triode-style gain stage: anti-aliased asymmetric clipping, normalised.
// Small-signal gain is sqrt(g): unity for clean settings, rising gently with drive.
triode(g, bias, lp, x) = (adaaTanh(x * g + bias) - ma.tanh(bias)) / sqrt(max(1.0, g)) : fi.dcblocker : fi.lowpass(1, lp);

preamp(x) = toned
with {
  shape = ampGain * ampGain;
  stageGain(maxG) = 1.0 + (maxG - 1.0) * shape;
  s3Max = preParam(9);
  in = x : fi.highpass(1, preParam(0)) : fi.high_shelf(preParam(2), preParam(1));
  v1 = in : triode(stageGain(preParam(3)), preParam(4), preParam(5));
  v2 = v1 : triode(stageGain(preParam(6)), preParam(7), preParam(8));
  v3 = v2 : triode(stageGain(max(1.0, s3Max)), preParam(10), 7000.0);
  driven = ba.if(s3Max > 0.5, v3, v2);
  // Tone stack: bass shelf, mid peak (with the model's own voicing), treble shelf.
  toned = driven
    : fi.low_shelf((ampBass - 0.5) * 20.0, preParam(11))
    : fi.peak_eq_cq((ampMid - 0.5) * 16.0 + preParam(13), preParam(12), 0.9)
    : fi.high_shelf((ampTreble - 0.5) * 20.0, preParam(14))
    : *(preParam(15));
};

powerAmp(xIn) = out
with {
  // The phase inverter hands the output stage a much smaller signal than the
  // preamp produces; Master then pushes it from clean into saturation.
  piLevel = 0.35;
  x = xIn * piLevel;
  drive = 1.0 + (powerParam(0) - 1.0) * ampMaster * ampMaster;
  env = x : abs : an.amp_follower_ar(0.01, 0.25);
  rail = 1.0 / (1.0 + powerParam(2) * env * 3.0);
  asym = powerParam(1);
  // Crossover notch of a class AB output stage: a small dead zone around zero.
  xo = powerParam(3) * piLevel;
  crossed = x - xo * ma.tanh(x / (xo + 0.0001));
  v = crossed * drive / rail + asym;
  soft = ma.tanh(v) - ma.tanh(asym);
  hard = max(-1.0, min(1.0, v * 1.1)) - max(-1.0, min(1.0, asym * 1.1));
  sat = (soft * (1.0 - powerParam(4)) + hard * powerParam(4)) * rail / sqrt(drive);
  out = sat : fi.highpass(1, powerParam(5)) : fi.lowpass(1, powerParam(6))
    : fi.peak_eq_cq(powerParam(8) * (0.3 + ampDepth * 1.7), powerParam(7), 1.2)
    : fi.high_shelf((ampPresence - 0.5) * 12.0, powerParam(9))
    : *(powerParam(10) * 1.4 / piLevel);
};

//--------------------------------------------------------------------------
// Cabinet table, 8 values per cabinet (row 0 unused: Direct bypasses the cab):
//   0 low cut | 1 low resonance freq | 2 resonance dB | 3 low-mid dip freq | 4 dip dB
//   5 presence freq | 6 presence dB | 7 top roll-off freq
//--------------------------------------------------------------------------
cabModel = int(pick(nentry("forge-rig/[4]Cab and Mics/[01]Cabinet [style:menu{'Direct (No Cab)':0;'1x12 Blue Open':1;'2x12 Open Jazz':2;'4x12 Vintage Thirty':3;'4x12 Greenie 25':4;'2x12 Brit Alnico':5;'4x10 Tweed':6}]", 3, 0, 6, 1), 1, 5, 4, 3, 3, 4, 2));
cabTable = waveform{
  20, 100, 0, 1000, 0, 3000, 0, 20000,
  70, 110, 3, 800, -2, 2500, 4, 5500,
  65, 100, 2, 600, -1, 2000, 2, 6500,
  75, 95, 4, 1000, -4, 2800, 6, 5000,
  70, 90, 3, 900, -2, 2300, 4, 4800,
  70, 105, 3, 700, -1, 3000, 5, 6000,
  80, 120, 2, 500, -1, 2200, 3, 5200};
cabParam(p) = cabTable, int(cabModel * 8 + p) : rdtable : si.smooth(ba.tau2pole(0.03));
cabinet(x) = ba.if(cabModel == 0, x, speaker)
with {
  speaker = x : fi.highpass(2, cabParam(0))
    : fi.peak_eq_cq(cabParam(2), cabParam(1), 1.5)
    : fi.peak_eq_cq(cabParam(4), cabParam(3), 1.0)
    : fi.peak_eq_cq(cabParam(6), cabParam(5), 1.3)
    : fi.lowpass(4, cabParam(7));
};

//--------------------------------------------------------------------------
// Virtual microphones. Mic type table, 5 values per type:
//   0 low cut | 1 presence freq | 2 presence dB | 3 top roll-off | 4 proximity strength
//--------------------------------------------------------------------------
micTable = waveform{
  60, 5000, 4.0, 13000, 1.0,
  30, 4000, -3.0, 8000, 1.5,
  25, 10000, 2.5, 18000, 0.8};
micLayout = nentry("forge-rig/[4]Cab and Mics/[02]Mic Layout [style:menu{'Stereo A-B':0;'Mono Blend':1;'Mic A Only':2}]", 0, 0, 2, 1);
micA = (
  nentry("forge-rig/[4]Cab and Mics/[10]Mic A Type [style:menu{'Dynamic Cardioid':0;'Ribbon Figure-8':1;'Large Condenser':2}]", 0, 0, 2, 1),
  hslider("forge-rig/[4]Cab and Mics/[11]Mic A Position (Cap to Edge) [style:knob]", 0.25, 0.0, 1.0, 0.01),
  hslider("forge-rig/[4]Cab and Mics/[12]Mic A Distance [unit:cm]", 3, 1, 100, 0.5),
  hslider("forge-rig/[4]Cab and Mics/[13]Mic A Angle [unit:deg]", 0, 0, 60, 1),
  hslider("forge-rig/[4]Cab and Mics/[14]Mic A Level [unit:dB]", 0, -24, 6, 0.1));
micB = (
  nentry("forge-rig/[4]Cab and Mics/[20]Mic B Type [style:menu{'Dynamic Cardioid':0;'Ribbon Figure-8':1;'Large Condenser':2}]", 1, 0, 2, 1),
  hslider("forge-rig/[4]Cab and Mics/[21]Mic B Position (Cap to Edge) [style:knob]", 0.65, 0.0, 1.0, 0.01),
  hslider("forge-rig/[4]Cab and Mics/[22]Mic B Distance [unit:cm]", 15, 1, 100, 0.5),
  hslider("forge-rig/[4]Cab and Mics/[23]Mic B Angle [unit:deg]", 15, 0, 60, 1),
  hslider("forge-rig/[4]Cab and Mics/[24]Mic B Level [unit:dB]", 0, -24, 6, 0.1));
roomMic = hslider("forge-rig/[4]Cab and Mics/[30]Room Mic [style:knob]", 0.10, 0.0, 1.0, 0.01) : si.smoo;

// One microphone on the speaker. Inputs: type, position, distance (cm), angle, level, signal.
microphone(type, position, distanceCm, angle, levelDb, x) = out
with {
  mp(p) = micTable, int(int(type) * 5 + p) : rdtable;
  pos = position : si.smoo;
  d = distanceCm * 0.01 : si.smoo;
  ang = angle : si.smoo;
  // Cap centre is brightest; towards the cone edge the top end falls away and
  // the low mids thicken.
  placement = fi.high_shelf(2.0 - pos * 10.0, 2500.0) : fi.lowpass(1, 14000.0 - pos * 9000.0)
    : fi.peak_eq_cq(pos * 2.5, 250.0, 1.0) : *(1.0 + pos * 0.8);
  // Off-axis angle rolls off treble.
  axis = fi.lowpass(1, 18000.0 - ang * 240.0) : fi.high_shelf(0.0 - ang * 0.1, 4000.0);
  // Proximity effect: close directional mics gain bass.
  proximity = fi.low_shelf(mp(4) * 9.0 * exp(0.0 - d / 0.08), 150.0);
  // Distance: arrival delay (sets phase against the other mic), level, and a
  // floor reflection that grows with distance.
  arrival = d / 343.0 * ma.SR;
  bounce = (sqrt(d * d + 0.64) - d) / 343.0 * ma.SR;
  distanceLevel = 1.0 / (1.0 + d * 4.0);
  room = _ <: de.fdelay(8192, arrival), (de.fdelay(8192, arrival + bounce) : fi.lowpass(1, 5000.0) : *(0.35 * d / (d + 0.3))) :> _;
  character = fi.highpass(1, mp(0)) : fi.peak_eq_cq(mp(2), mp(1), 1.2) : fi.lowpass(2, mp(3));
  out = x : placement : axis : proximity : character : room : *(distanceLevel * (1.0 + d * 1.5) * ba.db2linear(levelDb : si.smoo));
};

ampNode(l, r) = outL, outR
with {
  ampL = l : preamp : powerAmp : cabinet;
  ampR = r : preamp : powerAmp : cabinet;
  mA = micA, ampL : microphone;
  mB = micB, ampR : microphone;
  mono = (mA + mB) * 0.5;
  roomL = (ampL + ampR) * 0.5 : de.fdelay(8192, 0.023 * ma.SR) : fi.lowpass(1, 4000.0) : *(roomMic * 0.6);
  roomR = (ampL + ampR) * 0.5 : de.fdelay(8192, 0.031 * ma.SR) : fi.lowpass(1, 4000.0) : *(roomMic * 0.6);
  outL = ba.selectn(3, micLayout, mA, mono, mA) + roomL;
  outR = ba.selectn(3, micLayout, mB, mono, mA) + roomR;
  gain = ba.db2linear(ampLevel);
};

//==========================================================================
// Output stage
//==========================================================================
outWidth = hslider("forge-rig/[5]Output/[1]Stereo Width [style:knob]", 0.6, 0.0, 1.0, 0.01) : si.smoo;
outLevel = hslider("forge-rig/[5]Output/[2]Output Level [unit:dB]", 0, -30, 12, 0.1) : si.smoo;
outputStage(l, r) = safe(m + s), safe(m - s)
with {
  m = (l + r) * 0.5;
  s = (l - r) * 0.5 * outWidth * 2.0;
  // Gentle safety clipper above full scale.
  safe(x) = x * ba.db2linear(outLevel) : max(-4.0) : min(4.0) : (ma.tanh(_ * 0.5) * 2.0);
};

//==========================================================================
// The node graph
//==========================================================================
// Node i as a stereo block.
nodeFx(1) = echo;
nodeFx(2) = delayFx;
nodeFx(3) = pingPong;
nodeFx(4) = chorus;
nodeFx(5) = compressor;
nodeFx(6) = autoWah;
nodeFx(7) = phaser;
nodeFx(8) = flanger;
nodeFx(9) = tremolo;
nodeFx(10) = reverb;
nodeFx(11) = noiseCancel;
nodeFx(12) = fuzzBox;
// -6 dB house trim keeps the amp near unity loudness at default settings.
nodeFx(13) = ampNode : *(0.5 * ba.db2linear(ampLevel)), *(0.5 * ba.db2linear(ampLevel));

// Bus layout fed back each sample: (n1L, n1R, ..., n13L, n13R).
// The routing indices are computed outside the feedback loop and enter it as
// plain signals: keeping the control logic out of the recursive group is what
// keeps this graph quick to compile.
//
// regroup: 26 fed-back node outputs + dry L/R  ->  14 left then 14 right
// candidates, so index 0 is the dry input and index n is node n.
regroup = route(28, 28,
  par(j, 13, (2 * j + 1, j + 2), (2 * j + 2, j + 16)),
  (27, 1), (28, 15));

// One-hot selector: 14 candidates followed by an index -> the chosen candidate.
// select2 rather than multiplication, so a NaN in an unselected node can never
// leak into the chain (0 * NaN is still NaN).
oneHot(j) = (_, ==(j)) : ro.cross(2) : (_, (0.0, _)) : select2;
pickOne = (si.bus(14), (_ <: si.bus(14))) : ro.interleave(14, 2) : par(j, 14, oneHot(j)) :> _;
// 14 left + 14 right candidates and an index -> chosen (left, right).
pickStereo = (si.bus(28), (_ <: _, _))
  : route(30, 30, par(j, 14, (j + 1, j + 1)), par(j, 14, (j + 15, j + 16)), (29, 15), (30, 30))
  : pickOne, pickOne;

// Hand every node (and the final output) its own copy of the candidates plus its index.
nPicks = nNodes + 1;
distribute = (si.bus(28) <: par(i, nPicks, si.bus(28))), si.bus(nPicks)
  : route(29 * nPicks, 29 * nPicks,
      par(i, nPicks, par(j, 28, (28 * i + j + 1, 29 * i + j + 1)), (28 * nPicks + i + 1, 29 * i + 29)));

body = (regroup, si.bus(nPicks)) : distribute
  : (par(i, nNodes, pickStereo : nodeFx(i + 1)), pickStereo);
indices = par(i, nNodes, sourceOf(i + 1)), lastNode;
rig = (si.bus(2), indices) : (body ~ si.bus(26)) : (si.block(26), _, _);

process = _,_ : rig : outputStage;
