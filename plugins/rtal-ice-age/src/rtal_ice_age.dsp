import("stdfaust.lib");

declare name "rtal-ice-age";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Infinite-sustain freeze pad: captures each new chord into a frozen tank and crossfades between layers.";
// Sustain at maximum holds the captured pad forever by design.
declare rtal_smoke "allow-sustain";

presetMode = nentry("ice-age/[0]Factory Preset [style:menu{'Manual':0;'Chord Halo':1;'Drone Bed':2;'Shoegaze Wall':3}]", 0, 0, 3, 1);
modeManual = nentry("ice-age/[1]Capture [style:menu{'Auto (each chord)':0;'Hold Switch':1}]", 0, 0, 1, 1);
hold = checkbox("ice-age/[2]Hold");
sensManual = hslider("ice-age/[3]Sensitivity [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
captureManual = hslider("ice-age/[4]Capture Time [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
fadeManual = hslider("ice-age/[5]Fade [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
sustainManual = hslider("ice-age/[6]Sustain [style:knob]", 0.90, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("ice-age/[7]Tone [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("ice-age/[8]Pad Level [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
dryManual = hslider("ice-age/[9]Dry [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isHalo = (presetMode >= 0.5) * (presetMode < 1.5);
isDrone = (presetMode >= 1.5) * (presetMode < 2.5);
isWall = presetMode >= 2.5;

selectPreset(manual, halo, drone, wall) =
  manual * isManual +
  halo * isHalo +
  drone * isDrone +
  wall * isWall;

mode = selectPreset(modeManual, 0, 0, 0);
sens = selectPreset(sensManual, 0.55, 0.40, 0.65);
capture = selectPreset(captureManual, 0.35, 0.60, 0.50);
fade = selectPreset(fadeManual, 0.40, 0.85, 0.65);
sustain = selectPreset(sustainManual, 0.92, 1.00, 0.97);
tone = selectPreset(toneManual, 0.60, 0.40, 0.75);
level = selectPreset(levelManual, 0.50, 0.55, 0.70);
dry = selectPreset(dryManual, 1.0, 1.0, 0.90);

process = _,_ : iceStereo
with {
  maxLine = 16384;
  captureSamples = (0.06 + capture * 0.5) * ma.SR;
  fadeSec = 0.15 + fade * fade * 4.0;
  refractory = 0.25 * ma.SR;

  // Counts samples since the last accepted trigger; triggers inside the
  // refractory window are ignored so one strum makes one capture.
  sinceTrigger(raw) = step ~ _
  with {
    step(c) = ba.if(raw * (c > refractory), 0.0, min(c + 1.0, 100000000.0));
  };

  toggle(trig) = step ~ _
  with {
    step(prev) = ba.if(trig, 1.0 - prev, prev);
  };

  // Lossless four-line FDN: an orthogonal Hadamard mix with allpass diffusion in
  // each line, so feedback 1.0 holds the captured sound indefinitely.
  hadamard(a, b, c, d) = (a + b + c + d) * 0.5, (a - b + c - d) * 0.5, (a + b - c - d) * 0.5, (a - b - c + d) * 0.5;
  lineMs = (41.3, 53.9, 67.1, 79.7);
  diffuseN = (113, 157, 211, 263);
  dampHz = 2500.0 + tone * tone * 14000.0;

  tank(gIn, gFb, x) = (inject : par(i, 4, lineDelay(i))) ~ (hadamard : par(i, 4, *(gFb)))
  with {
    inject = par(i, 4, +(x * gIn * (1.0 - 2.0 * (i % 2))));
    lineDelay(i) = fi.allpass_comb(512, ba.take(i + 1, diffuseN), 0.55)
      : de.delay(maxLine, int(ba.take(i + 1, lineMs) * 0.001 * ma.SR) - ba.take(i + 1, diffuseN))
      : fi.lowpass(1, dampHz);
  };

  iceStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    fastEnv = mono : abs : an.amp_follower_ar(0.0005, 0.03);
    slowEnv = mono : abs : an.amp_follower_ar(0.04, 0.4);
    threshold = 0.002 + (1.0 - sens) * 0.05;
    onset = (fastEnv > slowEnv * 1.8 + threshold);
    holdOn = hold > 0.5;
    autoMode = mode < 0.5;
    raw = ba.if(autoMode, onset > onset', holdOn > holdOn');

    count = sinceTrigger(raw);
    trig = count == 0.0;
    which = toggle(trig);
    capturing = count < captureSamples;
    engaged = ba.if(autoMode, 1.0, holdOn);

    // Per-loop gains: sustain 1.0 is a true infinite hold.
    loopSec = 0.06;
    holdG = ba.if(sustain > 0.995, 1.0, pow(0.001, loopSec / (2.0 + sustain * sustain * 60.0)));
    releaseG = pow(0.001, loopSec / fadeSec);
    smoothG = si.smooth(ba.tau2pole(0.01));

    active(k) = (which == k) * engaged;
    gIn(k) = active(k) * capturing : si.smooth(ba.tau2pole(0.004)) : *(0.35);
    gFb(k) = ba.if(active(k), holdG, releaseG) : smoothG;
    gOut(k) = active(k) : si.smooth(ba.tau2pole(fadeSec * 0.3));

    tankA = tank(gIn(0), gFb(0), mono);
    tankB = tank(gIn(1), gFb(1), mono);
    padL = (tankA : _, !, _, !) :> *(1.0);
    padR = (tankA : !, _, !, _) :> *(1.0);
    padLB = (tankB : _, !, _, !) :> *(1.0);
    padRB = (tankB : !, _, !, _) :> *(1.0);

    padOutL = (padL * gOut(0) + padLB * gOut(1)) : fi.highpass(1, 90.0) : *(level * 1.2);
    padOutR = (padR * gOut(0) + padRB * gOut(1)) : fi.highpass(1, 90.0) : *(level * 1.2);
    outL = inL * dry + padOutL;
    outR = inR * dry + padOutR;
  };
};
