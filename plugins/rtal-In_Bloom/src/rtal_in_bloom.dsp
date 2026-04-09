import("stdfaust.lib");

declare name "rtal-In_Bloom";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Resonant guitar bloom and sympathetic string cloud.";

presetMode = nentry("in-bloom/[0]Factory Preset [style:menu{'Manual':0;'Petal Cloud':1;'Sympathetic Glass':2;'Cathedral Seeds':3}]", 0, 0, 3, 1);
bloomManual = hslider("in-bloom/[1]Bloom [style:knob]", 0.5, 0.0, 1.0, 0.01) : si.smoo;
resonanceManual = hslider("in-bloom/[2]Resonance [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
airManual = hslider("in-bloom/[3]Air [style:knob]", 0.42, 0.0, 1.0, 0.01) : si.smoo;
spreadManual = hslider("in-bloom/[4]Spread [style:knob]", 0.36, 0.0, 1.0, 0.01) : si.smoo;
decayManual = hslider("in-bloom/[5]Decay [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("in-bloom/[6]Width [style:knob]", 0.62, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("in-bloom/[7]Mix [style:knob]", 0.32, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isPetal = (presetMode >= 0.5) * (presetMode < 1.5);
isGlass = (presetMode >= 1.5) * (presetMode < 2.5);
isCathedral = presetMode >= 2.5;

selectPreset(manual, petal, glass, cathedral) =
  manual * isManual +
  petal * isPetal +
  glass * isGlass +
  cathedral * isCathedral;

bloom = selectPreset(bloomManual, 0.38, 0.58, 0.82);
resonance = selectPreset(resonanceManual, 0.42, 0.66, 0.74);
air = selectPreset(airManual, 0.34, 0.62, 0.78);
spread = selectPreset(spreadManual, 0.24, 0.48, 0.72);
decay = selectPreset(decayManual, 0.36, 0.54, 0.82);
width = selectPreset(widthManual, 0.50, 0.68, 0.86);
mix = selectPreset(mixManual, 0.24, 0.34, 0.46);

process = _,_ : bloomStereo
with {
  maxDelay = 16384;

  bloomStereo(inL, inR) = outL, outR
  with {
    mono = ((inL + inR) * 0.5) : fi.highpass(2, 70.0);
    env = mono : an.amp_follower_ar(0.002, 0.22) : min(1.0);
    transient = max(0.0, mono - (mono : fi.lowpass(2, 1000.0 + bloom * 2600.0)));
    pitch = mono : an.pitchTracker(4, 0.06) : max(70.0) : min(1400.0) : si.smooth(ba.tau2pole(0.04));
    bloomDrive = min(1.0, env * (0.55 + bloom * 0.8) + transient * (0.45 + bloom * 0.75) + resonance * 0.2);
    period = min(float(maxDelay - 32), ma.SR / max(70.0, pitch));

    voiceA = bloomVoice(mono, 0.98, 0.18);
    voiceB = bloomVoice(mono, 1.25, 0.43);
    voiceC = bloomVoice(mono, 1.50, 0.71);
    voiceD = bloomVoice(mono, 2.00, 0.91);

    wet = (voiceA + voiceB + voiceC + voiceD) * (0.2 + bloom * 0.72);
    shimmer = wet : fi.highpass(1, 1800.0 + air * 2400.0) : de.fdelay5(maxDelay, 22.0 + air * 70.0) : *(0.15 + air * 0.45);
    spray = wet : de.fdelay5(maxDelay, 33.0 + spread * 110.0 + width * 40.0) : fi.highpass(1, 900.0 + air * 1400.0) : *(0.08 + spread * 0.24);
    shaped = (wet + shimmer + spray) : fi.lowpass(2, 2600.0 + air * 6200.0) : fi.highpass(1, 110.0);

    orbitA = os.osc(0.05 + width * 0.12 + bloomDrive * 0.05) * (0.10 + width * 0.18);
    orbitB = os.osc(0.11 + spread * 0.15) * (0.08 + width * 0.14);

    wetL = shaped * min(1.0, max(0.0, 0.5 + orbitA + orbitB * 0.35))
      + shimmer * (0.08 + width * 0.14);
    wetR = shaped * min(1.0, max(0.0, 0.5 - orbitA + orbitB * 0.35))
      + spray * (0.10 + width * 0.16);

    outL = fi.highpass(1, 20.0, inL * (1.0 - mix) + wetL * mix) : ma.tanh;
    outR = fi.highpass(1, 20.0, inR * (1.0 - mix) + wetR * mix) : ma.tanh;

    bloomVoice(x, ratio, phase) = voiced
    with {
      center = max(120.0, min(5200.0, pitch * (ratio + spread * 0.45)));
      q = 2.5 + resonance * 10.0 + ratio * 0.5;
      delay = period * (0.14 + ratio * 0.07 + spread * 0.05) + phase * 27.0;
      mod = os.osc(0.07 + phase * 0.17) * (1.0 + width * 8.0);
      excited = x * (0.4 + env * 0.35) + transient * (0.22 + bloom * 0.9);
      delayed = excited : de.fdelay5(maxDelay, delay + mod);
      resonated = delayed : fi.resonbp(center, q, 1.0);
      tailed = resonated * bloomDrive : an.amp_follower_ar(0.001, 0.22 + decay * 2.4);
      airy = resonated : fi.highpass(1, center * 0.8) : *(0.08 + air * 0.28);
      echoDust = resonated : de.fdelay5(maxDelay, 9.0 + ratio * 21.0 + spread * 33.0) : *(0.05 + decay * 0.14);
      voiced = tailed + airy + echoDust;
    };
  };
};
