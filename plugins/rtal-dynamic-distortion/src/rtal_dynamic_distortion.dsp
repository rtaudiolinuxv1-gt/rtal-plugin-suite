import("stdfaust.lib");

declare name "rtal-dynamic-distortion";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Gesture-aware dynamic guitar distortion.";

presetMode = nentry("dynamic-distortion/[0]Factory Preset [style:menu{'Manual':0;'Touch Grind':1;'Needle Bias':2;'Collapsed Stack':3}]", 0, 0, 3, 1);
driveManual = hslider("dynamic-distortion/[1]Drive [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
touchManual = hslider("dynamic-distortion/[2]Touch [style:knob]", 0.58, 0.0, 1.0, 0.01) : si.smoo;
focusManual = hslider("dynamic-distortion/[3]Focus [style:knob]", 0.44, 0.0, 1.0, 0.01) : si.smoo;
biasManual = hslider("dynamic-distortion/[4]Bias [style:knob]", 0.46, 0.0, 1.0, 0.01) : si.smoo;
gateManual = hslider("dynamic-distortion/[5]Gate [style:knob]", 0.14, 0.0, 1.0, 0.01) : si.smoo;
outputManual = hslider("dynamic-distortion/[6]Output [style:knob]", 0.48, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("dynamic-distortion/[7]Mix [style:knob]", 0.92, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isTouchGrind = (presetMode >= 0.5) * (presetMode < 1.5);
isNeedle = (presetMode >= 1.5) * (presetMode < 2.5);
isCollapsed = presetMode >= 2.5;

selectPreset(manual, touchGrind, needle, collapsed) =
  manual * isManual +
  touchGrind * isTouchGrind +
  needle * isNeedle +
  collapsed * isCollapsed;

drive = selectPreset(driveManual, 0.42, 0.58, 0.82);
touch = selectPreset(touchManual, 0.74, 0.62, 0.46);
focus = selectPreset(focusManual, 0.34, 0.72, 0.40);
bias = selectPreset(biasManual, 0.40, 0.64, 0.70);
gate = selectPreset(gateManual, 0.10, 0.18, 0.28);
output = selectPreset(outputManual, 0.50, 0.46, 0.40);
mix = selectPreset(mixManual, 0.88, 0.94, 1.0);

process = _,_ : distortStereo
with {
  distortStereo(inL, inR) = outL, outR
  with {
    mono = ((inL + inR) * 0.5) : fi.highpass(1, 55.0);
    env = mono : an.amp_follower_ar(0.002, 0.12) : min(1.0);
    gateMask = max(0.0, min(1.0, (env - gate * 0.12) * 22.0));
    attack = max(0.0, env - env') : *(10.0) : min(1.0);
    dynamicDrive = 1.5 + drive * 10.0 + env * touch * 8.0 + attack * 2.0;
    biasShift = (bias - 0.5) * (0.18 + env * 0.24);
    focusHz = 600.0 + focus * 3200.0 + env * 600.0;

    preL = inL : fi.highpass(1, 45.0) : fi.lowpass(1, 8000.0);
    preR = inR : fi.highpass(1, 45.0) : fi.lowpass(1, 8000.0);

    toneL = fi.resonbp(focusHz, 2.0 + focus * 8.0, 1.0, preL);
    toneR = fi.resonbp(focusHz, 2.0 + focus * 8.0, 1.0, preR);
    biteL = preL : fi.highpass(1, 1400.0 + focus * 2600.0) : *(attack * (0.4 + touch * 1.1));
    biteR = preR : fi.highpass(1, 1400.0 + focus * 2600.0) : *(attack * (0.4 + touch * 1.1));

    wetL = saturate(preL * (1.0 - focus * 0.35) + toneL * focus * 0.55 + biteL, dynamicDrive, biasShift) * gateMask;
    wetR = saturate(preR * (1.0 - focus * 0.35) + toneR * focus * 0.55 + biteR, dynamicDrive, -biasShift) * gateMask;

    brokenL = wetL : fi.resonbp(180.0 + focus * 600.0, 1.6 + drive * 3.5, 1.0) : *(0.08 + drive * 0.22);
    brokenR = wetR : fi.resonbp(210.0 + focus * 700.0, 1.6 + drive * 3.5, 1.0) : *(0.08 + drive * 0.22);

    leveledL = (wetL + brokenL) * (0.4 + output * 1.4);
    leveledR = (wetR + brokenR) * (0.4 + output * 1.4);

    outL = fi.lowpass(1, 9000.0, inL * (1.0 - mix) + leveledL * mix) : ma.tanh;
    outR = fi.lowpass(1, 9000.0, inR * (1.0 - mix) + leveledR * mix) : ma.tanh;

    saturate(x, amount, offset) = ((x * amount) + offset) : ma.tanh : *(1.0 / ma.tanh(amount + abs(offset) + 1.0));
  };
};
