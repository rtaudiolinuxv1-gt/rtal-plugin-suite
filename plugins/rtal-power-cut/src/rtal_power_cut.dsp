import("stdfaust.lib");

declare name "rtal-power-cut";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Tape stop and spin-up: flick the switch and the deck grinds to a halt, release it and the motor winds back up.";

presetMode = nentry("power-cut/[0]Factory Preset [style:menu{'Manual':0;'Turntable Brake':1;'Slow Death':2;'Quick Glitch':3}]", 0, 0, 3, 1);
stop = checkbox("power-cut/[1]Stop");
stopTimeManual = hslider("power-cut/[2]Stop Time [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
startTimeManual = hslider("power-cut/[3]Start Time [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
curveManual = hslider("power-cut/[4]Curve [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("power-cut/[5]Darken [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("power-cut/[6]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBrake = (presetMode >= 0.5) * (presetMode < 1.5);
isDeath = (presetMode >= 1.5) * (presetMode < 2.5);
isGlitch = presetMode >= 2.5;

selectPreset(manual, brake, death, glitch) =
  manual * isManual +
  brake * isBrake +
  death * isDeath +
  glitch * isGlitch;

stopTime = selectPreset(stopTimeManual, 0.30, 0.85, 0.10);
startTime = selectPreset(startTimeManual, 0.20, 0.60, 0.08);
curve = selectPreset(curveManual, 0.30, 0.70, 0.50);
tone = selectPreset(toneManual, 0.60, 0.80, 0.40);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : powerStereo
with {
  maxDelay = 524288;
  stopSec = 0.05 + stopTime * stopTime * 4.0;
  startSec = 0.03 + startTime * startTime * 2.5;

  // Brake amount ramps linearly toward the switch position at separate rates.
  // (Tracked as brake rather than speed so the zero-initialised state is "running".)
  brake = step ~ _
  with {
    target = stop > 0.5;
    step(prev) = ba.if(target > prev, min(target, prev + 1.0 / (stopSec * ma.SR)),
                                      max(target, prev - 1.0 / (startSec * ma.SR)));
  };
  speedRamp = 1.0 - brake;
  // Curve bends the ramp: low values brake late and hard, high values sag early.
  speed = pow(speedRamp, 0.4 + curve * 2.2);

  // The tape head is used while stopping, stopped or spinning up; afterwards the
  // output crossfades back to live input and the tape position resets.
  onTape = (stop > 0.5) | (speedRamp < 0.999);
  tapeGain = onTape : si.smooth(ba.tau2pole(0.012));
  lag = step ~ _
  with {
    step(prev) = ba.if(tapeGain < 0.0005, 0.0, min(float(maxDelay - 8), prev + 1.0 - speed));
  };

  tapeVoice(x) = x : de.fdelay3(maxDelay, lag)
    // Playback level and bandwidth fall with tape speed.
    : fi.lowpass(2, 150.0 + 17000.0 * pow(speed, 0.5 + tone * 1.5))
    : *(sqrt(speed))
    : fi.dcblocker;

  powerStereo(inL, inR) = outL, outR
  with {
    wetL = inL * (1.0 - tapeGain) + tapeVoice(inL) * tapeGain;
    wetR = inR * (1.0 - tapeGain) + tapeVoice(inR) * tapeGain;
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
