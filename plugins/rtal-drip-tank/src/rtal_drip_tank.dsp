import("stdfaust.lib");

declare name "rtal-drip-tank";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Three-spring reverb tank with dispersive chirp, dwell drive and surf drip.";

presetMode = nentry("drip-tank/[0]Factory Preset [style:menu{'Manual':0;'Blackface Tank':1;'Surf Drip':2;'Dub Plate':3}]", 0, 0, 3, 1);
dwellManual = hslider("drip-tank/[1]Dwell [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
decayManual = hslider("drip-tank/[2]Decay [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
dripManual = hslider("drip-tank/[3]Drip [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
tensionManual = hslider("drip-tank/[4]Tension [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("drip-tank/[5]Tone [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("drip-tank/[6]Width [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("drip-tank/[7]Mix [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBlackface = (presetMode >= 0.5) * (presetMode < 1.5);
isSurf = (presetMode >= 1.5) * (presetMode < 2.5);
isDub = presetMode >= 2.5;

selectPreset(manual, blackface, surf, dub) =
  manual * isManual +
  blackface * isBlackface +
  surf * isSurf +
  dub * isDub;

dwell = selectPreset(dwellManual, 0.40, 0.85, 0.60);
decay = selectPreset(decayManual, 0.45, 0.60, 0.85);
drip = selectPreset(dripManual, 0.45, 0.85, 0.65);
tension = selectPreset(tensionManual, 0.50, 0.40, 0.70);
tone = selectPreset(toneManual, 0.55, 0.70, 0.35);
width = selectPreset(widthManual, 0.55, 0.65, 0.85);
mix = selectPreset(mixManual, 0.28, 0.42, 0.40);

process = _,_ : tankStereo
with {
  maxDelay = 16384;
  nStages = 18;

  // Stretched allpass (a + z^-K) / (1 + a z^-K): a cascade of these disperses
  // high frequencies against low ones, which is the spring's chirp.
  stretchedAllpass(k, a, x) = w * a + w@k
  with {
    w = x : (+ ~ (@(k - 1) : *(0.0 - a)));
  };

  dispersion(k) = seq(i, nStages, stretchedAllpass(k, coef))
  with {
    coef = 0.45 + drip * 0.30;
  };

  // Each spring: dispersive chain inside a feedback loop with frequency-dependent loss.
  spring(lengthMs, k, x) = (+(x) : dispersion(k) : de.fdelay(maxDelay, lengthSamples)) ~ loss
  with {
    lengthSamples = lengthMs * (0.8 + tension * 0.45) * 0.001 * ma.SR;
    roundTrip = lengthSamples / ma.SR;
    t60 = 0.6 + decay * decay * 5.5;
    g = pow(0.001, roundTrip / t60);
    loss = fi.lowpass(1, 2600.0 + tone * 4200.0) : fi.highpass(1, 140.0) : *(g);
  };

  // Transducer drive: the dwell control overdrives the tank input like a 12AT7 driver.
  driver(x) = ma.tanh(x * g) * 0.8
  with {
    g = 0.5 + dwell * 3.5;
  };

  tankStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5 : fi.highpass(2, 180.0) : fi.lowpass(2, 4800.0) : driver;
    springA = mono : spring(33.0, 2);
    springB = mono : spring(39.7, 2);
    springC = mono : spring(45.1, 3);
    chirpBand = fi.highpass(1, 250.0) : fi.lowpass(2, 2500.0 + tone * 3500.0);
    wetL = (springA * (0.5 + width * 0.5) + springB * (0.5 - width * 0.5) + springC * 0.6) : chirpBand;
    wetR = (springA * (0.5 - width * 0.5) + springB * (0.5 + width * 0.5) + springC * 0.6) : chirpBand;
    outL = inL * (1.0 - mix * 0.5) + wetL * mix * 0.55;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix * 0.55;
  };
};
