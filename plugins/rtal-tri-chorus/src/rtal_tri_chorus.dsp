import("stdfaust.lib");

declare name "rtal-tri-chorus";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Three-voice BBD-style chorus and string ensemble with dual LFOs, vibrato mode and stereo spread.";

presetMode = nentry("tri-chorus/[0]Factory Preset [style:menu{'Manual':0;'Dimension Two':1;'String Machine':2;'Seasick Vibrato':3}]", 0, 0, 3, 1);
modeManual = nentry("tri-chorus/[1]Mode [style:menu{'Chorus':0;'Ensemble':1;'Vibrato':2}]", 0, 0, 2, 1);
rateManual = hslider("tri-chorus/[2]Rate [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
depthManual = hslider("tri-chorus/[3]Depth [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
shimmerManual = hslider("tri-chorus/[4]Shimmer [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
delayManual = hslider("tri-chorus/[5]Delay [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("tri-chorus/[6]Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("tri-chorus/[7]Width [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("tri-chorus/[8]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isDimension = (presetMode >= 0.5) * (presetMode < 1.5);
isStrings = (presetMode >= 1.5) * (presetMode < 2.5);
isSeasick = presetMode >= 2.5;

selectPreset(manual, dimension, strings, seasick) =
  manual * isManual +
  dimension * isDimension +
  strings * isStrings +
  seasick * isSeasick;

mode = int(selectPreset(modeManual, 0, 1, 2));
rate = selectPreset(rateManual, 0.25, 0.45, 0.55);
depth = selectPreset(depthManual, 0.30, 0.55, 0.65);
shimmer = selectPreset(shimmerManual, 0.0, 0.55, 0.10);
delayKnob = selectPreset(delayManual, 0.45, 0.35, 0.25);
tone = selectPreset(toneManual, 0.70, 0.50, 0.60);
width = selectPreset(widthManual, 0.90, 1.00, 0.50);
mix = selectPreset(mixManual, 0.50, 0.55, 1.0);

process = _,_ : chorusStereo
with {
  maxDelay = 4096;
  wrap(x) = x - floor(x);

  slowHz = 0.08 * pow(60.0, rate);
  fastHz = 4.0 + rate * 4.0;
  slowPhase = (+(slowHz / ma.SR) : wrap) ~ _;
  fastPhase = (+(fastHz / ma.SR) : wrap) ~ _;

  baseMs = 3.0 + delayKnob * 17.0;
  isEnsemble = mode == 1;
  isVibrato = mode == 2;
  // Ensemble mode always blends in the fast LFO, like a string machine.
  fastAmount = ba.if(isEnsemble, max(0.35, shimmer), shimmer);

  // Voice v sits 120 degrees from its neighbours on both LFOs.
  voiceDelay(v) = (baseMs + slowMs + fastMs) * 0.001 * ma.SR
  with {
    offset = v / 3.0;
    slowMs = sin(2.0 * ma.PI * wrap(slowPhase + offset)) * depth * (1.0 + baseMs * 0.35);
    fastMs = sin(2.0 * ma.PI * wrap(fastPhase + offset)) * fastAmount * 0.35;
  };

  // BBD bandwidth limit and a touch of companding softness.
  bbd = fi.lowpass(2, 3000.0 + tone * 9000.0) : ma.tanh;

  voice(v, x) = x : de.fdelay3(maxDelay, max(1.0, voiceDelay(v))) : bbd;

  chorusStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    v0 = voice(0, mono);
    v1 = voice(1, mono);
    v2 = voice(2, mono);
    sideL = v0 * (0.5 + width * 0.5) + v1 * 0.5 + v2 * (0.5 - width * 0.5);
    sideR = v0 * (0.5 - width * 0.5) + v1 * 0.5 + v2 * (0.5 + width * 0.5);
    // Vibrato is one voice, fully wet, for pure pitch wobble.
    wetL = ba.if(isVibrato, v0, sideL * 0.85);
    wetR = ba.if(isVibrato, voice(0, inR), sideR * 0.85);
    dryGain = ba.if(isVibrato, 1.0 - mix, 1.0 - mix * 0.5);
    outL = inL * dryGain + wetL * mix;
    outR = inR * dryGain + wetR * mix;
  };
};
