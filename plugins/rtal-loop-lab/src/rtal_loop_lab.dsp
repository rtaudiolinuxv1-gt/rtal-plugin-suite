import("stdfaust.lib");

declare name "rtal-loop-lab";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Stereo looper with record, overdub with fading layers, play/stop, clear, half-speed and reverse playback.";

presetMode = nentry("loop-lab/[0]Factory Preset [style:menu{'Manual':0;'Classic Looper':1;'Fading Layers':2;'Ambient Half-Speed':3}]", 0, 0, 3, 1);
record = checkbox("loop-lab/[1]Record - Overdub");
play = checkbox("loop-lab/[2]Play");
clear = button("loop-lab/[3]Clear");
speedManual = nentry("loop-lab/[4]Speed [style:menu{'Normal':0;'Half':1;'Reverse':2;'Half Reverse':3}]", 0, 0, 3, 1);
feedbackManual = hslider("loop-lab/[5]Overdub Feedback [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
levelManual = hslider("loop-lab/[6]Loop Level [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("loop-lab/[7]Loop Tone [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
dryManual = hslider("loop-lab/[8]Dry [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
lengthMeter = hbargraph("loop-lab/[9]Loop Length [unit:s]", 0, 22);

isManual = presetMode < 0.5;
isClassic = (presetMode >= 0.5) * (presetMode < 1.5);
isFading = (presetMode >= 1.5) * (presetMode < 2.5);
isAmbient = presetMode >= 2.5;

selectPreset(manual, classic, fading, ambient) =
  manual * isManual +
  classic * isClassic +
  fading * isFading +
  ambient * isAmbient;

speed = int(selectPreset(speedManual, 0, 0, 1));
feedback = selectPreset(feedbackManual, 1.0, 0.82, 0.92);
level = selectPreset(levelManual, 0.80, 0.80, 0.70);
tone = selectPreset(toneManual, 1.0, 0.70, 0.45);
dry = selectPreset(dryManual, 1.0, 1.0, 1.0);

process = _,_ : loopStereo
with {
  tableSize = 1048576;
  maxLen = float(tableSize - 4);

  recOn = record > 0.5;
  playOn = play > 0.5;
  clearHit = clear > 0.5;

  // Loop length: counts while the very first recording runs, then latches.
  // Clear resets it so the next recording starts a fresh loop.
  // State: (length in samples, first-take-in-progress flag).
  transport = step ~ (_, _)
  with {
    step(len, counting) = newLen, newCounting
    with {
      starting = recOn * (len < 1.0) * (counting < 0.5);
      newCounting = ba.if(clearHit, 0.0, ba.if(starting, 1.0, ba.if(counting * (1 - recOn) + (len >= maxLen), 0.0, counting)));
      newLen = ba.if(clearHit, 0.0, ba.if(counting * recOn * (len < maxLen), len + 1.0, len));
    };
  };
  loopLen = transport : _, !;
  firstTake = transport : !, _;
  hasLoop = (loopLen >= 1.0) * (firstTake < 0.5);

  // Read position: follows the recording head during the first take, then wraps.
  rate = ba.selectn(4, speed, 1.0, 0.5, -1.0, -0.5);
  position = step ~ _
  with {
    step(p) = ba.if(clearHit, 0.0,
      ba.if(firstTake > 0.5, loopLen,
      ba.if(hasLoop * playOn, wrapLen(p + rate), p)));
    wrapLen(v) = v - floor(v / max(1.0, loopLen)) * max(1.0, loopLen);
  };

  // Linear-interpolated read for half speed; writes happen one sample behind the read.
  track(x) = (core ~ _) : !, _
  with {
    core(prevWrite) = writeValue, played
    with {
      i0 = int(position);
      i1 = int(ba.if(position + 1.0 >= loopLen, 0.0, position + 1.0));
      frac = position - floor(position);
      a = rwtable(tableSize, 0.0, int(position'), prevWrite, i0);
      b = rwtable(tableSize, 0.0, int(position'), prevWrite, i1);
      played = a * (1.0 - frac) + b * frac;
      // First take writes the input; overdub fades the old layer by Feedback.
      // Overdub runs at full speed only (half speed would visit each sample twice).
      canDub = recOn * hasLoop * playOn * (abs(rate) > 0.75);
      writeValue = ba.if(firstTake > 0.5, x, ba.if(canDub, a * feedback + x, a));
    };
  };

  loopStereo(inL, inR) = outL, outR
  with {
    audible = (hasLoop * playOn) : si.smooth(ba.tau2pole(0.005));
    loopTone = fi.lowpass(1, 800.0 + tone * tone * 19000.0);
    loopL = inL : track : loopTone : *(audible * level);
    loopR = inR : track : loopTone : *(audible * level);
    meter = loopLen / ma.SR : lengthMeter;
    outL = inL * dry + loopL : attach(_, meter);
    outR = inR * dry + loopR;
  };
};
