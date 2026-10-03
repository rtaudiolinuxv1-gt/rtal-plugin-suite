import("stdfaust.lib");

declare name "rtal-jet-wash";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Through-zero tape flanger with classic mode, bipolar feedback and LFO or envelope sweep.";

presetMode = nentry("jet-wash/[0]Factory Preset [style:menu{'Manual':0;'Tape Jet':1;'Metal Comb':2;'Pick Swoosh':3}]", 0, 0, 3, 1);
typeManual = nentry("jet-wash/[1]Type [style:menu{'Through-Zero':0;'Classic':1}]", 0, 0, 1, 1);
sourceManual = nentry("jet-wash/[2]Sweep [style:menu{'LFO':0;'Envelope':1}]", 0, 0, 1, 1);
rateManual = hslider("jet-wash/[3]Rate [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
depthManual = hslider("jet-wash/[4]Depth [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
manualManual = hslider("jet-wash/[5]Manual [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
feedbackManual = hslider("jet-wash/[6]Feedback [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
spreadManual = hslider("jet-wash/[7]Spread [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("jet-wash/[8]Mix [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isTape = (presetMode >= 0.5) * (presetMode < 1.5);
isMetal = (presetMode >= 1.5) * (presetMode < 2.5);
isSwoosh = presetMode >= 2.5;

selectPreset(manual, tape, metal, swoosh) =
  manual * isManual +
  tape * isTape +
  metal * isMetal +
  swoosh * isSwoosh;

type = selectPreset(typeManual, 0, 1, 0);
source = selectPreset(sourceManual, 0, 0, 1);
rate = selectPreset(rateManual, 0.18, 0.35, 0.30);
depth = selectPreset(depthManual, 0.90, 0.70, 0.85);
manualPos = selectPreset(manualManual, 0.45, 0.20, 0.40);
feedbackKnob = selectPreset(feedbackManual, 0.55, 0.90, 0.30);
spread = selectPreset(spreadManual, 0.25, 0.50, 0.0);
mix = selectPreset(mixManual, 0.50, 0.50, 0.50);

process = _,_ : flangeStereo
with {
  maxDelay = 2048;
  isThroughZero = type < 0.5;

  rateHz = 0.02 * pow(250.0, rate);
  // Center delay 0.3 ms .. 6 ms.
  centerMs = 0.3 + manualPos * manualPos * 5.7;
  feedback = (feedbackKnob - 0.5) * 1.8;

  wrap(x) = x - floor(x);
  lfoPhase = (+(rateHz / ma.SR) : wrap) ~ _;
  // Triangle sweep, as on tape and BBD flangers.
  tri(p) = 1.0 - 4.0 * abs(wrap(p + 0.25) - 0.5);

  flangeVoice(sweep, x) = out
  with {
    centerSamples = centerMs * 0.001 * ma.SR;
    // Through-zero: the dry path sits at the center delay and the wet head sweeps
    // across it, so the comb collapses to silence and flips polarity mid-sweep.
    dryDelay = ba.if(isThroughZero, centerSamples, 0.0);
    wetDelay = ba.if(isThroughZero,
      centerSamples * (1.0 + sweep * depth),
      centerSamples * (1.05 + depth * (sweep * 0.5 + 0.5) * 4.0));
    wet = x : (+ : de.fdelay3(maxDelay, max(1.0, min(float(maxDelay - 4), wetDelay)))) ~ (*(feedback) : ma.tanh);
    dry = x : de.fdelay3(maxDelay, dryDelay);
    out = (dry * (1.0 - mix) + wet * mix * ba.if(isThroughZero, -1.0, 1.0)) * (1.0 / (1.0 + abs(feedback) * 0.5)) * 1.3;
  };

  flangeStereo(inL, inR) = outL, outR
  with {
    env = (inL + inR) * 0.5 : an.amp_follower_ar(0.002, 0.4) : *(5.0) : min(1.0);
    envSweep = 1.0 - 2.0 * env;
    sweepL = ba.if(source > 0.5, envSweep, tri(lfoPhase));
    sweepR = ba.if(source > 0.5, envSweep, tri(wrap(lfoPhase + spread * 0.5)));
    outL = flangeVoice(sweepL, inL : fi.dcblocker);
    outR = flangeVoice(sweepR, inR : fi.dcblocker);
  };
};
