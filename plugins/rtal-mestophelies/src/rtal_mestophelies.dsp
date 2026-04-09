import("stdfaust.lib");

declare name "rtal-mestophelies";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Chord ghost afterimage for guitar.";

presetMode = nentry("mestophelies/[0]Factory Preset [style:menu{'Manual':0;'Phantom Chord':1;'Ashen Hall':2;'Witch Echo':3}]", 0, 0, 3, 1);
shadowManual = hslider("mestophelies/[1]Shadow [style:knob]", 0.46, 0.0, 1.0, 0.01) : si.smoo;
smearManual = hslider("mestophelies/[2]Smear [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
driftManual = hslider("mestophelies/[3]Drift [style:knob]", 0.32, 0.0, 1.0, 0.01) : si.smoo;
tensionManual = hslider("mestophelies/[4]Tension [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
tailManual = hslider("mestophelies/[5]Tail [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("mestophelies/[6]Width [style:knob]", 0.68, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("mestophelies/[7]Mix [style:knob]", 0.34, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isPhantom = (presetMode >= 0.5) * (presetMode < 1.5);
isAshen = (presetMode >= 1.5) * (presetMode < 2.5);
isWitch = presetMode >= 2.5;

selectPreset(manual, phantom, ashen, witch) =
  manual * isManual +
  phantom * isPhantom +
  ashen * isAshen +
  witch * isWitch;

shadow = selectPreset(shadowManual, 0.34, 0.56, 0.78);
smear = selectPreset(smearManual, 0.30, 0.54, 0.74);
drift = selectPreset(driftManual, 0.18, 0.46, 0.62);
tension = selectPreset(tensionManual, 0.42, 0.58, 0.76);
tail = selectPreset(tailManual, 0.38, 0.62, 0.82);
width = selectPreset(widthManual, 0.58, 0.74, 0.88);
mix = selectPreset(mixManual, 0.24, 0.38, 0.48);

process = _,_ : ghostStereo
with {
  maxDelay = 32768;

  ghostStereo(inL, inR) = outL, outR
  with {
    mono = ((inL + inR) * 0.5) : fi.highpass(2, 80.0);
    env = mono : an.amp_follower_ar(0.003, 0.22) : min(1.0);
    flux = abs(mono - mono') : an.amp_follower_ar(0.004, 0.16) : min(1.0);
    transient = max(0.0, mono - (mono : fi.lowpass(2, 1100.0 + tension * 2400.0)));
    baseDelay = 120.0 + smear * 1400.0;

    ghostA = tap(mono, baseDelay * 0.85, 0.13);
    ghostB = tap(mono, baseDelay * 1.2, 0.47);
    ghostC = tap(mono, baseDelay * 1.7, 0.71);
    ghostD = tap(mono, baseDelay * 2.3, 0.91);

    wet = (ghostA + ghostB + ghostC + ghostD) * (0.26 + shadow * 0.8);
    hiss = wet : fi.highpass(1, 1400.0 + tension * 1800.0) : de.fdelay5(maxDelay, 35.0 + smear * 160.0) : *(0.12 + drift * 0.25);
    shard = transient : de.fdelay5(maxDelay, 18.0 + smear * 70.0 + drift * 25.0) : fi.resonbp(1100.0 + tension * 2200.0, 4.0 + tension * 6.0, 1.0) : *(0.08 + shadow * 0.22);
    shaped = (wet + hiss + shard) : fi.lowpass(2, 1800.0 + tension * 4200.0) : fi.highpass(1, 120.0);

    panA = os.osc(0.03 + drift * 0.12) * (0.10 + width * 0.25);
    panB = os.osc(0.08 + drift * 0.17) * (0.05 + width * 0.15);
    wetL = shaped * min(1.0, max(0.0, 0.5 + panA + panB)) + hiss * (0.08 + width * 0.10);
    wetR = shaped * min(1.0, max(0.0, 0.5 - panA + panB)) + shard * (0.10 + width * 0.12);

    outL = inL * (1.0 - mix) + wetL * mix : ma.tanh;
    outR = inR * (1.0 - mix) + wetR * mix : ma.tanh;

    tap(x, delayTime, phase) = voice
    with {
      mod = os.osc(0.04 + phase * 0.09) * (4.0 + drift * 26.0);
      delayed = (x * (0.45 + env * 0.3) + transient * (0.12 + smear * 0.34)) : de.fdelay5(maxDelay, delayTime + mod);
      filtered = delayed : fi.resonbp(240.0 + phase * 1200.0 + tension * 1800.0 + flux * 900.0, 1.5 + tension * 6.0, 1.0);
      ghostGain = min(1.0, env * (0.45 + shadow * 0.4) + flux * (0.35 + smear * 0.5));
      smearTail = filtered : de.fdelay5(maxDelay, 18.0 + tail * 80.0 + phase * 17.0) : *(0.18 + tail * 0.42);
      whisper = filtered : fi.highpass(1, 900.0 + tension * 1300.0) : *(0.06 + drift * 0.12);
      voice = filtered * ghostGain + smearTail + whisper;
    };
  };
};
