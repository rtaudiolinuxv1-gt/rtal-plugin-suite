import("stdfaust.lib");

declare name "rtal-mirror-detune";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Studio micro-pitch doubler: mirrored detune and short delays for instant width, with mono-safe lows.";

presetMode = nentry("mirror-detune/[0]Factory Preset [style:menu{'Manual':0;'Studio Wide':1;'Eighties Rack':2;'Seasick Double':3}]", 0, 0, 3, 1);
detuneManual = hslider("mirror-detune/[1]Detune [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
delayManual = hslider("mirror-detune/[2]Delay [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
driftManual = hslider("mirror-detune/[3]Drift [style:knob]", 0.15, 0.0, 1.0, 0.01) : si.smoo;
feedbackManual = hslider("mirror-detune/[4]Feedback [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
lowMonoManual = hslider("mirror-detune/[5]Low Mono [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("mirror-detune/[6]Tone [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("mirror-detune/[7]Mix [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isWide = (presetMode >= 0.5) * (presetMode < 1.5);
isRack = (presetMode >= 1.5) * (presetMode < 2.5);
isSeasick = presetMode >= 2.5;

selectPreset(manual, wide, rack, seasick) =
  manual * isManual +
  wide * isWide +
  rack * isRack +
  seasick * isSeasick;

detune = selectPreset(detuneManual, 0.30, 0.45, 0.80);
delayKnob = selectPreset(delayManual, 0.30, 0.45, 0.25);
drift = selectPreset(driftManual, 0.10, 0.20, 0.70);
feedback = selectPreset(feedbackManual, 0.0, 0.30, 0.15);
lowMono = selectPreset(lowMonoManual, 0.45, 0.35, 0.40);
tone = selectPreset(toneManual, 0.75, 0.60, 0.65);
mix = selectPreset(mixManual, 0.45, 0.50, 0.55);

process = _,_ : doublerStereo
with {
  // Up to +/-30 cents, mirrored between the sides.
  cents = detune * detune * 30.0;
  delayMs = 2.0 + delayKnob * 28.0;
  crossHz = 60.0 + lowMono * lowMono * 400.0;

  shifted(semis, ms, x) = (+(x) : ef.transpose(1536, 384, semis) : de.fdelay(8192, ms * 0.001 * ma.SR))
    ~ (*(feedback * 0.6) : fi.lowpass(1, 6000.0))
    : fi.lowpass(1, 2000.0 + tone * tone * 16000.0);

  doublerStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    wobbleL = no.lfnoise(0.35) * drift * 0.12;
    wobbleR = no.lfnoise(0.29) * drift * 0.12;
    upper = mono : shifted(cents * 0.01 + wobbleL, delayMs);
    lower = mono : shifted(0.0 - cents * 0.01 + wobbleR, delayMs * 1.31);
    // Keep the bass centred: the doubled sides are highpassed at the crossover.
    sideL = upper : fi.highpassLR4(crossHz);
    sideR = lower : fi.highpassLR4(crossHz);
    outL = inL * (1.0 - mix * 0.4) + sideL * mix;
    outR = inR * (1.0 - mix * 0.4) + sideR * mix;
  };
};
