import("stdfaust.lib");

declare name "rtal-violin-swell";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Automatic volume swell: every new note fades in from silence, with an optional ambient echo wash.";
// Fast picking keeps restarting the swell, so the offline test may see very little level.
declare rtal_smoke "allow-quiet";

presetMode = nentry("violin-swell/[0]Factory Preset [style:menu{'Manual':0;'Slow Gear':1;'Pedal Steel':2;'Cathedral Bow':3}]", 0, 0, 3, 1);
sensManual = hslider("violin-swell/[1]Sensitivity [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
riseManual = hslider("violin-swell/[2]Rise [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
curveManual = hslider("violin-swell/[3]Curve [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
ambienceManual = hslider("violin-swell/[4]Ambience [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
spaceManual = hslider("violin-swell/[5]Space [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("violin-swell/[6]Level [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isGear = (presetMode >= 0.5) * (presetMode < 1.5);
isSteel = (presetMode >= 1.5) * (presetMode < 2.5);
isBow = presetMode >= 2.5;

selectPreset(manual, gear, steel, bow) =
  manual * isManual +
  gear * isGear +
  steel * isSteel +
  bow * isBow;

sens = selectPreset(sensManual, 0.55, 0.60, 0.50);
rise = selectPreset(riseManual, 0.35, 0.25, 0.70);
curve = selectPreset(curveManual, 0.60, 0.30, 0.70);
ambience = selectPreset(ambienceManual, 0.10, 0.35, 0.65);
space = selectPreset(spaceManual, 0.30, 0.45, 0.85);
level = selectPreset(levelManual, 0.50, 0.50, 0.50);

process = _,_ : swellStereo
with {
  riseSec = 0.05 + rise * rise * 2.5;
  refractory = 0.12 * ma.SR;
  // The audio runs a few ms behind the detector so the pick itself is muted.
  lookahead = de.delay(1024, int(0.004 * ma.SR));

  sinceTrigger(raw) = step ~ _
  with {
    step(c) = ba.if(raw * (c > refractory), 0.0, min(c + 1.0, 100000000.0));
  };

  // Small ambient wash: two cross-fed diffused echoes.
  ambient(x) = (wash ~ (si.bus(2) :> *(0.5))) : _, _
  with {
    echoMs = 140.0 + space * 360.0;
    fb = 0.35 + space * 0.45;
    tap(ms) = de.fdelay(65536, ms * 0.001 * ma.SR);
    smear = fi.allpass_comb(2048, 397, 0.6) : fi.allpass_comb(2048, 743, 0.6);
    wash(prev) = l, r
    with {
      feed = x + prev * fb : fi.lowpass(1, 5200.0) : fi.highpass(1, 140.0);
      l = feed : smear : tap(echoMs);
      r = feed : smear : tap(echoMs * 1.37);
    };
  };

  swellStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    fastEnv = mono : abs : an.amp_follower_ar(0.0005, 0.03);
    slowEnv = mono : abs : an.amp_follower_ar(0.03, 0.3);
    threshold = 0.002 + (1.0 - sens) * 0.04;
    onset = fastEnv > slowEnv * 1.6 + threshold;
    count = sinceTrigger(onset > onset');

    // Curve: 0 is a straight fade, 1 is a slow-start bowed swell.
    progress = min(1.0, count / (riseSec * ma.SR));
    shapeExp = 1.0 + curve * 2.5;
    swellGain = pow(progress, shapeExp) : si.smooth(ba.tau2pole(0.002));

    swelledL = inL : lookahead : *(swellGain);
    swelledR = inR : lookahead : *(swellGain);
    wash = (swelledL + swelledR) * 0.5 : ambient;
    out = 0.3 + level * 1.4;
    outL = (swelledL + (wash : _, !) * ambience * 0.8) * out;
    outR = (swelledR + (wash : !, _) * ambience * 0.8) * out;
  };
};
