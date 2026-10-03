import("stdfaust.lib");

declare name "rtal-stereo-sculpt";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Mid/side stereo imager: width, bass mono, side brightness, Haas widening for mono sources and balance.";
// Maximum width and mid level add gain by request.
declare rtal_smoke "allow-gain";

presetMode = nentry("stereo-sculpt/[0]Factory Preset [style:menu{'Manual':0;'Wide Master':1;'Mono-Safe Bass':2;'Haas Double':3}]", 0, 0, 3, 1);
widthManual = hslider("stereo-sculpt/[1]Width [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
bassMonoManual = hslider("stereo-sculpt/[2]Bass Mono [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
sideToneManual = hslider("stereo-sculpt/[3]Side Brightness [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
haasManual = hslider("stereo-sculpt/[4]Haas Widen [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
midManual = hslider("stereo-sculpt/[5]Mid Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
balanceManual = hslider("stereo-sculpt/[6]Balance [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
correlationMeter = hbargraph("stereo-sculpt/[7]Correlation", -1, 1);

isManual = presetMode < 0.5;
isWide = (presetMode >= 0.5) * (presetMode < 1.5);
isBassSafe = (presetMode >= 1.5) * (presetMode < 2.5);
isHaas = presetMode >= 2.5;

selectPreset(manual, wide, bassSafe, haas) =
  manual * isManual +
  wide * isWide +
  bassSafe * isBassSafe +
  haas * isHaas;

width = selectPreset(widthManual, 0.72, 0.60, 0.60);
bassMono = selectPreset(bassMonoManual, 0.30, 0.65, 0.35);
sideTone = selectPreset(sideToneManual, 0.65, 0.50, 0.55);
haas = selectPreset(haasManual, 0.0, 0.0, 0.65);
mid = selectPreset(midManual, 0.50, 0.50, 0.50);
balance = selectPreset(balanceManual, 0.50, 0.50, 0.50);

process = _,_ : sculptStereo
with {
  // Width: 0 is mono, 0.5 unchanged, 1 doubles the side signal.
  sideGain = width * 2.0;
  midGain = ba.db2linear((mid - 0.5) * 12.0);
  monoBelowHz = 40.0 + bassMono * bassMono * 260.0;

  sculptStereo(inL, inR) = outL, outR
  with {
    // Haas widening: a short delayed, filtered copy pushed into the side channel
    // creates width even from a mono guitar.
    haasSide = (inL + inR) * 0.5 : de.fdelay(2048, (8.0 + haas * 14.0) * 0.001 * ma.SR) : fi.highpass(1, 300.0) : *(haas * 0.6);
    m = (inL + inR) * 0.5 * midGain;
    s = (inL - inR) * 0.5 + haasSide;
    // Everything below the bass-mono frequency is removed from the side.
    sShaped = s : fi.highpassLR4(monoBelowHz) : fi.high_shelf((sideTone - 0.5) * 10.0, 3000.0) : *(sideGain);
    l = m + sShaped;
    r = m - sShaped;
    balL = min(1.0, 2.0 - 2.0 * balance);
    balR = min(1.0, 2.0 * balance);
    // Correlation meter: +1 mono, 0 wide/uncorrelated, -1 out of phase.
    num = l * r : fi.lowpass(1, 3.0);
    den = sqrt((l * l : fi.lowpass(1, 3.0)) * (r * r : fi.lowpass(1, 3.0))) + 0.000001;
    corr = num / den : correlationMeter;
    outL = l * balL : attach(_, corr);
    outR = r * balR;
  };
};
