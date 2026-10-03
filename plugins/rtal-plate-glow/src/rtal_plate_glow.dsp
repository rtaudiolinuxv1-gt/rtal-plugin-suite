import("stdfaust.lib");

declare name "rtal-plate-glow";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Dattorro plate reverb with pre-delay, input shimmer modulation, ducking and tilt EQ.";

presetMode = nentry("plate-glow/[0]Factory Preset [style:menu{'Manual':0;'Studio Plate':1;'Ducked Vocal Plate':2;'Endless Steel':3}]", 0, 0, 3, 1);
decayManual = hslider("plate-glow/[1]Decay [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
predelayManual = hslider("plate-glow/[2]Pre-Delay [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
diffusionManual = hslider("plate-glow/[3]Diffusion [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
dampingManual = hslider("plate-glow/[4]Damping [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
motionManual = hslider("plate-glow/[5]Motion [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
duckManual = hslider("plate-glow/[6]Duck [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
tiltManual = hslider("plate-glow/[7]Tilt [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("plate-glow/[8]Mix [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isStudio = (presetMode >= 0.5) * (presetMode < 1.5);
isDucked = (presetMode >= 1.5) * (presetMode < 2.5);
isSteel = presetMode >= 2.5;

selectPreset(manual, studio, ducked, steel) =
  manual * isManual +
  studio * isStudio +
  ducked * isDucked +
  steel * isSteel;

decay = selectPreset(decayManual, 0.50, 0.65, 0.92);
predelay = selectPreset(predelayManual, 0.15, 0.40, 0.25);
diffusion = selectPreset(diffusionManual, 0.70, 0.75, 0.85);
damping = selectPreset(dampingManual, 0.35, 0.40, 0.20);
motion = selectPreset(motionManual, 0.20, 0.25, 0.55);
duck = selectPreset(duckManual, 0.0, 0.75, 0.20);
tilt = selectPreset(tiltManual, 0.50, 0.55, 0.65);
mix = selectPreset(mixManual, 0.28, 0.35, 0.45);

process = _,_ : plateStereo
with {
  // Decay rate 0.2 .. 0.97 (the plate never quite freezes).
  decayRate = 0.2 + decay * 0.77;
  inDiff1 = 0.45 + diffusion * 0.4;
  inDiff2 = 0.35 + diffusion * 0.35;
  decDiff1 = 0.45 + diffusion * 0.3;
  decDiff2 = 0.35 + diffusion * 0.25;

  plate = re.dattorro_rev(0, 0.9995 - damping * 0.4, inDiff1, inDiff2, decayRate, decDiff1, decDiff2, damping * 0.7);

  // Tilt EQ around 900 Hz on the wet signal.
  tiltEq = fi.low_shelf((0.5 - tilt) * 10.0, 900.0) : fi.high_shelf((tilt - 0.5) * 10.0, 900.0);

  plateStereo(inL, inR) = outL, outR
  with {
    predelaySamples = (1.0 + predelay * 159.0) * 0.001 * ma.SR;
    // Motion: slow, decorrelated pre-delay wobble gives the static plate some shimmer.
    wobbleL = (os.osc(0.37) * 0.7 + no.lfnoise(1.1) * 0.3) * motion * 0.0015 * ma.SR;
    wobbleR = (os.osc(0.29) * 0.7 + no.lfnoise(0.9) * 0.3) * motion * 0.0015 * ma.SR;
    sendL = inL : fi.highpass(1, 120.0) : de.fdelay(16384, predelaySamples + 80.0 + wobbleL);
    sendR = inR : fi.highpass(1, 120.0) : de.fdelay(16384, predelaySamples + 80.0 + wobbleR);
    wet = sendL, sendR : plate;

    env = (inL + inR) * 0.5 : an.amp_follower_ar(0.01, 0.35) : *(6.0) : min(1.0);
    duckGain = 1.0 - duck * env;
    wetL = (wet : _, !) : tiltEq : *(duckGain);
    wetR = (wet : !, _) : tiltEq : *(duckGain);
    outL = inL * (1.0 - mix * 0.5) + wetL * mix;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix;
  };
};
