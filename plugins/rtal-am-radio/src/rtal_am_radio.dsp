import("stdfaust.lib");

declare name "rtal-am-radio";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Old radio and telephone voice: band-limited speaker, tube grit, tuning drift, static and crackle.";

presetMode = nentry("am-radio/[0]Factory Preset [style:menu{'Manual':0;'Kitchen Radio':1;'Telephone':2;'Distant Station':3}]", 0, 0, 3, 1);
bandManual = hslider("am-radio/[1]Band [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("am-radio/[2]Bandwidth [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
gritManual = hslider("am-radio/[3]Grit [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
driftManual = hslider("am-radio/[4]Tuning Drift [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
staticManual = hslider("am-radio/[5]Static [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
crackleManual = hslider("am-radio/[6]Crackle [style:knob]", 0.10, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("am-radio/[7]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("am-radio/[8]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isKitchen = (presetMode >= 0.5) * (presetMode < 1.5);
isPhone = (presetMode >= 1.5) * (presetMode < 2.5);
isDistant = presetMode >= 2.5;

selectPreset(manual, kitchen, phone, distant) =
  manual * isManual +
  kitchen * isKitchen +
  phone * isPhone +
  distant * isDistant;

band = selectPreset(bandManual, 0.45, 0.62, 0.50);
width = selectPreset(widthManual, 0.55, 0.25, 0.35);
grit = selectPreset(gritManual, 0.35, 0.55, 0.45);
drift = selectPreset(driftManual, 0.10, 0.0, 0.60);
staticLevel = selectPreset(staticManual, 0.10, 0.05, 0.40);
crackle = selectPreset(crackleManual, 0.10, 0.0, 0.30);
level = selectPreset(levelManual, 0.50, 0.50, 0.50);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : radioStereo
with {
  centerHz = 600.0 * pow(4.0, band);
  octaves = 0.8 + width * 2.6;
  lowEdge = centerHz / pow(2.0, octaves * 0.5);
  highEdge = min(ma.SR * 0.45, centerHz * pow(2.0, octaves * 0.5));

  // Tuning drift: a slowly wandering, fading signal like a station slipping off frequency.
  fadeSig = 1.0 - drift * (0.5 + 0.5 * no.lfnoise(0.4)) * 0.7;
  wander = 1.0 + no.lfnoise(0.25) * drift * 0.25;

  speaker = fi.highpass(2, lowEdge * wander) : fi.highpass(1, lowEdge)
    : fi.lowpass(2, highEdge * wander) : fi.lowpass(1, highEdge)
    : fi.peak_eq_cq(4.0, centerHz, 1.2);

  tube(x) = ma.tanh(x * g + 0.1 * grit) - ma.tanh(0.1 * grit) : /(sqrt(g))
  with {
    g = 1.0 + grit * grit * 20.0;
  };

  hiss = no.noise : fi.highpass(1, 800.0) : *(staticLevel * staticLevel * 0.08 * (1.5 - fadeSig));
  // Crackle: sparse random impulses through a short resonant ping.
  pop = no.noises(2, 1) : >(1.0 - crackle * 0.0015) : *(no.noises(2, 0)) : fi.resonbp(2400.0, 2.0, 0.5) : *(crackle * 0.8);

  radioStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    wet = mono : tube : speaker : *(fadeSig) : +(hiss) : +(pop) : *(0.4 + level * level * 2.0) : fi.dcblocker;
    outL = inL * (1.0 - mix) + wet * mix;
    outR = inR * (1.0 - mix) + wet * mix;
  };
};
