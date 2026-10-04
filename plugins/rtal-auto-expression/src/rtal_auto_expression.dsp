import("stdfaust.lib");

declare name "rtal-auto-expression";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Auto-expression: hears how you play (pick force, palm mutes, bends, vibrato, slides, sustain) and lets each technique drive an effect.";

//==========================================================================
// rtal_expression.h measures six playing gestures from the guitar signal.
// Each gesture row picks a target and an amount (negative amounts work in
// reverse). A target's value is its base knob plus every gesture routed to
// it, clamped to 0..1, and drives one stage of the effect chain:
//   Tightness (expander + low cut) > Drive > Wah > Brightness > Chorus >
//   Delay > Reverb > Volume
//==========================================================================

presetMode = nentry("auto-expression/[0]Factory Preset [style:menu{'Manual':0;'Expressive Lead':1;'Metal Chug':2;'Ambient Swells':3;'Funk Wah':4;'Blues Bender':5}]", 0, 0, 5, 1);
pick(manual, p1, p2, p3, p4, p5) = ba.selectn(6, int(presetMode), manual, p1, p2, p3, p4, p5);

sensitivity = hslider("auto-expression/[1]Detection/[1]Sensitivity [style:knob]", 0.5, 0.0, 1.0, 0.01);
response = hslider("auto-expression/[1]Detection/[2]Response [unit:ms]", 40, 5, 400, 1);

// Faust labels need literal text, so each gesture row is written out.
forceTarget = nentry("auto-expression/[2]Gestures/[10]Pick Force Target [style:menu{'None':0;'Wah':1;'Drive':2;'Delay':3;'Reverb':4;'Chorus':5;'Tightness':6;'Volume':7;'Brightness':8}]", 2, 0, 8, 1);
forceAmount = hslider("auto-expression/[2]Gestures/[11]Pick Force Amount [style:knob]", 0.5, -1, 1, 0.01);
palmTarget = nentry("auto-expression/[2]Gestures/[20]Palm Mute Target [style:menu{'None':0;'Wah':1;'Drive':2;'Delay':3;'Reverb':4;'Chorus':5;'Tightness':6;'Volume':7;'Brightness':8}]", 6, 0, 8, 1);
palmAmount = hslider("auto-expression/[2]Gestures/[21]Palm Mute Amount [style:knob]", 0.9, -1, 1, 0.01);
bendTarget = nentry("auto-expression/[2]Gestures/[30]Bend Target [style:menu{'None':0;'Wah':1;'Drive':2;'Delay':3;'Reverb':4;'Chorus':5;'Tightness':6;'Volume':7;'Brightness':8}]", 1, 0, 8, 1);
bendAmount = hslider("auto-expression/[2]Gestures/[31]Bend Amount [style:knob]", 1.0, -1, 1, 0.01);
vibTarget = nentry("auto-expression/[2]Gestures/[40]Vibrato Target [style:menu{'None':0;'Wah':1;'Drive':2;'Delay':3;'Reverb':4;'Chorus':5;'Tightness':6;'Volume':7;'Brightness':8}]", 5, 0, 8, 1);
vibAmount = hslider("auto-expression/[2]Gestures/[41]Vibrato Amount [style:knob]", 0.8, -1, 1, 0.01);
slideTarget = nentry("auto-expression/[2]Gestures/[50]Slide Target [style:menu{'None':0;'Wah':1;'Drive':2;'Delay':3;'Reverb':4;'Chorus':5;'Tightness':6;'Volume':7;'Brightness':8}]", 3, 0, 8, 1);
slideAmount = hslider("auto-expression/[2]Gestures/[51]Slide Amount [style:knob]", 0.6, -1, 1, 0.01);
sustainTarget = nentry("auto-expression/[2]Gestures/[60]Sustain Target [style:menu{'None':0;'Wah':1;'Drive':2;'Delay':3;'Reverb':4;'Chorus':5;'Tightness':6;'Volume':7;'Brightness':8}]", 4, 0, 8, 1);
sustainAmount = hslider("auto-expression/[2]Gestures/[61]Sustain Amount [style:knob]", 0.5, -1, 1, 0.01);

