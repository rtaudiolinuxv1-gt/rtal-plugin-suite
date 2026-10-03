import("stdfaust.lib");

declare name "rtal-split-drive";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Three-band multiband distortion: tight lows, crunchy mids and fizzy highs driven separately.";

presetMode = nentry("split-drive/[0]Factory Preset [style:menu{'Manual':0;'Tight Metal':1;'Bass-Safe Crunch':2;'Fuzz Top Clean Bottom':3}]", 0, 0, 3, 1);
lowDriveManual = hslider("split-drive/[1]Low Drive [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
midDriveManual = hslider("split-drive/[2]Mid Drive [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
highDriveManual = hslider("split-drive/[3]High Drive [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
lowSplitManual = hslider("split-drive/[4]Low Split [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
highSplitManual = hslider("split-drive/[5]High Split [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
lowLevelManual = hslider("split-drive/[6]Low Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
midLevelManual = hslider("split-drive/[7]Mid Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
highLevelManual = hslider("split-drive/[8]High Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("split-drive/[9]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isMetal = (presetMode >= 0.5) * (presetMode < 1.5);
isBassSafe = (presetMode >= 1.5) * (presetMode < 2.5);
isFuzzTop = presetMode >= 2.5;

selectPreset(manual, metal, bassSafe, fuzzTop) =
  manual * isManual +
  metal * isMetal +
  bassSafe * isBassSafe +
  fuzzTop * isFuzzTop;

lowDrive = selectPreset(lowDriveManual, 0.35, 0.05, 0.0);
midDrive = selectPreset(midDriveManual, 0.85, 0.55, 0.30);
highDrive = selectPreset(highDriveManual, 0.55, 0.35, 0.95);
lowSplit = selectPreset(lowSplitManual, 0.40, 0.45, 0.50);
highSplit = selectPreset(highSplitManual, 0.45, 0.50, 0.35);
lowLevel = selectPreset(lowLevelManual, 0.55, 0.55, 0.60);
midLevel = selectPreset(midLevelManual, 0.55, 0.50, 0.40);
highLevel = selectPreset(highLevelManual, 0.40, 0.45, 0.55);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : splitStereo
with {
  lowHz = 80.0 * pow(5.0, lowSplit);
  highHz = 900.0 * pow(5.0, highSplit);

  // ADAA tanh clipper (as in rtal-velvet-fuzz) so each band clips cleanly.
  logCosh(x) = abs(x) + log(1.0 + exp(-2.0 * abs(x))) - log(2.0);
  adaaTanh(x) = ba.if(abs(dx) < 0.0001, ma.tanh(0.5 * (x + x')), (logCosh(x) - logCosh(x')) / dx)
  with {
    dx = x - x';
  };

  // Drive with level compensation so turning a band's drive up mostly adds grit, not volume.
  clipBand(drive, x) = adaaTanh(x * g) / sqrt(g)
  with {
    g = 1.0 + drive * drive * 60.0;
  };

  bandLevel(k) = 2.0 * k * k;

  driveVoice(x) = low + mid + high
  with {
    lowBand = x : fi.lowpassLR4(lowHz);
    rest = x : fi.highpassLR4(lowHz);
    midBand = rest : fi.lowpassLR4(highHz);
    highBand = rest : fi.highpassLR4(highHz);
    low = lowBand : clipBand(lowDrive) : fi.lowpass(2, lowHz * 2.5) : *(bandLevel(lowLevel));
    mid = midBand : clipBand(midDrive) : fi.lowpass(1, highHz * 2.0) : *(bandLevel(midLevel));
    high = highBand : clipBand(highDrive) : fi.lowpass(2, 9000.0) : *(bandLevel(highLevel));
  };

  splitStereo(inL, inR) = outL, outR
  with {
    wetL = inL : driveVoice;
    wetR = inR : driveVoice;
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
