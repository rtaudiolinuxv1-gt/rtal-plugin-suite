import("stdfaust.lib");

declare name "rtal-brickwall";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Lookahead brickwall limiter with drive, ceiling, adaptive release, stereo link and a final safety clip.";

presetMode = nentry("brickwall/[0]Factory Preset [style:menu{'Manual':0;'Transparent':1;'Loud Rhythm':2;'Squashed':3}]", 0, 0, 3, 1);
driveManual = hslider("brickwall/[1]Drive [unit:dB]", 0, 0, 24, 0.1) : si.smoo;
ceilingManual = hslider("brickwall/[2]Ceiling [unit:dB]", -1, -12, 0, 0.1) : si.smoo;
releaseManual = hslider("brickwall/[3]Release [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
linkManual = hslider("brickwall/[4]Stereo Link [style:knob]", 1.0, 0.0, 1.0, 0.01) : si.smoo;
softManual = hslider("brickwall/[5]Soft Saturation [style:knob]", 0.0, 0.0, 1.0, 0.01) : si.smoo;
grMeter = hbargraph("brickwall/[6]Gain Reduction [unit:dB]", 0, 24);

isManual = presetMode < 0.5;
isTransparent = (presetMode >= 0.5) * (presetMode < 1.5);
isLoud = (presetMode >= 1.5) * (presetMode < 2.5);
isSquash = presetMode >= 2.5;

selectPreset(manual, transparent, loud, squash) =
  manual * isManual +
  transparent * isTransparent +
  loud * isLoud +
  squash * isSquash;

driveDb = selectPreset(driveManual, 3.0, 9.0, 18.0);
ceilingDb = selectPreset(ceilingManual, -1.0, -1.0, -2.0);
release = selectPreset(releaseManual, 0.50, 0.30, 0.15);
link = selectPreset(linkManual, 1.0, 0.80, 0.60);
soft = selectPreset(softManual, 0.0, 0.30, 0.60);

process = _,_ : limitStereo
with {
  lookSamples = int(0.0015 * ma.SR);
  ceiling = ba.db2linear(ceilingDb);
  releaseSec = 0.01 + release * release * 0.8;

  // Holds the largest recent reduction for the lookahead window.
  holdMax(n, x) = step ~ (_, _) : _, !
  with {
    step(held, count) = ba.if(take, x, held), ba.if(take, 0.0, count + 1.0)
    with {
      take = (x >= held) | (count >= n);
    };
  };

  // Attack completes inside the lookahead window; release is exponential and
  // slows down the harder the limiter is working.
  smoothReduction(r) = step ~ _
  with {
    step(prev) = ba.if(r > prev, prev + (r - prev) * aAtt, prev + (r - prev) * aRel)
    with {
      aAtt = 1.0 - exp(-4.0 / max(1.0, float(lookSamples)));
      aRel = 1.0 - exp(-1.0 / (releaseSec * (1.0 + prev * 3.0) * ma.SR));
    };
  };

  saturate(x) = x * (1.0 - soft) + ma.tanh(x) * soft;

  limitStereo(inL, inR) = outL, outR
  with {
    g = ba.db2linear(driveDb);
    xL = inL * g : saturate;
    xR = inR * g : saturate;
    peakL = abs(xL);
    peakR = abs(xR);
    linked = max(peakL, peakR);
    detL = peakL * (1.0 - link) + linked * link;
    detR = peakR * (1.0 - link) + linked * link;
    // Reduction needed, as a fraction 0 (none) .. 1 (silence).
    need(p) = max(0.0, 1.0 - ceiling / max(p, 0.000001));
    redL = need(detL) : holdMax(lookSamples) : smoothReduction;
    redR = need(detR) : holdMax(lookSamples) : smoothReduction;
    meter = max(redL, redR) : (1.0 - _) : max(0.000001) : ba.linear2db : (0.0 - _) : grMeter;
    delayL = xL : de.delay(1024, lookSamples);
    delayR = xR : de.delay(1024, lookSamples);
    // Final safety clip catches anything the smoothing let through.
    clip(v) = max(0.0 - ceiling, min(ceiling, v));
    outL = delayL * (1.0 - redL) : clip : attach(_, meter);
    outR = delayR * (1.0 - redR) : clip;
  };
};
