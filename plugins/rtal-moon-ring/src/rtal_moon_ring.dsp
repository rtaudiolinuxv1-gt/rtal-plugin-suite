import("stdfaust.lib");

declare name "rtal-moon-ring";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Ring modulator with a pitch-tracked carrier that stays musical, plus fixed and swept modes.";

presetMode = nentry("moon-ring/[0]Factory Preset [style:menu{'Manual':0;'Harmonic Bell':1;'Dalek Radio':2;'Orbit Sweep':3}]", 0, 0, 3, 1);
modeManual = nentry("moon-ring/[1]Carrier [style:menu{'Tracked':0;'Fixed':1}]", 0, 0, 1, 1);
ratioManual = nentry("moon-ring/[2]Ratio [style:menu{'1/2':0;'1':1;'3/2':2;'2':3;'5/2':4;'3':5;'Golden':6}]", 2, 0, 6, 1);
freqManual = hslider("moon-ring/[3]Frequency [style:knob]", 0.40, 0.0, 1.0, 0.001) : si.smoo;
shapeManual = hslider("moon-ring/[4]Shape [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
sweepManual = hslider("moon-ring/[5]Sweep Depth [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
rateManual = hslider("moon-ring/[6]Sweep Rate [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("moon-ring/[7]Tone [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("moon-ring/[8]Mix [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBell = (presetMode >= 0.5) * (presetMode < 1.5);
isDalek = (presetMode >= 1.5) * (presetMode < 2.5);
isOrbit = presetMode >= 2.5;

selectPreset(manual, bell, dalek, orbit) =
  manual * isManual +
  bell * isBell +
  dalek * isDalek +
  orbit * isOrbit;

mode = selectPreset(modeManual, 0, 1, 1);
ratioSel = int(selectPreset(ratioManual, 3, 2, 2));
freqKnob = selectPreset(freqManual, 0.40, 0.25, 0.45);
shape = selectPreset(shapeManual, 0.0, 0.55, 0.20);
sweep = selectPreset(sweepManual, 0.0, 0.10, 0.80);
rate = selectPreset(rateManual, 0.30, 0.60, 0.25);
tone = selectPreset(toneManual, 0.80, 0.45, 0.65);
mix = selectPreset(mixManual, 0.55, 0.85, 0.70);

process = _,_ : ringStereo
with {
  ratio = ba.selectn(7, ratioSel, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 1.618034);
  fixedHz = 20.0 * pow(150.0, freqKnob);
  wrap(x) = x - floor(x);

  // Carrier shape: sine through to a soft square.
  carrierWave(p) = ma.tanh(s * k) / ma.tanh(k)
  with {
    s = sin(2.0 * ma.PI * p);
    k = 0.3 + shape * 7.0;
  };

  ringStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    env = mono : an.amp_follower_ar(0.002, 0.1);
    trackedHz = mono : fi.lowpass(2, 1400.0) : an.pitchTracker(2, 0.025) : max(50.0) : min(1500.0)
      : ba.sAndH(env > 0.004) : si.smooth(ba.tau2pole(0.02));

    lfoHz = 0.03 * pow(200.0, rate);
    lfo = sin(2.0 * ma.PI * ((+(lfoHz / ma.SR) : wrap) ~ _));
    baseHz = ba.if(mode < 0.5, trackedHz * ratio, fixedHz);
    carrierHz = baseHz * pow(2.0, lfo * sweep * 2.0) : min(ma.SR * 0.45);
    phaseL = (+(carrierHz / ma.SR) : wrap) ~ _;
    // Right carrier runs a quarter cycle ahead for stereo movement.
    phaseR = wrap(phaseL + 0.25);

    post = fi.lowpass(2, 1500.0 + tone * tone * 14000.0) : fi.dcblocker;
    wetL = inL * carrierWave(phaseL) : post : *(1.3);
    wetR = inR * carrierWave(phaseR) : post : *(1.3);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
