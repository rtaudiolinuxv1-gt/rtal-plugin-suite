import("stdfaust.lib");

declare name "rtal-pick-tamer";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Two-band dynamic EQ: cuts harsh pick click and boomy low notes only when they jump out, leaving the rest alone.";

presetMode = nentry("pick-tamer/[0]Factory Preset [style:menu{'Manual':0;'Acoustic Piezo':1;'Bright Strat':2;'Boomy Hollowbody':3}]", 0, 0, 3, 1);
pickFreqManual = hslider("pick-tamer/[1]Pick Freq [unit:Hz]", 3200, 1500, 8000, 1) : si.smoo;
pickThreshManual = hslider("pick-tamer/[2]Pick Threshold [unit:dB]", -30, -60, 0, 0.1) : si.smoo;
pickCutManual = hslider("pick-tamer/[3]Pick Max Cut [unit:dB]", 9, 0, 18, 0.1) : si.smoo;
boomFreqManual = hslider("pick-tamer/[4]Boom Freq [unit:Hz]", 160, 70, 400, 1) : si.smoo;
boomThreshManual = hslider("pick-tamer/[5]Boom Threshold [unit:dB]", -24, -60, 0, 0.1) : si.smoo;
boomCutManual = hslider("pick-tamer/[6]Boom Max Cut [unit:dB]", 6, 0, 18, 0.1) : si.smoo;
speedManual = hslider("pick-tamer/[7]Speed [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
pickMeter = hbargraph("pick-tamer/[8]Pick Cut [unit:dB]", 0, 18);
boomMeter = hbargraph("pick-tamer/[9]Boom Cut [unit:dB]", 0, 18);

isManual = presetMode < 0.5;
isPiezo = (presetMode >= 0.5) * (presetMode < 1.5);
isStrat = (presetMode >= 1.5) * (presetMode < 2.5);
isHollow = presetMode >= 2.5;

selectPreset(manual, piezo, strat, hollow) =
  manual * isManual +
  piezo * isPiezo +
  strat * isStrat +
  hollow * isHollow;

pickFreq = selectPreset(pickFreqManual, 2800.0, 3800.0, 3000.0);
pickThresh = selectPreset(pickThreshManual, -34.0, -30.0, -28.0);
pickCut = selectPreset(pickCutManual, 10.0, 8.0, 6.0);
boomFreq = selectPreset(boomFreqManual, 180.0, 140.0, 120.0);
boomThresh = selectPreset(boomThreshManual, -28.0, -20.0, -30.0);
boomCut = selectPreset(boomCutManual, 6.0, 3.0, 10.0);
speed = selectPreset(speedManual, 0.75, 0.70, 0.45);

process = _,_ : tamerStereo
with {
  attackSec = 0.0002 + (1.0 - speed) * 0.004;
  releaseSec = 0.03 + (1.0 - speed) * 0.25;

  // Gain reduction for one band: how far its level rises above threshold, capped.
  bandCut(keyBand, threshDb, maxCut) = keyBand : abs : an.amp_follower_ar(attackSec, releaseSec)
    : max(0.000001) : ba.linear2db : -(threshDb) : *(0.7) : max(0.0) : min(maxCut);

  tamerStereo(inL, inR) = outL, outR
  with {
    key = max(abs(inL), abs(inR)) * ba.if(abs(inL) > abs(inR), ma.signum(inL), ma.signum(inR));
    pickKey = key : fi.bandpass(1, pickFreq * 0.7, pickFreq * 1.4);
    boomKey = key : fi.bandpass(1, boomFreq * 0.7, boomFreq * 1.4);
    pickGr = bandCut(pickKey, pickThresh, pickCut) : pickMeter;
    boomGr = bandCut(boomKey, boomThresh, boomCut) : boomMeter;
    eq = fi.peak_eq_cq(0.0 - pickGr, pickFreq, 1.2) : fi.peak_eq_cq(0.0 - boomGr, boomFreq, 1.0);
    outL = inL : eq;
    outR = inR : eq;
  };
};
