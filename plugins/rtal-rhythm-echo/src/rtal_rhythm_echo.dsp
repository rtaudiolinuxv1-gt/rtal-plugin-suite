import("stdfaust.lib");

declare name "rtal-rhythm-echo";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Tempo-synced ping-pong echo that ducks while you play and blooms when you stop.";

presetMode = nentry("rhythm-echo/[0]Factory Preset [style:menu{'Manual':0;'Dotted Eighth Stadium':1;'Ducked Lead':2;'Diffuse Bounce':3}]", 0, 0, 3, 1);
bpmManual = hslider("rhythm-echo/[1]BPM", 120, 40, 240, 0.1);
divisionManual = nentry("rhythm-echo/[2]Division [style:menu{'1/4':0;'Dotted 1/8':1;'1/8':2;'1/4 Triplet':3;'1/16':4;'Dotted 1/4':5}]", 1, 0, 5, 1);
feedbackManual = hslider("rhythm-echo/[3]Feedback [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
pingManual = hslider("rhythm-echo/[4]Ping Pong [style:knob]", 0.80, 0.0, 1.0, 0.01) : si.smoo;
duckManual = hslider("rhythm-echo/[5]Duck [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
diffuseManual = hslider("rhythm-echo/[6]Diffuse [style:knob]", 0.10, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("rhythm-echo/[7]Tone [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
modManual = hslider("rhythm-echo/[8]Modulation [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("rhythm-echo/[9]Mix [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isStadium = (presetMode >= 0.5) * (presetMode < 1.5);
isDucked = (presetMode >= 1.5) * (presetMode < 2.5);
isDiffuse = presetMode >= 2.5;

selectPreset(manual, stadium, ducked, diffuse) =
  manual * isManual +
  stadium * isStadium +
  ducked * isDucked +
  diffuse * isDiffuse;

// Tempo always follows the BPM control.
bpm = bpmManual;
division = int(selectPreset(divisionManual, 1, 0, 2));
feedback = selectPreset(feedbackManual, 0.40, 0.45, 0.60);
ping = selectPreset(pingManual, 0.30, 0.90, 1.00);
duck = selectPreset(duckManual, 0.15, 0.80, 0.30);
diffuse = selectPreset(diffuseManual, 0.05, 0.10, 0.70);
tone = selectPreset(toneManual, 0.70, 0.55, 0.45);
modAmt = selectPreset(modManual, 0.10, 0.20, 0.35);
mix = selectPreset(mixManual, 0.35, 0.40, 0.40);

process = _,_ : echoStereo
with {
  maxDelay = 524288;

  beats = ba.selectn(6, division, 1.0, 0.75, 0.5, 0.6666667, 0.25, 1.5);
  delaySec = 60.0 / bpm * beats;
  delaySamples = delaySec * ma.SR : si.smooth(ba.tau2pole(0.15));

  wrap(x) = x - floor(x);
  modSig(offset) = sin(2.0 * ma.PI * wrap(((+(0.35 / ma.SR) : wrap) ~ _) + offset)) * modAmt * 0.0025 * ma.SR;

  // Short allpass smear inside the loop; each repeat gets more diffuse.
  smear = seq(i, 3, fi.allpass_comb(2048, ba.take(i + 1, (347, 613, 1031)), diffuse * 0.65));

  loopTone = fi.lowpass(2, 1500.0 + tone * 9500.0) : fi.highpass(1, 80.0 + (1.0 - tone) * 200.0);

  line(offset) = de.fdelay3(maxDelay, min(float(maxDelay - 8), max(16.0, delaySamples + modSig(offset))));

  // Ping Pong 1: the left echo feeds the right and vice versa, so repeats bounce.
  // Ping Pong 0: two parallel echoes.
  echoCore(x, prevL, prevR) = l, r
  with {
    cross(a, b) = (a * ping + b * (1.0 - ping)) * feedback * 0.98 : ma.tanh;
    l = (x + cross(prevR, prevL)) : line(0.0);
    r = (x * (1.0 - ping) + cross(prevL, prevR)) : line(0.25);
  };

  echoes(x) = echoCore(x) ~ (shape, shape)
  with {
    shape = smear : loopTone;
  };

  echoStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    // Ducking: the echoes step back while you play and swell up in the gaps.
    env = mono : an.amp_follower_ar(0.01, 0.30) : *(6.0) : min(1.0);
    duckGain = 1.0 - duck * env;
    wet = mono : echoes;
    wetL = (wet : _, !) : loopTone : *(duckGain);
    wetR = (wet : !, _) : loopTone : *(duckGain);
    outL = inL * (1.0 - mix * 0.4) + wetL * mix;
    outR = inR * (1.0 - mix * 0.4) + wetR * mix;
  };
};
