import("stdfaust.lib");

declare name "rtal-cross-synth";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Cross-synthesis: your guitar takes on the texture of rain, wind, whispers, crackle, bubbles, metal or a second input, while keeping its notes.";

//==========================================================================
// Faust synthesises the texture (or takes the right input); the spectral
// engine (rtal_cross_synth.h) imprints the texture's fine detail, colour and
// phase onto the guitar spectrum. Two texture streams with different random
// seeds make the result stereo.
//==========================================================================

presetMode = nentry("cross-synth/[0]Factory Preset [style:menu{'Manual':0;'Rain Guitar':1;'Whisper Strings':2;'Wind Ghost':3;'Bubble Synth':4;'Iron Bells':5}]", 0, 0, 5, 1);
pick(manual, p1, p2, p3, p4, p5) = ba.selectn(6, int(presetMode), manual, p1, p2, p3, p4, p5);

textureManual = nentry("cross-synth/[1]Texture/[1]Source [style:menu{'Rain':0;'Wind':1;'Whisper':2;'Crackle':3;'Bubbles':4;'White Noise':5;'Metal':6;'Right Input':7}]", 0, 0, 7, 1);
rateManual = hslider("cross-synth/[1]Texture/[2]Texture Rate [style:knob]", 0.5, 0.0, 1.0, 0.01);
texturePitch = hslider("cross-synth/[1]Texture/[3]Texture Pitch [style:knob]", 0.5, 0.0, 1.0, 0.01) : si.smoo;

imprintManual = hslider("cross-synth/[2]Cross/[1]Imprint [style:knob]", 0.8, 0.0, 1.0, 0.01);
keepManual = hslider("cross-synth/[2]Cross/[2]Pitch Keep [style:knob]", 0.7, 0.0, 1.0, 0.01);
colourManual = hslider("cross-synth/[2]Cross/[3]Texture Colour [style:knob]", 0.4, 0.0, 1.0, 0.01);
phaseManual = hslider("cross-synth/[2]Cross/[4]Texture Phase [style:knob]", 0.5, 0.0, 1.0, 0.01);
smoothing = hslider("cross-synth/[2]Cross/[5]Envelope Smoothing [style:knob]", 0.5, 0.0, 1.0, 0.01);

wetLevel = hslider("cross-synth/[3]Mix/[1]Cross Level [unit:dB]", 0, -60, 6, 0.1) : si.smoo;
dryLevel = hslider("cross-synth/[3]Mix/[2]Dry Level [unit:dB]", -60, -60, 6, 0.1) : si.smoo;
textureLevel = hslider("cross-synth/[3]Mix/[3]Raw Texture [unit:dB]", -60, -60, 0, 0.1) : si.smoo;

// Presets: Manual, Rain Guitar, Whisper Strings, Wind Ghost, Bubble Synth, Iron Bells.
texture = int(pick(textureManual, 0, 2, 1, 4, 6));
rate = pick(rateManual, 0.55, 0.5, 0.4, 0.6, 0.45) : si.smoo;
imprint = pick(imprintManual, 0.9, 0.8, 1.0, 0.9, 0.8);
keep = pick(keepManual, 0.75, 0.45, 0.3, 0.7, 0.8);
colour = pick(colourManual, 0.3, 0.6, 0.6, 0.3, 0.5);
phaseBlend = pick(phaseManual, 0.5, 0.8, 0.9, 0.4, 0.3);

handle = fconstant(int rtal_xs_open, "rtal_cross_synth.h") % 65536;
engine = ffunction(float rtal_xs_process(int, float, float, float, float, float, float, float, float), "rtal_cross_synth.h", "");
rightOut = ffunction(float rtal_xs_right(int, float), "rtal_cross_synth.h", "");

// ---- Texture generators (seed s gives decorrelated left/right versions) ----
noiseS(s) = no.noises(32, s);
// Random events at roughly 'density' per second: a one-sample trigger.
events(s, density) = (noiseS(s) * 0.5 + 0.5) < (density / ma.SR);
holdRandom(s, trig) = ba.sAndH(trig, noiseS(s + 2) * 0.5 + 0.5);
pitchScale = pow(4.0, texturePitch - 0.5);

