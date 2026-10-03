import("stdfaust.lib");

declare name "rtal-velvet-hall";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Lush modulated hall: eight-line feedback delay network with early reflections, bloom and chorused tail.";

presetMode = nentry("velvet-hall/[0]Factory Preset [style:menu{'Manual':0;'Concert Hall':1;'Chorused Void':2;'Dark Cathedral':3}]", 0, 0, 3, 1);
sizeManual = hslider("velvet-hall/[1]Size [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
decayManual = hslider("velvet-hall/[2]Decay [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
modManual = hslider("velvet-hall/[3]Modulation [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
bloomManual = hslider("velvet-hall/[4]Bloom [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
earlyManual = hslider("velvet-hall/[5]Early [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
dampManual = hslider("velvet-hall/[6]High Damp [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
predelayManual = hslider("velvet-hall/[7]Pre-Delay [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("velvet-hall/[8]Mix [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isConcert = (presetMode >= 0.5) * (presetMode < 1.5);
isVoid = (presetMode >= 1.5) * (presetMode < 2.5);
isDark = presetMode >= 2.5;

selectPreset(manual, concert, void, dark) =
  manual * isManual +
  concert * isConcert +
  void * isVoid +
  dark * isDark;

size = selectPreset(sizeManual, 0.60, 0.85, 0.95);
decay = selectPreset(decayManual, 0.55, 0.85, 0.80);
modDepth = selectPreset(modManual, 0.25, 0.85, 0.30);
bloom = selectPreset(bloomManual, 0.35, 0.65, 0.55);
early = selectPreset(earlyManual, 0.45, 0.15, 0.30);
damp = selectPreset(dampManual, 0.40, 0.35, 0.80);
predelay = selectPreset(predelayManual, 0.25, 0.10, 0.35);
mix = selectPreset(mixManual, 0.30, 0.40, 0.40);

process = _,_ : hallStereo
with {
  maxLine = 16384;
  sizeScale = 0.5 + size * 1.5;
  t60 = 0.6 + decay * decay * 12.0;
  dampHz = 16000.0 * pow(0.1, damp);

  lineMs = (29.71, 37.13, 41.11, 43.73, 53.32, 59.93, 67.31, 73.13);
  lineLen(i) = ba.take(i + 1, lineMs) * sizeScale * 0.001 * ma.SR;

  // Orthogonal 8x8 Hadamard mix (fast Walsh-Hadamard butterflies, scaled 1/sqrt(8)).
  bfly(a, b) = a + b, a - b;
  hadamard8(a0, a1, a2, a3, a4, a5, a6, a7) =
    (bfly(a0, a1), bfly(a2, a3), bfly(a4, a5), bfly(a6, a7))
    : (route(8, 8, (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8)))
    : stage2 : stage3 : par(i, 8, *(1.0 / sqrt(8.0)))
  with {
    stage2(b0, b1, b2, b3, b4, b5, b6, b7) = bfly(b0, b2), bfly(b1, b3), bfly(b4, b6), bfly(b5, b7)
      : route(8, 8, (1, 1), (2, 3), (3, 2), (4, 4), (5, 5), (6, 7), (7, 6), (8, 8));
    stage3(c0, c1, c2, c3, c4, c5, c6, c7) = bfly(c0, c4), bfly(c1, c5), bfly(c2, c6), bfly(c3, c7)
      : route(8, 8, (1, 1), (2, 5), (3, 2), (4, 6), (5, 3), (6, 7), (7, 4), (8, 8));
  };

  // Each line: slowly modulated delay, then loss for the requested decay and damping.
  line(i) = de.fdelay3(maxLine, max(16.0, lineLen(i) + wobble))
    : fi.lowpass(1, dampHz)
    : *(pow(0.001, (lineLen(i) / ma.SR) / t60))
  with {
    wobble = os.osc(0.13 + i * 0.071) * modDepth * (0.0008 + 0.0012 * (i % 3)) * ma.SR;
  };

  // Inputs are spread across the lines with alternating signs.
  fdn(l, r) = (inject : par(i, 8, line(i))) ~ hadamard8
  with {
    inject = par(i, 8, +(ba.if(i % 2, r, l) * (1.0 - 2.0 * ((i / 2) % 2)) * 0.35));
  };

  // Bloom: input diffusion that softens the attack of the tail.
  diffuse = seq(i, 4, fi.allpass_comb(2048, ba.take(i + 1, (142, 107, 379, 277)), 0.3 + bloom * 0.45));

  hallStereo(inL, inR) = outL, outR
  with {
    pre = de.fdelay(19200, min(19000.0, (2.0 + predelay * 150.0) * 0.001 * ma.SR));
    sendL = inL : fi.highpass(1, 90.0) : pre : diffuse;
    sendR = inR : fi.highpass(1, 90.0) : pre : diffuse;
    tank = fdn(sendL, sendR);
    tailL = tank : (_, !, _, !, _, !, _, !) :> *(0.5);
    tailR = tank : (!, _, !, _, !, _, !, _) :> *(0.5);
    // Early reflections: a sparse tapped pattern scaled with the room size.
    tapAt(ms, x) = x : de.fdelay(16384, ms * sizeScale * 0.001 * ma.SR);
    earlyL = inL : pre <: tapAt(7.3), tapAt(13.1), tapAt(19.9), tapAt(27.4) :> *(early * 0.3);
    earlyR = inR : pre <: tapAt(8.9), tapAt(11.7), tapAt(23.3), tapAt(31.1) :> *(early * 0.3);
    outL = inL * (1.0 - mix * 0.5) + (tailL + earlyL) * mix;
    outR = inR * (1.0 - mix * 0.5) + (tailR + earlyR) * mix;
  };
};
