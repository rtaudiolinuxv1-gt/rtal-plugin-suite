import("stdfaust.lib");

declare name "rtal-hush-band";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Three-band downward expander: quietly pushes down hiss and hum in each band without chopping your notes like a gate.";

presetMode = nentry("hush-band/[0]Factory Preset [style:menu{'Manual':0;'High Gain Hush':1;'Gentle Clean Up':2;'Hiss Only':3}]", 0, 0, 3, 1);
thresholdManual = hslider("hush-band/[1]Threshold [unit:dB]", -55, -90, -20, 0.1) : si.smoo;
ratioManual = hslider("hush-band/[2]Ratio [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
rangeManual = hslider("hush-band/[3]Range [unit:dB]", -24, -60, 0, 0.1) : si.smoo;
releaseManual = hslider("hush-band/[4]Release [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
hissFocusManual = hslider("hush-band/[5]Hiss Focus [unit:dB]", 6, 0, 24, 0.1) : si.smoo;
lowFocusManual = hslider("hush-band/[6]Hum Focus [unit:dB]", 0, 0, 24, 0.1) : si.smoo;

isManual = presetMode < 0.5;
isHighGain = (presetMode >= 0.5) * (presetMode < 1.5);
isGentle = (presetMode >= 1.5) * (presetMode < 2.5);
isHiss = presetMode >= 2.5;

selectPreset(manual, highGain, gentle, hissOnly) =
  manual * isManual +
  highGain * isHighGain +
  gentle * isGentle +
  hissOnly * isHiss;

thresholdDb = selectPreset(thresholdManual, -45.0, -60.0, -55.0);
ratioKnob = selectPreset(ratioManual, 0.60, 0.25, 0.45);
rangeDb = selectPreset(rangeManual, -40.0, -12.0, -30.0);
release = selectPreset(releaseManual, 0.30, 0.55, 0.40);
hissFocus = selectPreset(hissFocusManual, 8.0, 4.0, 12.0);
lowFocus = selectPreset(lowFocusManual, 4.0, 0.0, -60.0);

process = _,_ : hushStereo
with {
  ratio = 1.2 + ratioKnob * 5.0;
  releaseSec = 0.03 + release * release * 0.6;

  // Below its threshold a band is turned down by (ratio - 1) dB per dB, never past Range.
  expanderGainDb(levelDb, offsetDb) = max(rangeDb, min(0.0, (levelDb - (thresholdDb + offsetDb)) * (ratio - 1.0)));

  ballistics(target) = step ~ _
  with {
    step(prev) = prev + (target - prev) * ba.if(target > prev, aOpen, aClose)
    with {
      aOpen = 1.0 - exp(-1.0 / (0.002 * ma.SR));
      aClose = 1.0 - exp(-1.0 / (releaseSec * ma.SR));
    };
  };

  bandGain(band, offsetDb) = band : abs : an.amp_follower_ar(0.001, 0.05) : max(0.000001) : ba.linear2db
    : expanderGainDb(_, offsetDb) : ballistics : ba.db2linear;

  hushStereo(inL, inR) = outL, outR
  with {
    split(x) = x : fi.lowpassLR4(250.0), (x : fi.highpassLR4(250.0) : fi.lowpassLR4(3000.0)), (x : fi.highpassLR4(3000.0));
    key = max(abs(inL), abs(inR));
    keyBands = key : split;
    lowKey = keyBands : _, !, !;
    midKey = keyBands : !, _, !;
    highKey = keyBands : !, !, _;
    // The hum band gets its own focus; set very low to leave the lows alone.
    gLow = ba.if(lowFocus < -50.0, 1.0, bandGain(lowKey, lowFocus));
    gMid = bandGain(midKey, 0.0);
    gHigh = bandGain(highKey, hissFocus);
    apply(x) = x : split : *(gLow), *(gMid), *(gHigh) :> _;
    outL = apply(inL);
    outR = apply(inR);
  };
};
