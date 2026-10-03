import("stdfaust.lib");

declare name "rtal-dub-station";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Dub echo station: throw switch, sweepable loop filter, runaway feedback and a spring tank, all for live dubbing.";
// Feedback above unity is a deliberate dub self-oscillation, bounded by the loop saturator.
declare rtal_smoke "allow-sustain";

presetMode = nentry("dub-station/[0]Factory Preset [style:menu{'Manual':0;'Skank Throw':1;'Siren Runaway':2;'Filter Melt':3}]", 0, 0, 3, 1);
throw = checkbox("dub-station/[1]Throw");
timeManual = hslider("dub-station/[2]Time [style:knob]", 0.45, 0.0, 1.0, 0.01);
feedbackManual = hslider("dub-station/[3]Feedback [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
filterManual = hslider("dub-station/[4]Filter [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
resonanceManual = hslider("dub-station/[5]Resonance [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
sendManual = hslider("dub-station/[6]Send [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
springManual = hslider("dub-station/[7]Spring [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
wobbleManual = hslider("dub-station/[8]Wobble [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("dub-station/[9]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isSkank = (presetMode >= 0.5) * (presetMode < 1.5);
isSiren = (presetMode >= 1.5) * (presetMode < 2.5);
isMelt = presetMode >= 2.5;

selectPreset(manual, skank, siren, melt) =
  manual * isManual +
  skank * isSkank +
  siren * isSiren +
  melt * isMelt;

time = selectPreset(timeManual, 0.50, 0.35, 0.55) : si.smooth(ba.tau2pole(0.3));
feedback = selectPreset(feedbackManual, 0.55, 0.92, 0.70);
filterKnob = selectPreset(filterManual, 0.62, 0.40, 0.25);
resonance = selectPreset(resonanceManual, 0.30, 0.55, 0.70);
send = selectPreset(sendManual, 0.15, 0.50, 0.45);
spring = selectPreset(springManual, 0.30, 0.20, 0.35);
wobble = selectPreset(wobbleManual, 0.15, 0.35, 0.25);
mix = selectPreset(mixManual, 0.55, 0.60, 0.60);

process = _,_ : dubStereo
with {
  maxDelay = 262144;
  delaySec = 0.06 * pow(20.0, time);
  // Feedback knob runs to just past unity: the loop saturator keeps runaway echoes in check.
  loopGain = feedback * 1.08;

  // Filter is bipolar: left of centre a lowpass closes down, right of centre a highpass opens up.
  lpHz = ba.if(filterKnob < 0.5, 300.0 * pow(60.0, filterKnob * 2.0), 18000.0);
  hpHz = ba.if(filterKnob > 0.5, 40.0 * pow(50.0, (filterKnob - 0.5) * 2.0), 40.0);
  q = 0.7 + resonance * resonance * 6.0;
  loopFilter = fi.svf.lp(lpHz, q) : fi.svf.hp(hpHz, q) : /(max(1.0, q * 0.6));

  wobbleMs = (os.osc(0.5) * 0.7 + no.lfnoise(2.0) * 0.3) * wobble * 2.5;

  // Small two-spring tank (dispersive allpass chains in feedback loops).
  stretched(k, a, x) = w * a + w@k
  with {
    w = x : (+ ~ (@(k - 1) : *(0.0 - a)));
  };
  springLine(ms, x) = (+(x) : seq(i, 12, stretched(2, 0.62)) : de.fdelay(8192, ms * 0.001 * ma.SR)) ~ (fi.lowpass(1, 3500.0) : *(0.72));
  tank(x) = x : fi.highpass(1, 200.0) <: springLine(33.0), springLine(41.3) : _, _;

  echo(x) = (+(x) : de.fdelay(maxDelay, min(float(maxDelay - 8), delaySec * ma.SR + wobbleMs * 0.001 * ma.SR)))
    ~ (loopFilter : *(loopGain) : ma.tanh);

  dubStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    // Throw slams the send open for dub throws; it springs back when released.
    sendGain = min(1.0, send + throw * 0.9) : si.smooth(ba.tau2pole(0.01));
    echoes = mono * sendGain : echo;
    springs = echoes : tank;
    wetL = echoes + (springs : _, !) * spring * 0.5;
    wetR = (echoes : de.fdelay(4096, 0.011 * ma.SR)) + (springs : !, _) * spring * 0.5;
    outL = inL * (1.0 - mix * 0.4) + wetL * mix;
    outR = inR * (1.0 - mix * 0.4) + wetR * mix;
  };
};