rain(s) = drops + hiss
with {
  trig = events(s, 30.0 + rate * 900.0);
  f = (800.0 + holdRandom(s, trig) * 5000.0) * pitchScale;
  drops = trig * (0.5 + holdRandom(s + 1, trig)) * 8.0 : fi.resonbp(f, 12.0, 1.0) : *(0.4);
  hiss = noiseS(s) : fi.highpass(2, 3000.0) : *(0.03);
};

wind(s) = noiseS(s) : fi.resonbp(fc, 2.5, 1.0) : *(gust)
with {
  slow = noiseS(s + 1) : fi.lowpass(2, 0.3 + rate * 2.0) : *(30.0) : max(-1.0) : min(1.0);
  fc = 500.0 * pow(4.0, slow) * pitchScale;
  gust = noiseS(s + 3) : fi.lowpass(2, 0.2 + rate) : *(20.0) : abs : +(0.25) : min(1.5) : *(0.6);
};

whisper(s) = noiseS(s) <: (fi.resonbp(f1, 6.0, 1.0) * 0.8, fi.resonbp(f2, 8.0, 1.0) * 0.5, fi.resonbp(f3, 10.0, 1.0) * 0.3) :> *(0.7)
with {
  v = noiseS(s + 1) : fi.lowpass(1, 0.4 + rate * 3.0) : *(25.0) : max(-1.0) : min(1.0) : *(0.5) : +(0.5);
  f1 = (300.0 + v * 500.0) * pitchScale;
  f2 = (900.0 + (1.0 - v) * 1300.0) * pitchScale;
  f3 = 2600.0 * pitchScale;
};

crackle(s) = pops + dust
with {
  trig = events(s, 8.0 + rate * 300.0);
  pops = trig * (0.3 + holdRandom(s, trig)) * 6.0 : fi.highpass(2, 900.0 * pitchScale) : *(0.7);
  dust = noiseS(s) * (noiseS(s + 1) > 0.97) * 0.4;
};

bubbles(s) = osc * env
with {
  trig = events(s, 4.0 + rate * 60.0);
  age = (+(1.0 / ma.SR) : *(1.0 - trig)) ~ _;
  f0 = (300.0 + holdRandom(s, trig) * 1200.0) * pitchScale;
  f = f0 * (1.0 + age * 25.0);
  osc = os.osc(f);
  env = exp(0.0 - age * 40.0) * (age > 0.0) * 0.6;
};

whiteNoise(s) = noiseS(s) * 0.3;

metal(s) = trig * 4.0 + noiseS(s) * 0.004 <: par(i, 5, fi.resonbp(ba.take(i + 1, (1.0, 2.76, 5.40, 8.93, 13.3)) * base, 120.0, 1.0)) :> *(0.25)
with {
  trig = events(s, 2.0 + rate * 25.0);
  base = (200.0 + holdRandom(s, trig) * 400.0) * pitchScale;
};

textureOf(s, rightIn) = ba.selectn(8, texture, rain(s), wind(s), whisper(s), crackle(s), bubbles(s), whiteNoise(s), metal(s), rightIn);

process(l, r) = outL, outR
with {
  useRight = texture == 7;
  guitarIn = ba.if(useRight, l, (l + r) * 0.5);
  t0 = textureOf(10, r);
  t1 = textureOf(20, r);
  crossL = engine(handle, guitarIn, t0, t1, imprint, keep, colour, phaseBlend, smoothing);
  crossR = rightOut(handle, crossL);
  wet = ba.db2linear(wetLevel);
  dry = ba.db2linear(dryLevel);
  raw = ba.db2linear(textureLevel);
  safe(x) = ma.tanh(x * 0.5) * 2.0;
  outL = crossL * wet + l * dry + t0 * raw * (1.0 - useRight) : safe;
  outR = crossR * wet + ba.if(useRight, l, r) * dry + t1 * raw * (1.0 - useRight) : safe;
};
