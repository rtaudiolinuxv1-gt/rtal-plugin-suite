import("stdfaust.lib");

declare name "rtal-silkcut-choir";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Slide-driven guitar choir smearing effect.";

presetMode = nentry("silkcut-choir/[0]Factory Preset [style:menu{'Manual':0;'Velvet Line':1;'Choir Rail':2;'Neon Psalm':3}]", 0, 0, 3, 1);
voicesManual = hslider("silkcut-choir/[1]Voices [style:knob]", 0.54, 0.0, 1.0, 0.01) : si.smoo;
glideManual = hslider("silkcut-choir/[2]Glide [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
choirManual = hslider("silkcut-choir/[3]Choir [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
silkManual = hslider("silkcut-choir/[4]Silk [style:knob]", 0.42, 0.0, 1.0, 0.01) : si.smoo;
driftManual = hslider("silkcut-choir/[5]Drift [style:knob]", 0.28, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("silkcut-choir/[6]Width [style:knob]", 0.74, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("silkcut-choir/[7]Mix [style:knob]", 0.34, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isVelvet = (presetMode >= 0.5) * (presetMode < 1.5);
isRail = (presetMode >= 1.5) * (presetMode < 2.5);
isPsalm = presetMode >= 2.5;

selectPreset(manual, velvet, rail, psalm) =
  manual * isManual +
  velvet * isVelvet +
  rail * isRail +
  psalm * isPsalm;

voices = selectPreset(voicesManual, 0.42, 0.62, 0.80);
glide = selectPreset(glideManual, 0.58, 0.44, 0.72);
choir = selectPreset(choirManual, 0.40, 0.62, 0.76);
silk = selectPreset(silkManual, 0.58, 0.44, 0.74);
drift = selectPreset(driftManual, 0.18, 0.34, 0.56);
width = selectPreset(widthManual, 0.62, 0.76, 0.90);
mix = selectPreset(mixManual, 0.26, 0.36, 0.48);

process = _,_ : choirStereo
with {
  maxDelay = 16384;

  choirStereo(inL, inR) = outL, outR
  with {
    mono = ((inL + inR) * 0.5) : fi.highpass(2, 90.0);
    pitch = mono : an.pitchTracker(4, 0.06) : max(75.0) : min(1200.0) : si.smooth(ba.tau2pole(0.05 + glide * 0.15));
    period = min(float(maxDelay - 32), ma.SR / max(75.0, pitch));
    env = mono : an.amp_follower_ar(0.003, 0.2) : min(1.0);
    breath = mono : fi.highpass(1, 900.0 + choir * 1500.0) : *(0.08 + silk * 0.22);

    voiceA = choirVoice(mono, 0.96, 0.12);
    voiceB = choirVoice(mono, 1.00, 0.39);
    voiceC = choirVoice(mono, 1.05, 0.63);
    voiceD = choirVoice(mono, 1.12, 0.88);

    wet = (voiceA + voiceB + voiceC + voiceD) * (0.23 + voices * 0.72);
    airy = breath : de.fdelay5(maxDelay, 24.0 + glide * 55.0) : *(0.18 + silk * 0.28);
    silky = (wet + airy) : fi.lowpass(2, 1600.0 + silk * 4200.0) : fi.highpass(1, 120.0);
    wetL = silky * (0.45 + width * 0.45 + os.osc(0.07 + drift * 0.1) * (0.04 + width * 0.14));
    wetR = silky * (0.45 + width * 0.45 - os.osc(0.1 + drift * 0.14) * (0.04 + width * 0.14));

    outL = ma.tanh(inL * (1.0 - mix) + wetL * mix);
    outR = ma.tanh(inR * (1.0 - mix) + wetR * mix);

    choirVoice(x, ratio, phase) = voice
    with {
      delay = period * ratio + drift * 18.0 + phase * 13.0;
      mod = os.osc(0.09 + phase * 0.15) * (1.0 + drift * 9.0);
      delayed = x : de.fdelay5(maxDelay, delay + mod);
      formanted = delayed : fi.resonbp(340.0 + choir * 1200.0 + phase * 600.0, 2.5 + choir * 7.0, 1.0);
      whisper = delayed : fi.highpass(1, 1200.0 + silk * 1800.0) : *(0.05 + silk * 0.18);
      voice = formanted * env + whisper;
    };
  };
};
