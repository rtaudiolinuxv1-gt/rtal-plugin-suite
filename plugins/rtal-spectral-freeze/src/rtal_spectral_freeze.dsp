import("stdfaust.lib");

declare name "rtal-spectral-freeze";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Spectral freeze and morph: holds any moment of your playing as an endless frozen spectrum and morphs smoothly between two frozen chords.";
// Holding a sound forever is the point, so long tails are expected.
declare rtal_smoke "allow-sustain";

//==========================================================================
// rtal_spectral_freeze.h stores captures A and B (per-bin magnitude and exact
// frequency) and resynthesises them forever. Faust adds the morph LFO, the
// automatic A/B glide, a reverb wash and the mix.
//==========================================================================

presetMode = nentry("spectral-freeze/[0]Factory Preset [style:menu{'Manual':0;'Chord Pad':1;'Evolving Morph':2;'Octave Halo':3;'Dark Drone':4;'Frozen Glass':5}]", 0, 0, 5, 1);
pick(manual, p1, p2, p3, p4, p5) = ba.selectn(6, int(presetMode), manual, p1, p2, p3, p4, p5);

captureA = button("spectral-freeze/[1]Capture/[1]Capture A");
captureB = button("spectral-freeze/[1]Capture/[2]Capture B");
clearButton = button("spectral-freeze/[1]Capture/[3]Clear");
autoManual = nentry("spectral-freeze/[1]Capture/[4]Auto Capture [style:menu{'Off':0;'Every New Note to A':1;'Alternate A and B':2}]", 1, 0, 2, 1);
sensitivity = hslider("spectral-freeze/[1]Capture/[5]Sensitivity [style:knob]", 0.5, 0.0, 1.0, 0.01);
blurManual = hslider("spectral-freeze/[1]Capture/[6]Blur [style:knob]", 0.3, 0.0, 1.0, 0.01);
filledA = hbargraph("spectral-freeze/[1]Capture/[7]A Holding", 0, 1);
filledB = hbargraph("spectral-freeze/[1]Capture/[8]B Holding", 0, 1);

morphManual = hslider("spectral-freeze/[2]Morph/[1]Morph A to B [style:knob]", 0.0, 0.0, 1.0, 0.01);
glideManual = hslider("spectral-freeze/[2]Morph/[2]Auto Glide [unit:s]", 2.0, 0.05, 12.0, 0.01);
lfoRate = hslider("spectral-freeze/[2]Morph/[3]LFO Rate [unit:Hz]", 0.1, 0.01, 2.0, 0.01);
lfoDepthManual = hslider("spectral-freeze/[2]Morph/[4]LFO Depth [style:knob]", 0.0, 0.0, 1.0, 0.01);

diffusionManual = hslider("spectral-freeze/[3]Texture/[1]Diffusion [style:knob]", 0.15, 0.0, 1.0, 0.01);
shimmerManual = hslider("spectral-freeze/[3]Texture/[2]Shimmer [style:knob]", 0.3, 0.0, 1.0, 0.01);
shiftManual = hslider("spectral-freeze/[3]Texture/[3]Shift [unit:semitones]", 0, -24, 24, 1);
tiltManual = hslider("spectral-freeze/[3]Texture/[4]Tilt (Dark to Bright) [style:knob]", 0.0, -1.0, 1.0, 0.01);
washManual = hslider("spectral-freeze/[3]Texture/[5]Wash [style:knob]", 0.25, 0.0, 1.0, 0.01);

freezeLevel = hslider("spectral-freeze/[4]Mix/[1]Freeze Level [unit:dB]", -3, -60, 6, 0.1) : si.smoo;
swellTime = hslider("spectral-freeze/[4]Mix/[2]Swell [unit:s]", 0.6, 0.01, 8.0, 0.01);
dryLevel = hslider("spectral-freeze/[4]Mix/[3]Dry Level [unit:dB]", 0, -60, 6, 0.1) : si.smoo;

// Presets: Manual, Chord Pad, Evolving Morph, Octave Halo, Dark Drone, Frozen Glass.
autoMode = int(pick(autoManual, 1, 2, 1, 1, 1));
blur = pick(blurManual, 0.4, 0.5, 0.3, 0.7, 0.1);
glide = pick(glideManual, 2.0, 4.0, 2.0, 2.0, 1.0);
lfoDepth = pick(lfoDepthManual, 0.0, 0.25, 0.0, 0.0, 0.0);
diffusion = pick(diffusionManual, 0.1, 0.2, 0.15, 0.3, 0.7);
shimmer = pick(shimmerManual, 0.3, 0.5, 0.3, 0.6, 0.2);
shift = pick(shiftManual, 0, 0, 12, -12, 12);
tilt = pick(tiltManual, -0.1, 0.0, 0.2, -0.6, 0.5) : si.smoo;
wash = pick(washManual, 0.3, 0.4, 0.35, 0.25, 0.5) : si.smoo;

handle = fconstant(int rtal_sf_open, "rtal_spectral_freeze.h") % 65536;
engine = ffunction(float rtal_sf_process(int, float, float, int, int, int, float, float, float, float, float, float, float, int), "rtal_spectral_freeze.h", "");
info = ffunction(float rtal_sf_info(int, int, float), "rtal_spectral_freeze.h", "");

process(l, r) = outL, outR
with {
  mono = (l + r) * 0.5;
  // Morph: manual position, or in Alternate mode a glide towards the newest
  // capture; the LFO sways around either. (Tied to the input, this read may
  // see the engine state one sample late, which is harmless for a glide.)
  latestSlot = info(handle, 1, mono);
  glideTarget = ba.if(autoMode == 2, latestSlot, morphManual) : si.smooth(ba.tau2pole(glide));
  lfo = os.osc(lfoRate) * 0.5 * lfoDepth;
  morph = glideTarget + lfo : max(0.0) : min(1.0);
  frozenL = engine(handle, mono, ma.SR, int(captureA), int(captureB), autoMode, sensitivity, blur, morph,
                   diffusion, shimmer, shift, tilt, int(clearButton));
  frozenR = info(handle, 0, frozenL);
  holdA = info(handle, 2, frozenL);
  holdB = info(handle, 3, frozenL);
  // Swell in when something is captured.
  swell = max(holdA, holdB) : si.smooth(ba.tau2pole(swellTime));
  gain = ba.db2linear(freezeLevel) * swell;
  fl = frozenL * gain;
  fr = frozenR * gain;
  verb = (fl, fr) : re.zita_rev1_stereo(30, 200, 7000, 4.0, 6.0, 48000);
  wetL = fl * (1.0 - wash * 0.5) + ba.selector(0, 2, verb) * wash;
  wetR = fr * (1.0 - wash * 0.5) + ba.selector(1, 2, verb) * wash;
  dry = ba.db2linear(dryLevel);
  outL = l * dry + wetL : attach(_, holdA : filledA) : attach(_, holdB : filledB);
  outR = r * dry + wetR;
};
