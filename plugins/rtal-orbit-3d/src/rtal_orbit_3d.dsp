import("stdfaust.lib");

declare name "rtal-orbit-3d";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Binaural spatializer for headphones: the guitar orbits your head using interaural time, level and shadow cues.";

presetMode = nentry("orbit-3d/[0]Factory Preset [style:menu{'Manual':0;'Slow Halo':1;'Pendulum Front':2;'Fast Whirl':3}]", 0, 0, 3, 1);
motionManual = nentry("orbit-3d/[1]Motion [style:menu{'Orbit':0;'Pendulum':1;'Static':2}]", 0, 0, 2, 1);
rateManual = hslider("orbit-3d/[2]Rate [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
azimuthManual = hslider("orbit-3d/[3]Azimuth [style:knob]", 0.50, 0.0, 1.0, 0.001) : si.smoo;
spanManual = hslider("orbit-3d/[4]Span [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
depthManual = hslider("orbit-3d/[5]Cue Depth [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
distanceManual = hslider("orbit-3d/[6]Distance [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
roomManual = hslider("orbit-3d/[7]Room [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("orbit-3d/[8]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isHalo = (presetMode >= 0.5) * (presetMode < 1.5);
isPendulum = (presetMode >= 1.5) * (presetMode < 2.5);
isWhirl = presetMode >= 2.5;

selectPreset(manual, halo, pendulum, whirl) =
  manual * isManual +
  halo * isHalo +
  pendulum * isPendulum +
  whirl * isWhirl;

motion = int(selectPreset(motionManual, 0, 1, 0));
rate = selectPreset(rateManual, 0.15, 0.30, 0.70);
azimuthKnob = selectPreset(azimuthManual, 0.50, 0.50, 0.50);
span = selectPreset(spanManual, 1.0, 0.60, 1.0);
depth = selectPreset(depthManual, 0.80, 0.85, 0.90);
distance = selectPreset(distanceManual, 0.40, 0.25, 0.20);
room = selectPreset(roomManual, 0.30, 0.20, 0.15);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : spaceStereo
with {
  maxItd = 0.00066;
  rateHz = 0.03 * pow(100.0, rate);
  wrap(x) = x - floor(x);
  phase = (+(rateHz / ma.SR) : wrap) ~ _;

  // Azimuth in radians: 0 is straight ahead, +pi/2 is the right ear.
  // Azimuth knob centre (0.5) faces forward. Span sets the pendulum swing, and
  // in Orbit mode squeezes the circle so the source stays closer to the middle.
  offset = (azimuthKnob - 0.5) * 2.0 * ma.PI;
  theta = ba.selectn(3, motion,
    offset + 2.0 * ma.PI * phase,
    offset + sin(2.0 * ma.PI * phase) * ma.PI * 0.5 * span,
    offset);
  lateralScale = ba.if(motion == 0, span, 1.0);

  spaceStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    lateral = sin(theta) * lateralScale;
    rear = 0.5 - 0.5 * cos(theta);

    // Interaural time difference: the far ear hears the source later.
    itd = lateral * maxItd * depth * ma.SR;
    delayL = 2.0 + max(0.0, itd);
    delayR = 2.0 + max(0.0, 0.0 - itd);

    // Head shadow: the far ear loses treble; sources behind lose a little more.
    farL = max(0.0, lateral) * depth;
    farR = max(0.0, 0.0 - lateral) * depth;
    shadowHz(far) = 1200.0 * pow(16.0, 1.0 - far) * (1.0 - rear * depth * 0.35);
    // Interaural level difference.
    gainL = 1.0 - farL * 0.45;
    gainR = 1.0 - farR * 0.45;

    // Distance: quieter, with more of a short room around it.
    near = 1.0 / (1.0 + distance * 2.0);
    direct(d, hz, g) = mono : de.fdelay3(256, d) : fi.lowpass(1, hz) : *(g * near * 1.25);
    earL = direct(delayL, shadowHz(farL), gainL);
    earR = direct(delayR, shadowHz(farR), gainR);

    roomSend = mono * room * (0.4 + distance * 0.6);
    reflect(ms, x) = x : de.fdelay(4096, ms * 0.001 * ma.SR);
    roomL = roomSend : fi.lowpass(1, 5000.0) <: reflect(11.3), reflect(23.9), reflect(31.7) :> *(0.3);
    roomR = roomSend : fi.lowpass(1, 5000.0) <: reflect(13.7), reflect(19.1), reflect(37.3) :> *(0.3);

    outL = inL * (1.0 - mix) + (earL + roomL) * mix;
    outR = inR * (1.0 - mix) + (earR + roomR) * mix;
  };
};
