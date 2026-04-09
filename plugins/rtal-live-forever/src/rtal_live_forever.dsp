import("stdfaust.lib");

declare name "rtal-live-forever";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Controlled endless-feedback bloom for guitar.";

presetMode = nentry("live-forever/[0]Factory Preset [style:menu{'Manual':0;'Amp Hymn':1;'Held Horizon':2;'Ritual Bloom':3}]", 0, 0, 3, 1);
exciteManual = hslider("live-forever/[1]Excite [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
sustainManual = hslider("live-forever/[2]Sustain [style:knob]", 0.58, 0.0, 1.0, 0.01) : si.smoo;
focusManual = hslider("live-forever/[3]Focus [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
riseManual = hslider("live-forever/[4]Rise [style:knob]", 0.34, 0.0, 1.0, 0.01) : si.smoo;
glowManual = hslider("live-forever/[5]Glow [style:knob]", 0.46, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("live-forever/[6]Width [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("live-forever/[7]Mix [style:knob]", 0.38, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isHymn = (presetMode >= 0.5) * (presetMode < 1.5);
isHorizon = (presetMode >= 1.5) * (presetMode < 2.5);
isRitual = presetMode >= 2.5;

selectPreset(manual, hymn, horizon, ritual) =
  manual * isManual +
  hymn * isHymn +
  horizon * isHorizon +
  ritual * isRitual;

excite = selectPreset(exciteManual, 0.34, 0.56, 0.72);
sustain = selectPreset(sustainManual, 0.48, 0.68, 0.82);
focus = selectPreset(focusManual, 0.58, 0.46, 0.64);
rise = selectPreset(riseManual, 0.24, 0.48, 0.70);
glow = selectPreset(glowManual, 0.34, 0.56, 0.78);
width = selectPreset(widthManual, 0.58, 0.74, 0.88);
mix = selectPreset(mixManual, 0.28, 0.40, 0.52);

process = _,_ : foreverStereo
with {
  maxDelay = 32768;

  foreverStereo(inL, inR) = outL, outR
  with {
    mono = ((inL + inR) * 0.5) : fi.highpass(2, 80.0);
    env = mono : an.amp_follower_ar(0.004, 0.18) : min(1.0);
    pitch = mono : an.pitchTracker(4, 0.08) : max(70.0) : min(1200.0) : si.smooth(ba.tau2pole(0.06));
    period = min(float(maxDelay - 64), ma.SR / max(70.0, pitch));
    transient = max(0.0, mono - (mono : fi.lowpass(2, 900.0 + excite * 2600.0)));
    energy = min(1.0, env * (0.55 + excite * 0.65) + transient * (0.28 + excite * 0.5));

    feedA = feedbackVoice(mono, 0.75, 0.11);
    feedB = feedbackVoice(mono, 1.12, 0.43);
    feedC = feedbackVoice(mono, 1.50, 0.77);

    wet = (feedA + feedB + feedC) * (0.28 + sustain * 0.82);
    overtone = wet : fi.highpass(1, 1200.0 + glow * 2400.0) : de.fdelay5(maxDelay, 16.0 + glow * 55.0) : *(0.14 + glow * 0.34);
    riseEcho = wet : de.fdelay5(maxDelay, 45.0 + rise * 180.0) : fi.resonbp(700.0 + focus * 1400.0, 1.6 + focus * 3.5, 1.0) : *(0.10 + rise * 0.24);
    wetTone = (wet + overtone + riseEcho) : fi.lowpass(2, 1400.0 + glow * 5200.0) : fi.highpass(1, 120.0);

    wetL = wetTone * (0.45 + width * 0.45 + os.osc(0.06) * (0.05 + width * 0.18))
      + overtone * (0.08 + width * 0.12);
    wetR = wetTone * (0.45 + width * 0.45 - os.osc(0.09) * (0.05 + width * 0.18))
      + riseEcho * (0.10 + width * 0.14);

    outL = ma.tanh(inL * (1.0 - mix) + wetL * mix);
    outR = ma.tanh(inR * (1.0 - mix) + wetR * mix);

    feedbackVoice(x, ratio, phase) = voice
    with {
      delay = period * ratio + rise * 240.0 + phase * 41.0;
      delayed = (x * (0.3 + excite * 0.45) + transient * (0.28 + excite * 0.6)) : de.fdelay5(maxDelay, delay);
      center = max(140.0, min(5400.0, pitch * ratio + focus * 1800.0));
      resonated = delayed : fi.resonbp(center, 2.0 + focus * 12.0, 1.0);
      held = resonated * energy : an.amp_follower_ar(0.001, 0.2 + sustain * 2.8);
      bloomTail = resonated : de.fdelay5(maxDelay, 22.0 + rise * 90.0 + phase * 12.0) : *(0.12 + sustain * 0.32);
      singing = resonated : fi.highpass(1, center * 0.9) : *(0.05 + glow * 0.16);
      voice = held + bloomTail + singing;
    };
  };
};
