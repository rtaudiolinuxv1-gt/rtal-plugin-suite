import("stdfaust.lib");

declare name "rtal-leslie-weather";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Rotary speaker with separate horn and drum inertia, Doppler, tube drive and stereo mics.";

presetMode = nentry("leslie-weather/[0]Factory Preset [style:menu{'Manual':0;'Sunday Chorale':1;'Whirlwind':2;'Cracked Cabinet':3}]", 0, 0, 3, 1);
speedManual = nentry("leslie-weather/[1]Speed [style:menu{'Brake':0;'Chorale':1;'Tremolo':2}]", 1, 0, 2, 1);
rampManual = hslider("leslie-weather/[2]Ramp [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
hornManual = hslider("leslie-weather/[3]Horn Balance [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
dopplerManual = hslider("leslie-weather/[4]Doppler [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
driveManual = hslider("leslie-weather/[5]Drive [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
micsManual = hslider("leslie-weather/[6]Mic Spread [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("leslie-weather/[7]Mix [style:knob]", 0.85, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isChorale = (presetMode >= 0.5) * (presetMode < 1.5);
isWhirl = (presetMode >= 1.5) * (presetMode < 2.5);
isCracked = presetMode >= 2.5;

selectPreset(manual, chorale, whirl, cracked) =
  manual * isManual +
  chorale * isChorale +
  whirl * isWhirl +
  cracked * isCracked;

speed = selectPreset(speedManual, 1, 2, 2);
ramp = selectPreset(rampManual, 0.50, 0.35, 0.60);
horn = selectPreset(hornManual, 0.55, 0.62, 0.50);
doppler = selectPreset(dopplerManual, 0.55, 0.75, 0.65);
drive = selectPreset(driveManual, 0.15, 0.30, 0.82);
mics = selectPreset(micsManual, 0.75, 0.85, 0.55);
mix = selectPreset(mixManual, 0.85, 0.90, 1.00);

process = _,_ : rotaryStereo
with {
  maxDelay = 4096;

  isBrake = speed < 0.5;
  isFast = speed > 1.5;
  hornTarget = ba.if(isBrake, 0.0, ba.if(isFast, 6.8, 0.82));
  drumTarget = ba.if(isBrake, 0.0, ba.if(isFast, 5.9, 0.68));

  // The light horn spins up quickly; the heavy drum lags far behind.
  rampScale = 0.3 + ramp * 1.7;
  hornHz = hornTarget : si.smooth(ba.tau2pole(0.45 * rampScale));
  drumHz = drumTarget : si.smooth(ba.tau2pole(2.6 * rampScale));

  wrap(x) = x - floor(x);
  rotor(f) = (+(f / ma.SR) : wrap) ~ _;
  hornPhase = rotor(hornHz);
  drumPhase = rotor(drumHz);

  preamp(x) = ma.tanh(x * g) / ma.tanh(g)
  with {
    g = 0.6 + drive * 5.0;
  };

  // One rotor seen from a mic at the given angle (fraction of a turn).
  rotorVoice(x, phase, angle, dopplerMs, amDepth, shadeHz) = out
  with {
    c = cos(2.0 * ma.PI * (phase + angle));
    s = sin(2.0 * ma.PI * (phase + angle));
    d = (1.5 + dopplerMs * doppler * s) * 0.001 * ma.SR;
    moving = x : de.fdelay3(maxDelay, d);
    facing = 0.5 + 0.5 * c;
    shaded = moving : fi.lowpass(1, shadeHz);
    out = (moving * facing + shaded * (1.0 - facing)) * (1.0 - amDepth * (1.0 - facing));
  };

  rotaryStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5 : preamp;
    lo = mono : fi.lowpassLR4(800.0);
    hi = mono : fi.highpassLR4(800.0);

    angle = 0.25 * mics;
    hornL = rotorVoice(hi, hornPhase, -angle, 0.45, 0.55, 2400.0);
    hornR = rotorVoice(hi, hornPhase, angle, 0.45, 0.55, 2400.0);
    drumL = rotorVoice(lo, drumPhase, -angle, 0.18, 0.35, 450.0);
    drumR = rotorVoice(lo, drumPhase, angle, 0.18, 0.35, 450.0);

    hornGain = 0.3 + horn * 0.9;
    drumGain = 1.2 - horn * 0.9;
    cabinet = fi.peak_eq_cq(2.0, 1800.0, 1.2) : fi.lowpass(2, 7500.0);
    wetL = (hornL * hornGain + drumL * drumGain) : cabinet;
    wetR = (hornR * hornGain + drumR * drumGain) : cabinet;

    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
