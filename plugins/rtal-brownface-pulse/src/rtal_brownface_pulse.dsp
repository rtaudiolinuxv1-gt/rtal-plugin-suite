import("stdfaust.lib");

declare name "rtal-brownface-pulse";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Harmonic, classic and panning tremolo with morphing LFO shape and pick-reactive rate.";

presetMode = nentry("brownface-pulse/[0]Factory Preset [style:menu{'Manual':0;'Brownface Harmonic':1;'Surf Chop':2;'Slow Pan Dream':3}]", 0, 0, 3, 1);
modeManual = nentry("brownface-pulse/[1]Mode [style:menu{'Harmonic':0;'Classic':1;'Pan':2}]", 0, 0, 2, 1);
rateManual = hslider("brownface-pulse/[2]Rate [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
depthManual = hslider("brownface-pulse/[3]Depth [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
shapeManual = hslider("brownface-pulse/[4]Shape [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
splitManual = hslider("brownface-pulse/[5]Split [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
pushManual = hslider("brownface-pulse/[6]Pick Push [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
spreadManual = hslider("brownface-pulse/[7]Stereo Phase [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBrown = (presetMode >= 0.5) * (presetMode < 1.5);
isSurf = (presetMode >= 1.5) * (presetMode < 2.5);
isPan = presetMode >= 2.5;

selectPreset(manual, brown, surf, pan) =
  manual * isManual +
  brown * isBrown +
  surf * isSurf +
  pan * isPan;

mode = int(selectPreset(modeManual, 0, 1, 2));
rate = selectPreset(rateManual, 0.42, 0.62, 0.15);
depth = selectPreset(depthManual, 0.75, 0.90, 0.85);
shape = selectPreset(shapeManual, 0.10, 0.80, 0.0);
split = selectPreset(splitManual, 0.40, 0.40, 0.40);
push = selectPreset(pushManual, 0.0, 0.25, 0.0);
spread = selectPreset(spreadManual, 0.0, 0.0, 0.0);

process = _,_ : tremStereo
with {
  wrap(x) = x - floor(x);

  // Sine -> triangle -> rounded square as Shape goes 0 -> 0.5 -> 1.
  lfoShape(p) = ba.if(shape < 0.5, sine * (1.0 - m1) + tri * m1, tri * (1.0 - m2) + square * m2)
  with {
    sine = sin(2.0 * ma.PI * p);
    // Triangle phase-aligned with the sine so the morph stays smooth.
    tri = 1.0 - 4.0 * abs(wrap(p + 0.25) - 0.5);
    square = ma.tanh(sine * 6.0) / ma.tanh(6.0);
    m1 = shape * 2.0;
    m2 = shape * 2.0 - 1.0;
  };

  tremStereo(inL, inR) = outL, outR
  with {
    env = (inL + inR) * 0.5 : an.amp_follower_ar(0.003, 0.25) : *(4.0) : min(1.0);
    // Pick Push speeds the LFO up while you dig in.
    rateHz = 0.6 * pow(25.0, rate) * (1.0 + push * env * 1.5);
    phaseL = (+(rateHz / ma.SR) : wrap) ~ _;
    phaseR = wrap(phaseL + spread * 0.5);
    uniL = 0.5 + 0.5 * lfoShape(phaseL);
    uniR = 0.5 + 0.5 * lfoShape(phaseR);

    splitHz = 250.0 * pow(8.0, split);

    harmonic(x, u) = lo * (1.0 - depth * u) + hi * (1.0 - depth * (1.0 - u))
    with {
      lo = x : fi.lowpassLR4(splitHz);
      hi = x : fi.highpassLR4(splitHz);
    };

    classic(x, u) = x * (1.0 - depth * u);

    // Pan mode: the two sides move in opposition.
    panned(x, u, side) = x * ba.if(side, 1.0 - depth * (1.0 - u), 1.0 - depth * u);

    voice(x, u, side) = ba.selectn(3, mode, harmonic(x, u), classic(x, u), panned(x, u, side));
    makeup = 1.0 + depth * ba.if(mode == 0, 0.5, 0.6);
    outL = voice(inL, uniL, 0) * makeup;
    outR = voice(inR, uniR, 1) * makeup;
  };
};