forceMeter = hbargraph("auto-expression/[3]Heard/[1]Pick Force", 0, 1);
palmMeter = hbargraph("auto-expression/[3]Heard/[2]Palm Mute", 0, 1);
bendMeter = hbargraph("auto-expression/[3]Heard/[3]Bend", 0, 1);
vibMeter = hbargraph("auto-expression/[3]Heard/[4]Vibrato", 0, 1);
slideMeter = hbargraph("auto-expression/[3]Heard/[5]Slide", 0, 1);
sustainMeter = hbargraph("auto-expression/[3]Heard/[6]Sustain", 0, 1);

wahBaseM = hslider("auto-expression/[4]Base Settings/[1]Wah [style:knob]", 0.0, 0, 1, 0.01);
driveBaseM = hslider("auto-expression/[4]Base Settings/[2]Drive [style:knob]", 0.15, 0, 1, 0.01);
delayBaseM = hslider("auto-expression/[4]Base Settings/[3]Delay [style:knob]", 0.1, 0, 1, 0.01);
reverbBaseM = hslider("auto-expression/[4]Base Settings/[4]Reverb [style:knob]", 0.15, 0, 1, 0.01);
chorusBaseM = hslider("auto-expression/[4]Base Settings/[5]Chorus [style:knob]", 0.0, 0, 1, 0.01);
tightBaseM = hslider("auto-expression/[4]Base Settings/[6]Tightness [style:knob]", 0.0, 0, 1, 0.01);
volumeBaseM = hslider("auto-expression/[4]Base Settings/[7]Volume [style:knob]", 1.0, 0, 1, 0.01);
brightBaseM = hslider("auto-expression/[4]Base Settings/[8]Brightness [style:knob]", 0.5, 0, 1, 0.01);

delayTime = hslider("auto-expression/[5]Effects/[1]Delay Time [unit:ms]", 380, 40, 1500, 1) : si.smoo;
delayFeedback = hslider("auto-expression/[5]Effects/[2]Delay Feedback [style:knob]", 0.35, 0, 0.9, 0.01) : si.smoo;
reverbDecay = hslider("auto-expression/[5]Effects/[3]Reverb Decay [unit:s]", 2.5, 0.5, 10, 0.01) : si.smoo : max(0.5);
outLevel = hslider("auto-expression/[5]Effects/[4]Output Level [unit:dB]", 0, -30, 12, 0.1) : si.smoo;

// Presets: Manual, Expressive Lead, Metal Chug, Ambient Swells, Funk Wah, Blues Bender.
fT = int(pick(forceTarget, 2, 2, 7, 1, 2));
fA = pick(forceAmount, 0.5, 0.6, -0.3, 0.9, 0.5);
pT = int(pick(palmTarget, 6, 6, 4, 6, 6));
pA = pick(palmAmount, 0.9, 1.0, -0.5, 0.7, 0.6);
bT = int(pick(bendTarget, 1, 8, 4, 1, 2));
bA = pick(bendAmount, 1.0, 0.6, 0.5, 0.5, 0.7);
vT = int(pick(vibTarget, 5, 5, 5, 5, 3));
vA = pick(vibAmount, 0.8, 0.5, 0.9, 0.6, 0.8);
sT = int(pick(slideTarget, 3, 3, 3, 3, 3));
sA = pick(slideAmount, 0.6, 0.3, 0.8, 0.4, 0.5);
uT = int(pick(sustainTarget, 4, 3, 7, 4, 4));
uA = pick(sustainAmount, 0.5, 0.4, 0.8, 0.2, 0.4);
wahBase = pick(wahBaseM, 0.0, 0.0, 0.0, 0.0, 0.0);
driveBase = pick(driveBaseM, 0.3, 0.55, 0.0, 0.1, 0.25);
delayBase = pick(delayBaseM, 0.1, 0.0, 0.35, 0.05, 0.1);
reverbBase = pick(reverbBaseM, 0.15, 0.05, 0.45, 0.1, 0.2);
chorusBase = pick(chorusBaseM, 0.0, 0.0, 0.2, 0.0, 0.0);
tightBase = pick(tightBaseM, 0.0, 0.2, 0.0, 0.1, 0.0);
volumeBase = pick(volumeBaseM, 1.0, 1.0, 0.35, 1.0, 1.0);
brightBase = pick(brightBaseM, 0.5, 0.4, 0.45, 0.6, 0.45);

handle = fconstant(int rtal_ae_open, "rtal_expression.h") % 65536;
engine = ffunction(float rtal_ae_process(int, float, float, float), "rtal_expression.h", "");
gestureOf = ffunction(float rtal_ae_gesture(int, int, float), "rtal_expression.h", "");

