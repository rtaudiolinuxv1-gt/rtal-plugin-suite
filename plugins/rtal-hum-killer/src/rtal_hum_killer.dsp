import("stdfaust.lib");

declare name "rtal-hum-killer";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Mains hum and hiss remover: notches 50/60 Hz and its harmonics, plus a dynamic hiss filter for the quiet bits.";

presetMode = nentry("hum-killer/[0]Factory Preset [style:menu{'Manual':0;'Single Coil 60':1;'Single Coil 50':2;'Noisy Room':3}]", 0, 0, 3, 1);
mainsManual = nentry("hum-killer/[1]Mains [style:menu{'50 Hz':0;'60 Hz':1}]", 1, 0, 1, 1);
harmonicsManual = nentry("hum-killer/[2]Harmonics", 4, 1, 8, 1);
widthManual = hslider("hum-killer/[3]Notch Width [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
depthManual = hslider("hum-killer/[4]Notch Depth [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
hissManual = hslider("hum-killer/[5]Hiss Filter [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
thresholdManual = hslider("hum-killer/[6]Hiss Threshold [unit:dB]", -50, -80, -20, 0.1) : si.smoo;

isManual = presetMode < 0.5;
isSixty = (presetMode >= 0.5) * (presetMode < 1.5);
isFifty = (presetMode >= 1.5) * (presetMode < 2.5);
isRoom = presetMode >= 2.5;

selectPreset(manual, sixty, fifty, room) =
  manual * isManual +
  sixty * isSixty +
  fifty * isFifty +
  room * isRoom;

mains = selectPreset(mainsManual, 1, 0, mainsManual);
harmonics = selectPreset(harmonicsManual, 5, 5, 8);
width = selectPreset(widthManual, 0.25, 0.25, 0.40);
depth = selectPreset(depthManual, 1.0, 1.0, 1.0);
hiss = selectPreset(hissManual, 0.35, 0.35, 0.70);
thresholdDb = selectPreset(thresholdManual, -52.0, -52.0, -45.0);

process = _,_ : cleanStereo
with {
  maxHarmonics = 8;
  baseHz = ba.if(mains > 0.5, 60.0, 50.0);
  // Narrow notches: a few hertz wide on the fundamental, wider up the series.
  notchWidth(k) = (1.5 + width * 8.0) * (1.0 + k * 0.25);
  notch(k) = ba.bypass1(k >= harmonics, fi.notchw(notchWidth(k), baseHz * (k + 1)));
  humChain = seq(k, maxHarmonics, notch(k));

  cleanVoice(env, x) = out
  with {
    notched = x : humChain;
    dehummed = x * (1.0 - depth) + notched * depth;
    // Dynamic hiss filter: when the guitar falls below threshold the top end closes down.
    quiet = (ba.db2linear(thresholdDb) - env) / ba.db2linear(thresholdDb) : max(0.0) : min(1.0)
      : si.smooth(ba.tau2pole(0.08));
    hissHz = 18000.0 * pow(0.08, quiet * hiss);
    out = dehummed : fi.lowpass(2, hissHz);
  };

  cleanStereo(inL, inR) = cleanVoice(env, inL), cleanVoice(env, inR)
  with {
    env = max(abs(inL), abs(inR)) : an.amp_follower_ar(0.002, 0.2);
  };
};
