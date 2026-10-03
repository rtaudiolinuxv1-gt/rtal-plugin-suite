import("stdfaust.lib");

declare name "rtal-slide-scoop";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Automatic pitch gestures: every note scoops up into pitch, dives in from above, or falls off as it decays.";

presetMode = nentry("slide-scoop/[0]Factory Preset [style:menu{'Manual':0;'Steel Scoop':1;'Drunk Slide':2;'Fall Off Blues':3}]", 0, 0, 3, 1);
modeManual = nentry("slide-scoop/[1]Gesture [style:menu{'Scoop Up':0;'Dive In':1;'Fall Off':2;'Scoop and Fall':3}]", 0, 0, 3, 1);
depthManual = hslider("slide-scoop/[2]Depth [unit:semitones]", 2.0, 0.25, 12.0, 0.01) : si.smoo;
timeManual = hslider("slide-scoop/[3]Glide Time [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
curveManual = hslider("slide-scoop/[4]Curve [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
sensManual = hslider("slide-scoop/[5]Sensitivity [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("slide-scoop/[6]Mix [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isSteel = (presetMode >= 0.5) * (presetMode < 1.5);
isDrunk = (presetMode >= 1.5) * (presetMode < 2.5);
isBlues = presetMode >= 2.5;

selectPreset(manual, steel, drunk, blues) =
  manual * isManual +
  steel * isSteel +
  drunk * isDrunk +
  blues * isBlues;

mode = int(selectPreset(modeManual, 0, 3, 2));
depth = selectPreset(depthManual, 1.0, 3.0, 5.0);
time = selectPreset(timeManual, 0.30, 0.50, 0.55);
curve = selectPreset(curveManual, 0.65, 0.40, 0.50);
sens = selectPreset(sensManual, 0.55, 0.55, 0.55);
mix = selectPreset(mixManual, 1.0, 1.0, 1.0);

process = _,_ : scoopStereo
with {
  glideSec = 0.03 + time * time * 0.6;
  refractory = 0.08 * ma.SR;

  sinceTrigger(raw) = step ~ _
  with {
    step(c) = ba.if(raw * (c > refractory), 0.0, min(c + 1.0, 100000000.0));
  };

  scoopStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    fast = mono : abs : an.amp_follower_ar(0.0005, 0.03);
    slow = mono : abs : an.amp_follower_ar(0.03, 0.3);
    onset = fast > slow * 1.6 + 0.002 + (1.0 - sens) * 0.03;
    count = sinceTrigger(onset > onset');

    // Attack gesture: starts offset by Depth and settles onto the note.
    progress = min(1.0, count / (glideSec * ma.SR));
    settle = pow(1.0 - progress, 0.5 + curve * 2.5);
    // Release gesture: pitch falls as the note dies away.
    env = mono : an.amp_follower_ar(0.001, 0.15);
    peak = mono : an.amp_follower_ar(0.0005, 0.6);
    fade = 1.0 - min(1.0, env / max(peak, 0.0001));
    falling = pow(max(0.0, fade - 0.35) / 0.65, 1.0 + curve * 2.0);

    semis = ba.selectn(4, mode,
      0.0 - depth * settle,
      depth * settle,
      0.0 - depth * falling,
      0.0 - depth * settle * 0.6 - depth * falling)
      : si.smooth(ba.tau2pole(0.003));

    // A short lookahead keeps the very start of the note inside the gesture.
    wetL = inL : de.delay(512, int(0.003 * ma.SR)) : ef.transpose(1536, 384, semis);
    wetR = inR : de.delay(512, int(0.003 * ma.SR)) : ef.transpose(1536, 384, semis);
    outL = inL * (1.0 - mix) + wetL * mix;
    outR = inR * (1.0 - mix) + wetR * mix;
  };
};
