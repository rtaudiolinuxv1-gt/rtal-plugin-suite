import("stdfaust.lib");

declare name "rtal-coral-buzz";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Electric sitar: a buzzing bridge whose bright jawari sweep climbs through the harmonics as each note decays.";

presetMode = nentry("coral-buzz/[0]Factory Preset [style:menu{'Manual':0;'Sixties Sitar':1;'Raga Drone':2;'Buzz Lead':3}]", 0, 0, 3, 1);
buzzManual = hslider("coral-buzz/[1]Buzz [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
jawariManual = hslider("coral-buzz/[2]Jawari [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
sweepManual = hslider("coral-buzz/[3]Sweep Time [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
sustainManual = hslider("coral-buzz/[4]Sustain [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
droneManual = hslider("coral-buzz/[5]Drone Ring [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("coral-buzz/[6]Tone [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("coral-buzz/[7]Mix [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isSixties = (presetMode >= 0.5) * (presetMode < 1.5);
isRaga = (presetMode >= 1.5) * (presetMode < 2.5);
isLead = presetMode >= 2.5;

selectPreset(manual, sixties, raga, lead) =
  manual * isManual +
  sixties * isSixties +
  raga * isRaga +
  lead * isLead;

buzz = selectPreset(buzzManual, 0.55, 0.65, 0.75);
jawari = selectPreset(jawariManual, 0.60, 0.80, 0.55);
sweep = selectPreset(sweepManual, 0.40, 0.65, 0.30);
sustain = selectPreset(sustainManual, 0.35, 0.60, 0.70);
drone = selectPreset(droneManual, 0.20, 0.60, 0.10);
tone = selectPreset(toneManual, 0.55, 0.50, 0.65);
mix = selectPreset(mixManual, 0.80, 0.85, 0.80);

process = _,_ : sitarStereo
with {
  sweepSec = 0.08 + sweep * sweep * 1.2;

  sitarStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5 : fi.highpass(1, 80.0);
    hz = mono : fi.lowpass(2, 1200.0) : an.pitchTracker(2, 0.02) : max(70.0) : min(1200.0)
      : si.smooth(ba.tau2pole(0.01));
    env = mono : an.amp_follower_ar(0.002, 0.25);
    peak = mono : an.amp_follower_ar(0.0005, sweepSec * 2.0);
    // 0 at the pick, rising toward 1 as the note dies away.
    decayed = 1.0 - min(1.0, env / max(peak, 0.0001));

    // Sustain evens out the level so the buzz keeps going.
    held = mono * min(ba.db2linear(18.0 * sustain), 1.0 + sustain * 0.1 / max(env, 0.003));

    // Bridge buzz: the string grazes a curved bridge, a one-sided soft barrier.
    barrier = 0.05 + (1.0 - buzz) * 0.3;
    grazed = held + buzz * (ma.tanh((held - barrier) * 6.0) * 0.5 + 0.5) * held * 1.5;

    // Jawari: a resonant band that sweeps from the 3rd up past the 12th harmonic as the note decays.
    harmonic = 3.0 + decayed * 10.0;
    jawariHz = min(ma.SR * 0.4, hz * harmonic) : si.smooth(ba.tau2pole(0.005));
    q = 4.0 + jawari * 10.0;
    jawariBand = grazed : fi.svf.bp(jawariHz, q) : /(q) : *(jawari * 4.0);
    // Drone ring: a narrow comb at the played pitch gives a sympathetic halo.
    ringPeriod = ma.SR / hz;
    ring = grazed : (+ : de.fdelay3(4096, max(2.0, min(4090.0, ringPeriod * 2.0 - 1.0)))) ~ *(0.92 * drone) : *(drone * 0.4);

    sitar = (grazed + jawariBand + ring) : fi.lowpass(2, 2500.0 + tone * tone * 12000.0) : fi.dcblocker : ma.tanh : *(0.8);
    outL = inL * (1.0 - mix) + sitar * mix;
    outR = inR * (1.0 - mix) + sitar * mix;
  };
};
