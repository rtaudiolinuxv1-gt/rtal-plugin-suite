import("stdfaust.lib");

declare name "rtal-cloud-bank";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "One-knob ambient machine: modulated echoes into a shimmering diffuse tank, with a freeze switch.";
// Freeze holds the tank indefinitely by design.
declare rtal_smoke "allow-sustain";

presetMode = nentry("cloud-bank/[0]Factory Preset [style:menu{'Manual':0;'Morning Haze':1;'Night Cathedral':2;'Shimmer Storm':3}]", 0, 0, 3, 1);
atmosphereManual = hslider("cloud-bank/[1]Atmosphere [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
shimmerManual = hslider("cloud-bank/[2]Shimmer [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
motionManual = hslider("cloud-bank/[3]Motion [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("cloud-bank/[4]Tone [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
freeze = checkbox("cloud-bank/[5]Freeze");
mixManual = hslider("cloud-bank/[6]Mix [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isHaze = (presetMode >= 0.5) * (presetMode < 1.5);
isNight = (presetMode >= 1.5) * (presetMode < 2.5);
isStorm = presetMode >= 2.5;

selectPreset(manual, haze, night, storm) =
  manual * isManual +
  haze * isHaze +
  night * isNight +
  storm * isStorm;

atmosphere = selectPreset(atmosphereManual, 0.40, 0.85, 0.70);
shimmer = selectPreset(shimmerManual, 0.15, 0.10, 0.75);
motion = selectPreset(motionManual, 0.35, 0.30, 0.60);
tone = selectPreset(toneManual, 0.65, 0.35, 0.70);
mix = selectPreset(mixManual, 0.35, 0.45, 0.50);

process = _,_ : cloudStereo
with {
  // Atmosphere drives everything at once: echo time and feedback, tank size and decay.
  echoSec = 0.18 + atmosphere * 0.5;
  echoFb = 0.25 + atmosphere * 0.45;
  tankT60 = 1.5 + atmosphere * atmosphere * 14.0;
  frozen = freeze > 0.5;

  wobble(seed) = (os.osc(0.21 + seed * 0.07) * 0.6 + no.lfnoise(0.6 + seed * 0.3) * 0.4) * motion * 0.004 * ma.SR;
  echo(seed, x) = (+(x) : de.fdelay3(131072, echoSec * ma.SR * (1.0 + seed * 0.27) + wobble(seed)))
    ~ (*(echoFb) : fi.lowpass(1, 3000.0 + tone * 8000.0) : fi.highpass(1, 150.0));

  // Four-line lossless tank (Hadamard), feedback 1.0 when frozen.
  hadamard(a, b, c, d) = (a + b + c + d) * 0.5, (a - b + c - d) * 0.5, (a + b - c - d) * 0.5, (a - b - c + d) * 0.5;
  lineMs = (47.3, 61.1, 71.9, 89.3);
  lineSamples(i) = ba.take(i + 1, lineMs) * (0.7 + atmosphere * 0.8) * 0.001 * ma.SR;
  lineGain(i) = ba.if(frozen, 1.0, pow(0.001, (lineSamples(i) / ma.SR) / tankT60));
  tankLine(i) = fi.allpass_comb(1024, ba.take(i + 1, (149, 211, 263, 337)), 0.6)
    : de.fdelay3(16384, lineSamples(i) + wobble(i + 2) * 0.3)
    : fi.lowpass(1, ba.if(frozen, 20000.0, 2000.0 + tone * tone * 14000.0))
    : *(lineGain(i));
  // Shimmer: an octave-up copy of the tank re-enters the input (muted while frozen).
  octave = ef.transpose(4096, 1024, 12.0) : fi.highpass(1, 300.0) : *(shimmer * 0.35 * (1 - frozen));
  tank(l, r) = (inject : par(i, 4, tankLine(i))) ~ (hadamard <: par(i, 4, _), (si.bus(4) :> octave) : routeBack)
  with {
    inputGain = 0.3 * (1 - frozen);
    inject = par(i, 4, +(ba.if(i % 2, r, l) * inputGain));
    // Adds the shimmer signal onto each of the four feedback paths.
    routeBack(a, b, c, d, s) = a + s, b - s, c + s, d - s;
  };

  cloudStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    echoL = mono : echo(0);
    echoR = mono : echo(1);
    // DC would otherwise pile up in the near-lossless tank.
    wet = (inL * 0.5 + echoL * 0.6 : fi.dcblocker), (inR * 0.5 + echoR * 0.6 : fi.dcblocker) : tank;
    wetL = wet : (_, !, _, !) :> *(0.6);
    wetR = wet : (!, _, !, _) :> *(0.6);
    outL = inL * (1.0 - mix * 0.5) + (wetL + echoL * 0.25) * mix;
    outR = inR * (1.0 - mix * 0.5) + (wetR + echoR * 0.25) * mix;
  };
};
