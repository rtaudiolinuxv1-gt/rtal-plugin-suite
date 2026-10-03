import("stdfaust.lib");

declare name "rtal-attack-sculpt";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Level-independent transient shaper: boost or soften pick attack and sustain separately.";

presetMode = nentry("attack-sculpt/[0]Factory Preset [style:menu{'Manual':0;'Pick Snap':1;'Violin Soft':2;'Room Bloom':3}]", 0, 0, 3, 1);
attackManual = hslider("attack-sculpt/[1]Attack [style:knob]", 0.65, 0.0, 1.0, 0.01) : si.smoo;
sustainManual = hslider("attack-sculpt/[2]Sustain [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
speedManual = hslider("attack-sculpt/[3]Speed [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
focusManual = hslider("attack-sculpt/[4]Focus [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
clipManual = hslider("attack-sculpt/[5]Soft Clip [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
outputManual = hslider("attack-sculpt/[6]Output [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("attack-sculpt/[7]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isSnap = (presetMode >= 0.5) * (presetMode < 1.5);
isSoft = (presetMode >= 1.5) * (presetMode < 2.5);
isBloom = presetMode >= 2.5;

selectPreset(manual, snap, soft, bloom) =
  manual * isManual +
  snap * isSnap +
  soft * isSoft +
  bloom * isBloom;

// Attack and Sustain are bipolar: 0.5 leaves the signal untouched.
attackKnob = selectPreset(attackManual, 0.85, 0.10, 0.45);
sustainKnob = selectPreset(sustainManual, 0.40, 0.60, 0.90);
speed = selectPreset(speedManual, 0.70, 0.40, 0.45);
focus = selectPreset(focusManual, 0.40, 0.20, 0.20);
clip = selectPreset(clipManual, 0.40, 0.10, 0.30);
output = selectPreset(outputManual, 0.45, 0.55, 0.45);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : sculptStereo
with {
  attackAmt = (attackKnob - 0.5) * 2.0;
  sustainAmt = (sustainKnob - 0.5) * 2.0;
  timeScale = 2.0 - speed * 1.6;

  db(x) = max(x, 0.00001) : ba.linear2db;

  sculptStereo(inL, inR) = outL, outR
  with {
    // Focus moves the detector up the spectrum so low-string thump matters less.
    scHz = 30.0 + focus * focus * 900.0;
    sc = max(abs(inL : fi.highpass(2, scHz)), abs(inR : fi.highpass(2, scHz)));

    // Attack: a fast envelope runs ahead of a slow one at every pick.
    fastAtk = sc : an.amp_follower_ar(0.0005 * timeScale, 0.06 * timeScale);
    slowAtk = sc : an.amp_follower_ar(0.020 * timeScale, 0.06 * timeScale);
    attackDb = max(0.0, db(fastAtk) - db(slowAtk));

    // Sustain: a slow-release envelope outlasts a fast-release one as notes decay.
    longRel = sc : an.amp_follower_ar(0.001, 0.45 * timeScale);
    shortRel = sc : an.amp_follower_ar(0.001, 0.04 * timeScale);
    sustainDb = max(0.0, db(longRel) - db(shortRel));

    gainDb = (attackDb * attackAmt + sustainDb * sustainAmt * 0.9)
      : max(-24.0) : min(12.0)
      : si.smooth(ba.tau2pole(0.0008));
    g = ba.db2linear(gainDb + (output - 0.5) * 24.0);

    // Optional soft clip keeps boosted attacks from overshooting.
    soft(x) = x * (1.0 - clip) + ma.tanh(x) * clip;
    wetL = inL * g : soft;
    wetR = inR * g : soft;
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
