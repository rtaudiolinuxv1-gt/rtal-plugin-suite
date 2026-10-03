import("stdfaust.lib");

declare name "rtal-tweed-glow";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Tweed-style small amp: two triode stages, simple tone control, saggy push-pull power section and a 1x12 speaker.";

presetMode = nentry("tweed-glow/[0]Factory Preset [style:menu{'Manual':0;'Clean Sparkle':1;'Edge of Breakup':2;'Cranked Tweed':3}]", 0, 0, 3, 1);
volumeManual = hslider("tweed-glow/[1]Volume [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("tweed-glow/[2]Tone [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
brightManual = hslider("tweed-glow/[3]Bright Channel [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
sagManual = hslider("tweed-glow/[4]Sag [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
powerManual = hslider("tweed-glow/[5]Power Drive [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
cabManual = hslider("tweed-glow/[6]Speaker [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("tweed-glow/[7]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isClean = (presetMode >= 0.5) * (presetMode < 1.5);
isEdge = (presetMode >= 1.5) * (presetMode < 2.5);
isCranked = presetMode >= 2.5;

selectPreset(manual, clean, edge, cranked) =
  manual * isManual +
  clean * isClean +
  edge * isEdge +
  cranked * isCranked;

volume = selectPreset(volumeManual, 0.25, 0.55, 0.90);
tone = selectPreset(toneManual, 0.65, 0.55, 0.50);
bright = selectPreset(brightManual, 0.55, 0.40, 0.35);
sag = selectPreset(sagManual, 0.25, 0.50, 0.80);
power = selectPreset(powerManual, 0.25, 0.50, 0.85);
cab = selectPreset(cabManual, 1.0, 1.0, 1.0);
level = selectPreset(levelManual, 0.55, 0.50, 0.40);

process = _,_ : ampStereo
with {
  // Triode: asymmetric soft clipping, grid conduction on the positive side.
  triode(gain, bias, x) = (ma.tanh((x * gain + bias) * ba.if(x * gain + bias > 0.0, 1.4, 0.8)) - ma.tanh(bias)) / sqrt(gain);

  ampVoice(x) = out
  with {
    // V1: the bright channel adds a treble-peaking cap; the two channels are blended.
    normal = x : fi.lowpass(1, 6000.0);
    brightCh = x : fi.high_shelf(6.0, 1800.0);
    v1in = normal * (1.0 - bright) + brightCh * bright;
    g1 = 1.5 + volume * volume * 30.0;
    v1 = v1in : triode(g1, 0.15) : fi.highpass(1, 40.0);
    // Tweed tone control: a single treble-cut that also dips the level a little.
    toneHz = 1200.0 * pow(8.0, tone);
    toned = v1 : fi.lowpass(1, toneHz) : *(0.8 + tone * 0.2);
    v2 = toned : triode(3.0 + volume * 6.0, 0.1) : fi.highpass(1, 60.0);

    // Push-pull power section with supply sag: heavy playing pulls the rails down,
    // compressing and softening the attack.
    env = v2 : abs : an.amp_follower_ar(0.01, 0.25);
    rail = 1.0 / (1.0 + sag * env * 3.0);
    pg = 1.0 + power * power * 8.0;
    pushPull = ma.tanh(v2 * pg / rail) * rail / sqrt(pg);
    transformer = pushPull : fi.highpass(1, 70.0) : fi.lowpass(1, 9000.0);

    // 1x12 alnico speaker: low resonance, upper-mid presence, steep top roll-off.
    speaker = fi.highpass(2, 75.0) : fi.peak_eq_cq(3.0, 110.0, 1.5) : fi.peak_eq_cq(4.0, 2400.0, 1.2)
      : fi.lowpass(4, 5200.0);
    voiced = transformer * (1.0 - cab) + (transformer : speaker) * cab;
    out = voiced : *(0.2 + level * level * 1.6);
  };

  ampStereo(inL, inR) = out, out
  with {
    out = (inL + inR) * 0.5 : ampVoice;
  };
};
