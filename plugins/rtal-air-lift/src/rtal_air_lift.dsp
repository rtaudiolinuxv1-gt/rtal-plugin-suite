import("stdfaust.lib");

declare name "rtal-air-lift";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Harmonic exciter: generates fresh upper harmonics for air and saturated low harmonics for body.";

presetMode = nentry("air-lift/[0]Factory Preset [style:menu{'Manual':0;'Acoustic Sparkle':1;'Dull Pickup Rescue':2;'Fat Bottom':3}]", 0, 0, 3, 1);
airFreqManual = hslider("air-lift/[1]Air Freq [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
airManual = hslider("air-lift/[2]Air [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
harmonicsManual = hslider("air-lift/[3]Harmonics [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
oddEvenManual = hslider("air-lift/[4]Odd-Even [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
bodyFreqManual = hslider("air-lift/[5]Body Freq [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
bodyManual = hslider("air-lift/[6]Body [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
outputManual = hslider("air-lift/[7]Output [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isAcoustic = (presetMode >= 0.5) * (presetMode < 1.5);
isRescue = (presetMode >= 1.5) * (presetMode < 2.5);
isFat = presetMode >= 2.5;

selectPreset(manual, acoustic, rescue, fat) =
  manual * isManual +
  acoustic * isAcoustic +
  rescue * isRescue +
  fat * isFat;

airFreq = selectPreset(airFreqManual, 0.60, 0.35, 0.45);
air = selectPreset(airManual, 0.45, 0.70, 0.20);
harmonics = selectPreset(harmonicsManual, 0.40, 0.65, 0.50);
oddEven = selectPreset(oddEvenManual, 0.70, 0.40, 0.50);
bodyFreq = selectPreset(bodyFreqManual, 0.40, 0.45, 0.35);
body = selectPreset(bodyManual, 0.10, 0.25, 0.70);
output = selectPreset(outputManual, 0.50, 0.50, 0.45);

process = _,_ : exciteStereo
with {
  airHz = 1500.0 * pow(6.0, airFreq);
  bodyHz = 60.0 * pow(4.0, bodyFreq);

  // Odd-Even blends a symmetric clipper (odd harmonics) with a biased,
  // asymmetric one (even harmonics).
  shaper(x) = odd * (1.0 - oddEven) + even * oddEven
  with {
    g = 1.0 + harmonics * harmonics * 18.0;
    odd = ma.tanh(x * g) / sqrt(g);
    even = (ma.tanh(x * g + 0.6) - ma.tanh(0.6)) / sqrt(g);
  };

  exciteVoice(x) = x + airPart + bodyPart
  with {
    // Only the band above Air Freq is excited, and the new harmonics are
    // highpassed again so nothing muddy is added underneath.
    airPart = x : fi.highpass(2, airHz) : shaper : fi.highpass(2, airHz) : fi.dcblocker : *(air);
    bodyPart = x : fi.lowpass(2, bodyHz) : shaper : fi.lowpass(2, bodyHz * 3.0) : fi.dcblocker : *(body);
  };

  exciteStereo(inL, inR) = outL, outR
  with {
    g = ba.db2linear((output - 0.5) * 18.0);
    outL = inL : exciteVoice : *(g);
    outR = inR : exciteVoice : *(g);
  };
};
