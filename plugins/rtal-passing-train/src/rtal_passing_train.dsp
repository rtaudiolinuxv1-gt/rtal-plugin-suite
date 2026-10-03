import("stdfaust.lib");

declare name "rtal-passing-train";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Doppler fly-by: your guitar races past the listener along a track, with true Doppler pitch, distance and air absorption.";

presetMode = nentry("passing-train/[0]Factory Preset [style:menu{'Manual':0;'Express Train':1;'Race Car':2;'Lazy Swing':3}]", 0, 0, 3, 1);
speedManual = hslider("passing-train/[1]Speed [unit:km/h]", 90, 10, 300, 1) : si.smoo;
distanceManual = hslider("passing-train/[2]Distance [unit:m]", 6, 1, 40, 0.1) : si.smoo;
trackManual = hslider("passing-train/[3]Track Length [unit:m]", 60, 10, 200, 1) : si.smoo;
widthManual = hslider("passing-train/[4]Width [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
airManual = hslider("passing-train/[5]Air Absorption [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("passing-train/[6]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isTrain = (presetMode >= 0.5) * (presetMode < 1.5);
isCar = (presetMode >= 1.5) * (presetMode < 2.5);
isSwing = presetMode >= 2.5;

selectPreset(manual, train, car, swing) =
  manual * isManual +
  train * isTrain +
  car * isCar +
  swing * isSwing;

speedKmh = selectPreset(speedManual, 120.0, 260.0, 25.0);
distance = selectPreset(distanceManual, 8.0, 4.0, 2.0);
track = selectPreset(trackManual, 120.0, 150.0, 12.0);
width = selectPreset(widthManual, 0.85, 0.90, 0.70);
air = selectPreset(airManual, 0.60, 0.50, 0.20);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : passStereo
with {
  maxDelay = 65536;
  c = 343.0;
  halfTrack = track * 0.5;
  // The source swings along the track on a smooth (sinusoidal) path, so its speed
  // peaks as it passes the listener at the closest approach.
  pathHz = (speedKmh / 3.6) / (ma.PI * halfTrack);
  wrap(x) = x - floor(x);
  phase = (+(pathHz / ma.SR) : wrap) ~ _;
  x = halfTrack * sin(2.0 * ma.PI * phase);
  r = sqrt(x * x + distance * distance);

  // Propagation delay r / c gives the true Doppler shift as r changes.
  delaySamples = min(float(maxDelay - 8), r / c * ma.SR) : si.smooth(ba.tau2pole(0.001));
  // Distance attenuation (normalised to the closest approach), softened from pure
  // inverse distance so the far ends of the track stay audible; plus air absorption.
  level = pow(distance / r, 0.7) * 1.4;
  airHz = 18000.0 / (1.0 + air * r * 0.08);
  azimuth = x / r;

  passStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    moving = mono : de.fdelay3(maxDelay, delaySamples) : fi.lowpass(1, airHz) : *(level);
    panR = 0.5 + 0.5 * azimuth * width;
    outL = inL * (1.0 - mix) + moving * sqrt(1.0 - panR) * 1.2 * mix;
    outR = inR * (1.0 - mix) + moving * sqrt(panR) * 1.2 * mix;
  };
};
