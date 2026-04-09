import("stdfaust.lib");

declare name "rtal-crystal-pluck";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Transient prism and crystal pluck enhancer.";

presetMode = nentry("crystal-pluck/[0]Factory Preset [style:menu{'Manual':0;'Glass Nerve':1;'Prism Harp':2;'Frozen Rain':3}]", 0, 0, 3, 1);
pluckManual = hslider("crystal-pluck/[1]Pluck [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
sparkleManual = hslider("crystal-pluck/[2]Sparkle [style:knob]", 0.54, 0.0, 1.0, 0.01) : si.smoo;
glassManual = hslider("crystal-pluck/[3]Glass [style:knob]", 0.46, 0.0, 1.0, 0.01) : si.smoo;
scatterManual = hslider("crystal-pluck/[4]Scatter [style:knob]", 0.34, 0.0, 1.0, 0.01) : si.smoo;
decayManual = hslider("crystal-pluck/[5]Decay [style:knob]", 0.32, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("crystal-pluck/[6]Width [style:knob]", 0.72, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("crystal-pluck/[7]Mix [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isNerve = (presetMode >= 0.5) * (presetMode < 1.5);
isHarp = (presetMode >= 1.5) * (presetMode < 2.5);
isRain = presetMode >= 2.5;

selectPreset(manual, nerve, harp, rain) =
  manual * isManual +
  nerve * isNerve +
  harp * isHarp +
  rain * isRain;

pluck = selectPreset(pluckManual, 0.58, 0.42, 0.72);
sparkle = selectPreset(sparkleManual, 0.62, 0.78, 0.88);
glass = selectPreset(glassManual, 0.54, 0.68, 0.84);
scatter = selectPreset(scatterManual, 0.26, 0.52, 0.72);
decay = selectPreset(decayManual, 0.22, 0.44, 0.70);
width = selectPreset(widthManual, 0.64, 0.76, 0.90);
mix = selectPreset(mixManual, 0.26, 0.34, 0.46);

process = _,_ : prismStereo
with {
  maxDelay = 8192;

  prismStereo(inL, inR) = outL, outR
  with {
    mono = ((inL + inR) * 0.5) : fi.highpass(2, 120.0);
    env = mono : an.amp_follower_ar(0.001, 0.12);
    attack = max(0.0, env - env') : *(18.0) : min(1.0);
    transient = max(0.0, mono - (mono : fi.lowpass(2, 900.0 + pluck * 3200.0)));
    excite = transient * (0.9 + pluck * 2.4 + attack * 1.8);

    pingA = prismTap(excite, 1700.0 + sparkle * 4000.0, 9.0, 13.0);
    pingB = prismTap(excite, 2400.0 + glass * 5200.0, 17.0, 23.0);
    pingC = prismTap(excite, 3100.0 + scatter * 6100.0, 29.0, 37.0);

    wet = (pingA + pingB + pingC) * (0.55 + pluck * 1.1);
    wetL = wet * (0.45 + width * 0.45 + os.osc(0.12) * (0.04 + width * 0.12));
    wetR = wet * (0.45 + width * 0.45 - os.osc(0.19) * (0.04 + width * 0.12));

    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;

    prismTap(x, freq, baseDelay, trailDelay) = voice
    with {
      delayed = x : de.fdelay5(maxDelay, baseDelay + scatter * 24.0);
      crystal = delayed : fi.resonbp(freq, 12.0 + glass * 22.0, 1.0);
      trail = delayed
        : de.fdelay5(maxDelay, trailDelay + decay * 85.0 + scatter * 18.0)
        : fi.resonbp(freq * (1.22 + sparkle * 0.33), 9.0 + glass * 14.0, 1.0);
      voice = (crystal * (1.2 + sparkle * 1.1) + trail * (0.5 + decay * 0.9))
        : fi.highpass(1, 1200.0 + sparkle * 1800.0);
    };
  };
};
