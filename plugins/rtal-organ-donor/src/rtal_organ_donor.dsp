import("stdfaust.lib");

declare name "rtal-organ-donor";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Polyphonic guitar-to-organ: drawbar-style octave and quint stack with key-click percussion, sustain and scanner vibrato.";

presetMode = nentry("organ-donor/[0]Factory Preset [style:menu{'Manual':0;'Gospel Full':1;'Church Flute':2;'Garage Combo':3}]", 0, 0, 3, 1);
subManual = hslider("organ-donor/[1]Sub 16' [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
fundManual = hslider("organ-donor/[2]Fund 8' [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
octaveManual = hslider("organ-donor/[3]Octave 4' [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
quintManual = hslider("organ-donor/[4]Quint 2 2/3' [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
superManual = hslider("organ-donor/[5]Super 2' [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
percManual = hslider("organ-donor/[6]Percussion [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
sustainManual = hslider("organ-donor/[7]Sustain [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
vibratoManual = hslider("organ-donor/[8]Vibrato [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
driveManual = hslider("organ-donor/[9]Drive [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("organ-donor/[10]Mix [style:knob]", 0.85, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isGospel = (presetMode >= 0.5) * (presetMode < 1.5);
isFlute = (presetMode >= 1.5) * (presetMode < 2.5);
isCombo = presetMode >= 2.5;

selectPreset(manual, gospel, flute, combo) =
  manual * isManual +
  gospel * isGospel +
  flute * isFlute +
  combo * isCombo;

sub = selectPreset(subManual, 0.90, 0.60, 0.20);
fund = selectPreset(fundManual, 0.90, 0.70, 0.90);
octave = selectPreset(octaveManual, 0.90, 0.80, 0.70);
quint = selectPreset(quintManual, 0.60, 0.0, 0.50);
super = selectPreset(superManual, 0.50, 0.40, 0.70);
perc = selectPreset(percManual, 0.45, 0.0, 0.25);
sustain = selectPreset(sustainManual, 0.65, 0.80, 0.45);
vibrato = selectPreset(vibratoManual, 0.40, 0.25, 0.65);
drive = selectPreset(driveManual, 0.40, 0.10, 0.60);
mix = selectPreset(mixManual, 0.90, 0.90, 0.85);

process = _,_ : organStereo
with {
  wrap(x) = x - floor(x);

  // Each drawbar is the whole (polyphonic) signal shifted by a fixed interval.
  footage(semis) = ef.transpose(2048, 512, semis);

  organStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5 : fi.highpass(1, 70.0);
    // Soften the pick and even out the decay so notes hold like organ keys.
    env = mono : an.amp_follower_ar(0.01, 0.4);
    levelGain = min(ba.db2linear(24.0 * sustain), 0.12 / max(env, 0.0003));
    held = mono * (1.0 - sustain + sustain * levelGain) : fi.lowpass(2, 3200.0) : ma.tanh;

    // Percussion: a decaying 4' and 2 2/3' blip on each new note.
    fast = mono : abs : an.amp_follower_ar(0.0005, 0.03);
    slow = mono : abs : an.amp_follower_ar(0.03, 0.3);
    onset = fast > slow * 1.7 + 0.003;
    percEnv = (onset > onset') : en.ar(0.001, 0.25);

    stack = held * fund
      + footage(-12.0, held) * sub
      + footage(12.0, held) * (octave + percEnv * perc * 1.5)
      + footage(19.0, held) * (quint + percEnv * perc)
      + footage(24.0, held) * super;
    norm = 1.0 / (1.0 + (sub + fund + octave + quint + super) * 0.35);
    voiced = stack * norm : *(1.0 + drive * 5.0) : ma.tanh : /(1.0 + drive * 1.5);

    // Scanner-style vibrato/chorus: a modulated short delay blended with the dry stack.
    scan = 0.5 + 0.5 * sin(2.0 * ma.PI * ((+(6.8 / ma.SR) : wrap) ~ _));
    scanned = voiced : de.fdelay3(1024, (0.8 + scan * vibrato * 2.2) * 0.001 * ma.SR);
    wetL = voiced * (1.0 - vibrato * 0.5) + scanned * vibrato * 0.5;
    wetR = voiced * (1.0 - vibrato * 0.6) + scanned * vibrato * 0.6;

    tone = fi.lowpass(2, 7000.0) : fi.peak_eq_cq(2.0, 1100.0, 1.0);
    outL = inL * (1.0 - mix) + (wetL : tone) * mix * 1.8;
    outR = inR * (1.0 - mix) + (wetR : tone) * mix * 1.8;
  };
};
