import("stdfaust.lib");

declare name "rtal-green-mile";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Mid-hump overdrive: only the mids and highs are driven into soft diode clipping, keeping lows tight and notes clear.";

presetMode = nentry("green-mile/[0]Factory Preset [style:menu{'Manual':0;'Classic Push':1;'Blues Breaker-ish':2;'Tight Metal Boost':3}]", 0, 0, 3, 1);
driveManual = hslider("green-mile/[1]Drive [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("green-mile/[2]Tone [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("green-mile/[3]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
tightManual = hslider("green-mile/[4]Tight [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
midManual = hslider("green-mile/[5]Mid Push [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
clipManual = nentry("green-mile/[6]Clipping [style:menu{'Symmetric':0;'Asymmetric':1;'Hard':2}]", 0, 0, 2, 1);

isManual = presetMode < 0.5;
isClassic = (presetMode >= 0.5) * (presetMode < 1.5);
isBlues = (presetMode >= 1.5) * (presetMode < 2.5);
isMetal = presetMode >= 2.5;

selectPreset(manual, classic, blues, metal) =
  manual * isManual +
  classic * isClassic +
  blues * isBlues +
  metal * isMetal;

drive = selectPreset(driveManual, 0.45, 0.60, 0.10);
tone = selectPreset(toneManual, 0.55, 0.45, 0.65);
level = selectPreset(levelManual, 0.55, 0.50, 0.70);
tight = selectPreset(tightManual, 0.30, 0.10, 0.75);
mid = selectPreset(midManual, 0.55, 0.30, 0.65);
clip = int(selectPreset(clipManual, 0, 1, 0));

process = _,_ : odStereo
with {
  logCosh(x) = abs(x) + log(1.0 + exp(-2.0 * abs(x))) - log(2.0);
  adaaTanh(x) = ba.if(abs(dx) < 0.0001, ma.tanh(0.5 * (x + x')), (logCosh(x) - logCosh(x')) / dx)
  with {
    dx = x - x';
  };

  // Diode pair in the feedback loop: soft, smooth clipping; asymmetric adds even harmonics.
  clipper(x) = ba.selectn(3, clip,
    adaaTanh(x),
    adaaTanh(x + 0.25) - ma.tanh(0.25),
    max(-0.9, min(0.9, x * 1.15)) : fi.lowpass(1, 9000.0));

  odVoice(x) = out
  with {
    // The op-amp stage only adds gain above ~720 Hz, so bass passes nearly clean.
    pre = x : fi.highpass(1, 30.0 + tight * tight * 300.0);
    highs = pre : fi.highpass(1, 720.0);
    gain = 1.0 + drive * drive * 110.0;
    driven = (pre + highs * (gain - 1.0)) / sqrt(gain) : clipper;
    // Mid Push adds the famous hump; Tone sweeps the treble roll-off.
    hump = fi.peak_eq_cq(mid * 7.0, 720.0, 0.8);
    toneHz = 700.0 * pow(8.0, tone);
    out = driven : hump : fi.lowpass(1, toneHz) : fi.lowpass(1, 7000.0) : fi.dcblocker
      : *(0.15 + level * level * 1.6);
  };

  odStereo(inL, inR) = out, out
  with {
    out = (inL + inR) * 0.5 : odVoice;
  };
};
