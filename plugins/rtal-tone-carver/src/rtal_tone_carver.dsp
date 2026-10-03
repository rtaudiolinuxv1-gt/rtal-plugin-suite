import("stdfaust.lib");

declare name "rtal-tone-carver";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Guitar parametric EQ: cuts, shelves and two sweepable mid bands, with guitar-tuned factory curves.";
// Every band at +15 dB plus full output gain is loud by request, not unstable.
declare rtal_smoke "allow-gain";

presetMode = nentry("tone-carver/[0]Factory Preset [style:menu{'Manual':0;'Mid Push Lead':1;'Metal Scoop':2;'Mix Fit':3}]", 0, 0, 3, 1);
hpfManual = hslider("tone-carver/[01]Low Cut [unit:Hz]", 40, 20, 400, 1) : si.smoo;
lowGainManual = hslider("tone-carver/[02]Low Shelf [unit:dB]", 0, -15, 15, 0.1) : si.smoo;
lowFreqManual = hslider("tone-carver/[03]Low Freq [unit:Hz]", 120, 40, 400, 1) : si.smoo;
mid1GainManual = hslider("tone-carver/[04]Mid 1 Gain [unit:dB]", 0, -15, 15, 0.1) : si.smoo;
mid1FreqManual = hslider("tone-carver/[05]Mid 1 Freq [unit:Hz]", 500, 150, 2000, 1) : si.smoo;
mid1QManual = hslider("tone-carver/[06]Mid 1 Q", 1.0, 0.3, 6.0, 0.01) : si.smoo;
mid2GainManual = hslider("tone-carver/[07]Mid 2 Gain [unit:dB]", 0, -15, 15, 0.1) : si.smoo;
mid2FreqManual = hslider("tone-carver/[08]Mid 2 Freq [unit:Hz]", 2500, 800, 8000, 1) : si.smoo;
mid2QManual = hslider("tone-carver/[09]Mid 2 Q", 1.0, 0.3, 6.0, 0.01) : si.smoo;
highGainManual = hslider("tone-carver/[10]High Shelf [unit:dB]", 0, -15, 15, 0.1) : si.smoo;
highFreqManual = hslider("tone-carver/[11]High Freq [unit:Hz]", 5000, 1500, 12000, 1) : si.smoo;
lpfManual = hslider("tone-carver/[12]High Cut [unit:Hz]", 18000, 2000, 20000, 1) : si.smoo;
outputManual = hslider("tone-carver/[13]Output [unit:dB]", 0, -18, 18, 0.1) : si.smoo;

isManual = presetMode < 0.5;
isLead = (presetMode >= 0.5) * (presetMode < 1.5);
isScoop = (presetMode >= 1.5) * (presetMode < 2.5);
isFit = presetMode >= 2.5;

selectPreset(manual, lead, scoop, fit) =
  manual * isManual +
  lead * isLead +
  scoop * isScoop +
  fit * isFit;

hpf = selectPreset(hpfManual, 80.0, 70.0, 110.0);
lowGain = selectPreset(lowGainManual, -1.0, 3.0, -2.0);
lowFreq = selectPreset(lowFreqManual, 120.0, 100.0, 200.0);
mid1Gain = selectPreset(mid1GainManual, 4.5, -7.0, -3.0);
mid1Freq = selectPreset(mid1FreqManual, 750.0, 650.0, 350.0);
mid1Q = selectPreset(mid1QManual, 0.9, 0.8, 1.4);
mid2Gain = selectPreset(mid2GainManual, 2.0, 3.0, 2.5);
mid2Freq = selectPreset(mid2FreqManual, 1800.0, 3200.0, 2500.0);
mid2Q = selectPreset(mid2QManual, 1.2, 1.0, 1.0);
highGain = selectPreset(highGainManual, -2.0, 2.0, -1.0);
highFreq = selectPreset(highFreqManual, 6000.0, 7000.0, 8000.0);
lpf = selectPreset(lpfManual, 9000.0, 12000.0, 10000.0);
outputDb = selectPreset(outputManual, -2.0, 1.0, 0.0);

process = _,_ : eqStereo
with {
  // Constant-Q peaking bands, shelves, and 12 dB/oct cuts at the ends.
  eq = fi.highpass(2, hpf)
    : fi.low_shelf(lowGain, lowFreq)
    : fi.peak_eq_cq(mid1Gain, mid1Freq, mid1Q)
    : fi.peak_eq_cq(mid2Gain, mid2Freq, mid2Q)
    : fi.high_shelf(highGain, highFreq)
    : fi.lowpass(2, lpf)
    : *(ba.db2linear(outputDb));

  eqStereo = eq, eq;
};
