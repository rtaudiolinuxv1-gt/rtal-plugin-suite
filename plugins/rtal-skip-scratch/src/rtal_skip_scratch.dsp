import("stdfaust.lib");

declare name "rtal-skip-scratch";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Skipping CD glitch: random jumps back in time, reversed fragments and returns to live, with click-free crossfades.";

presetMode = nentry("skip-scratch/[0]Factory Preset [style:menu{'Manual':0;'Scratched Disc':1;'Broken Discman':2;'Reverse Flicker':3}]", 0, 0, 3, 1);
rateManual = hslider("skip-scratch/[1]Skip Rate [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
rangeManual = hslider("skip-scratch/[2]Jump Range [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
returnManual = hslider("skip-scratch/[3]Return Chance [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
reverseManual = hslider("skip-scratch/[4]Reverse Chance [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
fadeManual = hslider("skip-scratch/[5]Crossfade [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("skip-scratch/[6]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isScratched = (presetMode >= 0.5) * (presetMode < 1.5);
isBroken = (presetMode >= 1.5) * (presetMode < 2.5);
isFlicker = presetMode >= 2.5;

selectPreset(manual, scratched, broken, flicker) =
  manual * isManual +
  scratched * isScratched +
  broken * isBroken +
  flicker * isFlicker;

rate = selectPreset(rateManual, 0.25, 0.65, 0.45);
range = selectPreset(rangeManual, 0.30, 0.55, 0.40);
returnChance = selectPreset(returnManual, 0.60, 0.35, 0.50);
reverseChance = selectPreset(reverseManual, 0.05, 0.20, 0.80);
fade = selectPreset(fadeManual, 0.20, 0.10, 0.35);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : skipStereo
with {
  maxDelay = 131072;
  wrap(x) = x - floor(x);

  // Decision clock: on each tick an event happens with probability set by Skip Rate.
  tickHz = 2.0 + rate * 14.0;
  tickPhase = (+(tickHz / ma.SR) : wrap) ~ _;
  tick = tickPhase < tickPhase';
  rnd(k) = no.noises(4, k) : ba.sAndH(tick) : *(0.5) : +(0.5);
  event = tick * (rnd(0) < 0.15 + rate * 0.5);

  // Two heads alternate: each event loads the idle head with a new jump and crossfades to it.
  toggle(trig) = step ~ _
  with {
    step(prev) = ba.if(trig, 1.0 - prev, prev);
  };
  active = toggle(event);

  maxJump = (0.03 + range * range * 0.9) * ma.SR;
  goesLive = rnd(1) < returnChance;
  plays = ba.if(goesLive, 0.0, 8.0 + rnd(2) * maxJump);
  backwards = (rnd(3) < reverseChance) * (1.0 - goesLive);

  // Each head latches its own jump; a reversed head's delay grows at twice real time.
  headDelay(k) = step ~ (_, _) : _, !
  with {
    load = event * (active == k);
    step(d, rev) = ba.if(load, plays, min(float(maxDelay - 8), d + 2.0 * rev)), ba.if(load, backwards, rev);
  };
  fadeSec = 0.002 + fade * fade * 0.03;
  gainB = active : si.smooth(ba.tau2pole(fadeSec));

  skipVoice(x) = (x : de.fdelay(maxDelay, headDelay(0))) * (1.0 - gainB) + (x : de.fdelay(maxDelay, headDelay(1))) * gainB;

  skipStereo(inL, inR) = outL, outR
  with {
    outL = inL * (1.0 - mix) + skipVoice(inL) * mix;
    outR = inR * (1.0 - mix) + skipVoice(inR) * mix;
  };
};
