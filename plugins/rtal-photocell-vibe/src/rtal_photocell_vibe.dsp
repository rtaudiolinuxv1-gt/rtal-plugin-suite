import("stdfaust.lib");

declare name "rtal-photocell-vibe";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Photocell vibe: four staggered phase stages driven by a lagging lamp, for that throbbing chorus/vibrato.";

presetMode = nentry("photocell-vibe/[0]Factory Preset [style:menu{'Manual':0;'Machine Gun Throb':1;'Slow Swirl':2;'Seasick Vibrato':3}]", 0, 0, 3, 1);
modeManual = nentry("photocell-vibe/[1]Mode [style:menu{'Chorus':0;'Vibrato':1}]", 0, 0, 1, 1);
speedManual = hslider("photocell-vibe/[2]Speed [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
intensityManual = hslider("photocell-vibe/[3]Intensity [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
throbManual = hslider("photocell-vibe/[4]Lamp Lag [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
driveManual = hslider("photocell-vibe/[5]Preamp [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
volumeManual = hslider("photocell-vibe/[6]Volume [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isGun = (presetMode >= 0.5) * (presetMode < 1.5);
isSwirl = (presetMode >= 1.5) * (presetMode < 2.5);
isSeasick = presetMode >= 2.5;

selectPreset(manual, gun, swirl, seasick) =
  manual * isManual +
  gun * isGun +
  swirl * isSwirl +
  seasick * isSeasick;

mode = selectPreset(modeManual, 0, 0, 1);
speed = selectPreset(speedManual, 0.35, 0.15, 0.45);
intensity = selectPreset(intensityManual, 0.85, 0.75, 0.80);
throb = selectPreset(throbManual, 0.65, 0.45, 0.50);
drive = selectPreset(driveManual, 0.45, 0.20, 0.30);
volume = selectPreset(volumeManual, 0.50, 0.50, 0.50);

process = _,_ : vibeStereo
with {
  rateHz = 0.6 * pow(20.0, speed);
  wrap(x) = x - floor(x);
  phase = (+(rateHz / ma.SR) : wrap) ~ _;

  // The lamp brightens quickly and dims slowly; the photocells respond to it
  // nonlinearly. This lag and curve make the classic lopsided throb.
  lampDrive = max(0.0, sin(2.0 * ma.PI * phase)) : pow(_, 1.5);
  lamp = lampDrive : step ~ _
  with {
    step(prev, target) = prev + (target - prev) * ba.if(target > prev, up, down);
    up = 1.0 - exp(-1.0 / ((0.004 + throb * 0.01) * ma.SR));
    down = 1.0 - exp(-1.0 / ((0.02 + throb * 0.09) * ma.SR));
  };
  // Photocell resistance falls as light rises, raising each stage's frequency.
  cell = 0.15 + pow(lamp, 0.7) * intensity * 2.4;

  // Four stages with deliberately mismatched capacitors (staggered centre frequencies).
  stageHz = (90.0, 260.0, 600.0, 1700.0);
  allpass(f) = fi.tf1(a, 1.0, a)
  with {
    t = tan(ma.PI * min(f, ma.SR * 0.45) / ma.SR);
    a = (t - 1.0) / (t + 1.0);
  };
  stages = seq(i, 4, allpass(ba.take(i + 1, stageHz) * cell));

  // Unity small-signal gain; Preamp only adds saturation (and a little level).
  preamp(x) = ma.tanh(x * g) / g * (1.0 + drive * 0.3)
  with {
    g = 0.5 + drive * 4.0;
  };

  vibeVoice(x) = out
  with {
    pre = x : preamp;
    shifted = pre : stages;
    // Chorus mixes the shifted signal with the dry; vibrato is the shifted signal alone.
    out = ba.if(mode > 0.5, shifted, (pre + shifted) * 0.5) * (0.4 + volume * 1.2);
  };

  vibeStereo(inL, inR) = vibeVoice(inL), vibeVoice(inR);
};
