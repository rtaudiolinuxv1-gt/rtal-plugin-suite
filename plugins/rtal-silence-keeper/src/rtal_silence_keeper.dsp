import("stdfaust.lib");

declare name "rtal-silence-keeper";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "High-gain noise gate with hysteresis, hold, lookahead, sidechain filtering and a range control.";
// A gate is supposed to mute quiet passages; very high thresholds silence the test signal.
declare rtal_smoke "allow-quiet";

presetMode = nentry("silence-keeper/[0]Factory Preset [style:menu{'Manual':0;'Tight Chug':1;'Gentle Hum Cut':2;'Staccato Chop':3}]", 0, 0, 3, 1);
thresholdManual = hslider("silence-keeper/[1]Threshold [unit:dB]", -50, -90, -10, 0.1) : si.smoo;
hysteresisManual = hslider("silence-keeper/[2]Hysteresis [unit:dB]", 6, 0, 20, 0.1) : si.smoo;
attackManual = hslider("silence-keeper/[3]Attack [style:knob]", 0.10, 0.0, 1.0, 0.01) : si.smoo;
holdManual = hslider("silence-keeper/[4]Hold [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
releaseManual = hslider("silence-keeper/[5]Release [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
rangeManual = hslider("silence-keeper/[6]Range [unit:dB]", -80, -80, 0, 0.1) : si.smoo;
scManual = hslider("silence-keeper/[7]Sidechain Focus [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
gateMeter = hbargraph("silence-keeper/[8]Gate Open", 0, 1);

isManual = presetMode < 0.5;
isChug = (presetMode >= 0.5) * (presetMode < 1.5);
isHum = (presetMode >= 1.5) * (presetMode < 2.5);
isChop = presetMode >= 2.5;

selectPreset(manual, chug, hum, chop) =
  manual * isManual +
  chug * isChug +
  hum * isHum +
  chop * isChop;

thresholdDb = selectPreset(thresholdManual, -42.0, -60.0, -30.0);
hysteresisDb = selectPreset(hysteresisManual, 8.0, 6.0, 3.0);
attack = selectPreset(attackManual, 0.02, 0.20, 0.0);
hold = selectPreset(holdManual, 0.10, 0.50, 0.0);
release = selectPreset(releaseManual, 0.15, 0.60, 0.05);
rangeDb = selectPreset(rangeManual, -80.0, -18.0, -80.0);
sc = selectPreset(scManual, 0.45, 0.20, 0.40);

process = _,_ : gateStereo
with {
  attackSec = 0.0001 + attack * attack * 0.02;
  holdSamples = (hold * hold * 0.4) * ma.SR;
  releaseSec = 0.005 + release * release * 1.0;
  lookahead = de.delay(1024, int(0.0015 * ma.SR));

  // Opens above the threshold, closes only after falling below threshold minus
  // hysteresis and staying there for the hold time.
  gateState(levelDb) = step ~ (_, _) : _, !
  with {
    step(open, held) = newOpen, newHeld
    with {
      above = levelDb > thresholdDb;
      below = levelDb < thresholdDb - hysteresisDb;
      newHeld = ba.if(above, 0.0, held + 1.0);
      newOpen = ba.if(above, 1.0, ba.if(below * (newHeld > holdSamples), 0.0, open));
    };
  };

  ballistics(target) = step ~ _
  with {
    step(prev) = prev + (target - prev) * ba.if(target > prev, aAtt, aRel)
    with {
      aAtt = 1.0 - exp(-1.0 / (attackSec * ma.SR));
      aRel = 1.0 - exp(-1.0 / (releaseSec * ma.SR));
    };
  };

  gateStereo(inL, inR) = outL, outR
  with {
    scLow = 40.0 + sc * sc * 500.0;
    scHigh = 12000.0 - sc * 8000.0;
    key = max(abs(inL), abs(inR)) : fi.highpass(2, scLow) : fi.lowpass(2, scHigh);
    levelDb = key : an.amp_follower_ar(0.0002, 0.02) : max(0.000001) : ba.linear2db;
    openness = levelDb : gateState : ballistics : gateMeter;
    floorGain = ba.db2linear(rangeDb);
    g = floorGain + (1.0 - floorGain) * openness;
    outL = inL : lookahead : *(g);
    outR = inR : lookahead : *(g);
  };
};
