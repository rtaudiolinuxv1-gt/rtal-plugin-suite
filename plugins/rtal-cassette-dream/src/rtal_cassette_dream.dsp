import("stdfaust.lib");

declare name "rtal-cassette-dream";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Lo-fi cassette deck: wow, flutter, tape saturation, worn bandwidth, dropouts and hiss.";

presetMode = nentry("cassette-dream/[0]Factory Preset [style:menu{'Manual':0;'Pocket Walkman':1;'Fourth Generation Dub':2;'Attic Find':3}]", 0, 0, 3, 1);
wowManual = hslider("cassette-dream/[1]Wow [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
flutterManual = hslider("cassette-dream/[2]Flutter [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
saturationManual = hslider("cassette-dream/[3]Saturation [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
ageManual = hslider("cassette-dream/[4]Age [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
dropoutManual = hslider("cassette-dream/[5]Dropouts [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
hissManual = hslider("cassette-dream/[6]Hiss [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("cassette-dream/[7]Azimuth [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("cassette-dream/[8]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isWalkman = (presetMode >= 0.5) * (presetMode < 1.5);
isDub = (presetMode >= 1.5) * (presetMode < 2.5);
isAttic = presetMode >= 2.5;

selectPreset(manual, walkman, dub, attic) =
  manual * isManual +
  walkman * isWalkman +
  dub * isDub +
  attic * isAttic;

wow = selectPreset(wowManual, 0.30, 0.45, 0.75);
flutter = selectPreset(flutterManual, 0.40, 0.30, 0.50);
saturation = selectPreset(saturationManual, 0.35, 0.65, 0.50);
age = selectPreset(ageManual, 0.30, 0.70, 0.85);
dropout = selectPreset(dropoutManual, 0.05, 0.20, 0.55);
hiss = selectPreset(hissManual, 0.20, 0.35, 0.30);
width = selectPreset(widthManual, 0.25, 0.40, 0.60);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : cassetteStereo
with {
  maxDelay = 8192;

  // Wow is slow and lumpy, flutter is fast and fine-grained.
  wowSig(seed) = os.osc(0.45 + seed * 0.07) * 0.6 + no.lfnoise(0.9 + seed * 0.2) * 0.4;
  flutterSig(seed) = os.osc(9.0 + seed * 1.3) * 0.5 + no.lfnoise(25.0 + seed * 5.0) * 0.5;
  transportMs(seed) = 6.0 + wowSig(seed) * wow * 3.5 + flutterSig(seed) * flutter * 0.35;

  // Asymmetric soft saturation with tape compression character.
  tapeSat(x) = (ma.tanh(x * g + bias) - ma.tanh(bias)) / g * (1.0 + saturation * 0.8)
  with {
    g = 1.0 + saturation * 4.0;
    bias = saturation * 0.15;
  };

  wornTone = fi.lowpass(2, 16000.0 - age * 12500.0) : fi.highpass(1, 35.0 + age * 110.0)
    : fi.peak_eq_cq(1.5 + age * 2.5, 90.0, 1.0)
    : fi.peak_eq_cq(0.0 - age * 3.0, 3200.0, 0.8);

  // Dropouts: random oxide flakes briefly duck and dull the signal.
  flake = (no.lfnoise(2.0 + dropout * 6.0) * 0.5 + 0.5) > (1.0 - dropout * 0.35);
  dropGain = 1.0 - flake * (0.55 + dropout * 0.35) : si.smooth(ba.tau2pole(0.012));

  hissSig(seed) = no.noises(2, seed) : fi.highpass(1, 1500.0) : fi.lowpass(1, 9000.0) : *(hiss * hiss * 0.02);

  deck(seed, x) = x : tapeSat
    : de.fdelay3(maxDelay, transportMs(seed) * 0.001 * ma.SR)
    : wornTone
    : *(dropGain)
    : +(hissSig(seed))
    : fi.dcblocker;

  cassetteStereo(inL, inR) = outL, outR
  with {
    // Azimuth error: the channels drift apart in time and treble.
    wetL = deck(0, inL);
    wetR = inR : de.fdelay(256, width * 0.0006 * ma.SR) : deck(1) : fi.lowpass(1, 18000.0 - width * 8000.0);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