process(l, r) = outL, outR
with {
  mono = (l + r) * 0.5;
  tie = engine(handle, mono, ma.SR, sensitivity);
  smoothing = ba.tau2pole(response * 0.001);
  g(i) = gestureOf(handle, i, tie) : si.smooth(smoothing);
  force = g(0); palm = g(1); bend = g(2); vib = g(3); slide = g(4); sustain = g(5);

  routed(t) = fA * force * (fT == t) + pA * palm * (pT == t) + bA * bend * (bT == t)
            + vA * vib * (vT == t) + sA * slide * (sT == t) + uA * sustain * (uT == t);
  value(base, t) = base + routed(t) : max(0.0) : min(1.0);
  wah = value(wahBase, 1);
  drive = value(driveBase, 2);
  delaySend = value(delayBase, 3);
  reverbSend = value(reverbBase, 4);
  chorusAmt = value(chorusBase, 5);
  tight = value(tightBase, 6);
  volume = value(volumeBase, 7);
  bright = value(brightBase, 8);

  // Tightness: low cut plus a downward expander that clamps the decay.
  lowCut = fi.highpass(2, 30.0 + tight * 250.0);
  levelDb = mono : abs : an.amp_follower_ar(0.002, 0.08) : ba.linear2db;
  expandDb = min(0.0, (levelDb - (-70.0 + tight * 38.0)) * tight * 1.5) : max(-50.0);
  expGain = ba.db2linear(expandDb) : si.smooth(ba.tau2pole(0.004));

  // Drive: anti-aliased tanh with loudness compensation, clean when at 0.
  driveGain = ba.db2linear(drive * 32.0);
  logCosh(x) = abs(x) + log(1.0 + exp(-2.0 * abs(x))) - log(2.0);
  adaaTanh(x) = ba.if(abs(dx) < 0.0001, ma.tanh(0.5 * (x + x')), (logCosh(x) - logCosh(x')) / dx)
  with { dx = x - x'; };
  driven(x) = adaaTanh(x * driveGain) / pow(driveGain, 0.75) : fi.lowpass(1, 7000.0 - drive * 2500.0);
  driveStage(x) = x + (driven(x) - x) * min(1.0, drive * 6.0);

  // Wah: resonant band-pass swept by the target value, faded in from zero.
  wahFc = 380.0 * pow(2.0, wah * 2.7);
  wahStage(x) = x + ((x : fi.resonbp(wahFc, 5.0, 1.0) : *(0.6)) - x) * min(1.0, wah * 5.0);

  // Brightness: high-shelf tilt of +/-9 dB around the 0.5 centre.
  brightStage = fi.high_shelf((bright - 0.5) * 18.0, 2200.0);

  chain(x) = x : lowCut : *(expGain) : driveStage : wahStage : brightStage;
  cl = l : chain;
  cr = r : chain;

  // Chorus: one modulated voice per side.
  chorusVoice(ph, x) = x : de.fdelay3(2048, (7.0 + os.oscp(0.7, ph) * chorusAmt * 4.5) * 0.001 * ma.SR);
  chL = cl + (chorusVoice(0.0, cl) - cl) * chorusAmt * 0.5;
  chR = cr + (chorusVoice(1.6, cr) - cr) * chorusAmt * 0.5;

  // Delay send.
  dSamples = delayTime * 0.001 * ma.SR : max(16.0);
  echo(x) = x : (+ : de.fdelay(96000, dSamples)) ~ (fi.lowpass(1, 4500.0) : *(delayFeedback));
  dlL = chL + echo(chL * delaySend) * 0.8;
  dlR = chR + echo(chR * delaySend) * 0.8;

  // Reverb send.
  verb = (dlL * reverbSend, dlR * reverbSend) : re.zita_rev1_stereo(20, 200, 6000, reverbDecay * 0.8, reverbDecay, 48000);
  outGain = volume * ba.db2linear(outLevel);
  meters = attach(_, force : forceMeter) : attach(_, palm : palmMeter) : attach(_, bend : bendMeter)
         : attach(_, vib : vibMeter) : attach(_, slide : slideMeter) : attach(_, sustain : sustainMeter);
  outL = (dlL + ba.selector(0, 2, verb) * 0.7) * outGain : meters;
  outR = (dlR + ba.selector(1, 2, verb) * 0.7) * outGain;
};
