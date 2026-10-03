import("stdfaust.lib");

declare name "rtal-lorenz-drift";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Chaotic modulator: a Lorenz attractor steers a resonant filter, pitch wobble and stereo position, never repeating.";

presetMode = nentry("lorenz-drift/[0]Factory Preset [style:menu{'Manual':0;'Butterfly Filter':1;'Unstable Tape':2;'Chaos Orbit':3}]", 0, 0, 3, 1);
speedManual = hslider("lorenz-drift/[1]Speed [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
chaosManual = hslider("lorenz-drift/[2]Chaos [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
filterManual = hslider("lorenz-drift/[3]Filter Depth [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
centerManual = hslider("lorenz-drift/[4]Filter Center [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
resonanceManual = hslider("lorenz-drift/[5]Resonance [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
pitchManual = hslider("lorenz-drift/[6]Pitch Depth [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
panManual = hslider("lorenz-drift/[7]Pan Depth [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("lorenz-drift/[8]Mix [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isButterfly = (presetMode >= 0.5) * (presetMode < 1.5);
isTape = (presetMode >= 1.5) * (presetMode < 2.5);
isOrbit = presetMode >= 2.5;

selectPreset(manual, butterfly, tape, orbit) =
  manual * isManual +
  butterfly * isButterfly +
  tape * isTape +
  orbit * isOrbit;

speed = selectPreset(speedManual, 0.40, 0.25, 0.55);
chaos = selectPreset(chaosManual, 0.85, 0.75, 1.00);
filterDepth = selectPreset(filterManual, 0.75, 0.10, 0.50);
center = selectPreset(centerManual, 0.50, 0.70, 0.55);
resonance = selectPreset(resonanceManual, 0.60, 0.20, 0.45);
pitchDepth = selectPreset(pitchManual, 0.05, 0.60, 0.25);
panDepth = selectPreset(panManual, 0.40, 0.20, 0.90);
mix = selectPreset(mixManual, 0.85, 1.00, 0.85);

process = _,_ : chaosStereo
with {
  // Lorenz system, integrated with small Euler steps at audio rate.
  // Chaos sets rho: low values settle into a spiral, 28 and up is the classic butterfly.
  sigma = 10.0;
  beta = 8.0 / 3.0;
  rho = 14.0 + chaos * 18.0;
  dt = (0.2 + speed * speed * 9.0) / ma.SR;

  // States are stored offset by (1, 1, 1) so the zero-initialised recursion
  // doesn't start on the system's fixed point at the origin.
  lorenz = step ~ (_, _, _)
  with {
    step(sx, sy, sz) = sx + dx * dt, sy + dy * dt, sz + dz * dt
    with {
      x = sx + 1.0;
      y = sy + 1.0;
      z = sz + 1.0;
      dx = sigma * (y - x);
      dy = x * (rho - z) - y;
      dz = x * y - beta * z;
    };
  };
  // Normalise the attractor's typical range to about +/-1.
  mx = lorenz : _, !, ! : +(1.0) : /(20.0) : max(-1.0) : min(1.0);
  my = lorenz : !, _, ! : +(1.0) : /(27.0) : max(-1.0) : min(1.0);
  mz = lorenz : !, !, _ : +(1.0) : -(rho - 1.0) : /(25.0) : max(-1.0) : min(1.0);

  centerHz = 400.0 * pow(10.0, center);
  q = 0.8 + resonance * resonance * 8.0;

  voice(x, panSign) = filtered * gain
  with {
    cutoff = centerHz * pow(2.0, mx * filterDepth * 3.0) : max(60.0) : min(16000.0);
    wobbled = x : de.fdelay3(2048, (3.0 + my * pitchDepth * 2.5) * 0.001 * ma.SR);
    filtered = wobbled : fi.svf.lp(cutoff, q) : /(max(1.0, sqrt(q))) : *(1.5);
    gain = 1.0 + panSign * mz * panDepth * 0.7;
  };

  chaosStereo(inL, inR) = outL, outR
  with {
    outL = inL * (1.0 - mix) + voice(inL, -1.0) * mix;
    outR = inR * (1.0 - mix) + voice(inR, 1.0) * mix;
  };
};
