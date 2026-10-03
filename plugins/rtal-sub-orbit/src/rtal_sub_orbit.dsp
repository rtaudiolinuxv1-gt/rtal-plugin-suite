import("stdfaust.lib");

declare name "rtal-sub-orbit";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Analog-style flip-flop octaver with one and two octaves down plus rectified octave up.";

presetMode = nentry("sub-orbit/[0]Factory Preset [style:menu{'Manual':0;'Bass Shadow':1;'Synth Floor':2;'Octave Fuzz':3}]", 0, 0, 3, 1);
dryManual = hslider("sub-orbit/[1]Dry [style:knob]", 0.75, 0.0, 1.0, 0.01) : si.smoo;
sub1Manual = hslider("sub-orbit/[2]Sub 1 [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
sub2Manual = hslider("sub-orbit/[3]Sub 2 [style:knob]", 0.20, 0.0, 1.0, 0.01) : si.smoo;
upManual = hslider("sub-orbit/[4]Octave Up [style:knob]", 0.10, 0.0, 1.0, 0.01) : si.smoo;
toneManual = hslider("sub-orbit/[5]Sub Tone [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
gritManual = hslider("sub-orbit/[6]Grit [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
trackManual = hslider("sub-orbit/[7]Tracking [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isBass = (presetMode >= 0.5) * (presetMode < 1.5);
isSynth = (presetMode >= 1.5) * (presetMode < 2.5);
isFuzz = presetMode >= 2.5;

selectPreset(manual, bass, synth, fuzz) =
  manual * isManual +
  bass * isBass +
  synth * isSynth +
  fuzz * isFuzz;

dry = selectPreset(dryManual, 0.70, 0.40, 0.55);
sub1 = selectPreset(sub1Manual, 0.80, 0.70, 0.50);
sub2 = selectPreset(sub2Manual, 0.00, 0.55, 0.10);
up = selectPreset(upManual, 0.00, 0.10, 0.75);
tone = selectPreset(toneManual, 0.30, 0.55, 0.65);
grit = selectPreset(gritManual, 0.10, 0.60, 0.80);
track = selectPreset(trackManual, 0.50, 0.55, 0.45);

process = _,_ : octaveStereo
with {
  // Schmitt trigger: holds its state until the signal crosses the opposite threshold.
  schmitt(th, x) = step ~ _
  with {
    step(prev) = ba.if(x > th, 1.0, ba.if(x < 0.0 - th, 0.0, prev));
  };

  // Toggle flip-flop: changes state on every rising edge, halving the frequency.
  toggle(gate) = step ~ _
  with {
    rise = gate > gate';
    step(prev) = ba.if(rise, 1.0 - prev, prev);
  };

  octaveStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5 : fi.dcblocker;
    // Isolate the fundamental before edge detection; Tracking moves the filter.
    trackHz = 280.0 + track * 900.0;
    fundamental = mono : fi.lowpass(4, trackHz) : fi.highpass(1, 50.0);
    env = mono : an.amp_follower_ar(0.003, 0.09);
    th = env * (0.06 + (1.0 - track) * 0.18) + 0.0004;

    edge = schmitt(th, fundamental);
    div2 = toggle(edge);
    div4 = toggle(div2);

    // Envelope-shaped squares, rounded off by the sub filter. Grit lets more edge through.
    subHz = 90.0 + tone * tone * 900.0;
    gateEnv = env : min(0.6) : si.smooth(ba.tau2pole(0.004));
    square(s) = (2.0 * s - 1.0) * gateEnv;
    shapeSub(s) = square(s) : fi.lowpass(2, subHz * (1.0 + grit * 3.0)) : fi.lowpass(2, subHz) : *(1.0 + grit * 0.5);
    oct1 = shapeSub(div2);
    oct2 = shapeSub(div4) : fi.lowpass(1, subHz * 0.6);

    // Full-wave rectification doubles the frequency; grit adds a fuzz edge.
    rect = abs(mono : fi.lowpass(2, 2500.0)) : fi.highpass(2, 90.0);
    octUp = ma.tanh(rect * (2.0 + grit * 10.0)) * (0.5 - grit * 0.25);

    wet = oct1 * sub1 + oct2 * sub2 * 1.1 + octUp * up * 1.2;
    outL = inL * dry + wet;
    outR = inR * dry + wet;
  };
};
