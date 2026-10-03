import("stdfaust.lib");

declare name "rtal-cathedral-shimmer";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Shimmer reverb: a large hall whose tail is pitch-shifted back into itself.";

presetMode = nentry("cathedral-shimmer/[0]Factory Preset [style:menu{'Manual':0;'Heaven Octave':1;'Fifth Cathedral':2;'Abyss Choir':3}]", 0, 0, 3, 1);
intervalManual = nentry("cathedral-shimmer/[1]Interval [style:menu{'+12 Octave':0;'+7 Fifth':1;'+19 Twelfth':2;'+24 Two Octaves':3;'-12 Octave Down':4}]", 0, 0, 4, 1);
sizeManual = hslider("cathedral-shimmer/[2]Size [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
shimmerManual = hslider("cathedral-shimmer/[3]Shimmer [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
dampManual = hslider("cathedral-shimmer/[4]Damping [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
predelayManual = hslider("cathedral-shimmer/[5]Pre-Delay [style:knob]", 0.25, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("cathedral-shimmer/[6]Shimmer Tone [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("cathedral-shimmer/[7]Mix [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isHeaven = (presetMode >= 0.5) * (presetMode < 1.5);
isFifth = (presetMode >= 1.5) * (presetMode < 2.5);
isAbyss = presetMode >= 2.5;

selectPreset(manual, heaven, fifth, abyss) =
  manual * isManual +
  heaven * isHeaven +
  fifth * isFifth +
  abyss * isAbyss;

interval = int(selectPreset(intervalManual, 0, 1, 4));
size = selectPreset(sizeManual, 0.72, 0.62, 0.85);
shimmer = selectPreset(shimmerManual, 0.55, 0.45, 0.50);
damp = selectPreset(dampManual, 0.35, 0.45, 0.60);
predelay = selectPreset(predelayManual, 0.30, 0.20, 0.45);
tone = selectPreset(toneManual, 0.65, 0.55, 0.40);
mix = selectPreset(mixManual, 0.40, 0.35, 0.45);

process = _,_ : shimmerStereo
with {
  semitones = ba.selectn(5, interval, 12.0, 7.0, 19.0, 24.0, -12.0);

  t60 = 1.2 + size * size * 14.0;
  hfDampHz = 9000.0 - damp * 7000.0;
  predelaySamples = (5.0 + predelay * 245.0) * 0.001 * ma.SR;

  hall = re.zita_rev1_stereo(0, 180.0, hfDampHz, t60 * 0.8, t60, 192000);

  // Two-window granular pitch shifter in the feedback path.
  shifter = ef.transpose(4096, 1024, semitones);
  // Feedback is normalised against the hall's build-up so long tails stay bounded.
  fbGain = shimmer * 0.9 / (1.0 + t60 * 0.08);
  shimmerPath = shifter : fi.lowpass(2, 2000.0 + tone * 9000.0) : fi.highpass(2, 150.0) : *(fbGain) : ma.tanh;

  // Inputs: feedback L/R from the loop, then dry L/R. Channels swap on the way back for width.
  loopIn = route(4, 2, (1, 2), (2, 1), (3, 1), (4, 2));
  tank = (loopIn : hall) ~ (shimmerPath, shimmerPath);

  shimmerStereo(inL, inR) = outL, outR
  with {
    sendL = inL : de.fdelay(19200, min(19000.0, predelaySamples)) : fi.highpass(1, 100.0);
    sendR = inR : de.fdelay(19200, min(19000.0, predelaySamples)) : fi.highpass(1, 100.0);
    wet = sendL, sendR : tank;
    wetL = wet : _, !;
    wetR = wet : !, _;
    outL = inL * (1.0 - mix * 0.5) + wetL * mix;
    outR = inR * (1.0 - mix * 0.5) + wetR * mix;
  };
};
