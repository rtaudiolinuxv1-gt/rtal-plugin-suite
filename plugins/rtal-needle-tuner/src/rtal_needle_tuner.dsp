import("stdfaust.lib");

declare name "rtal-needle-tuner";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Chromatic tuner: note, octave and cents meters with adjustable reference pitch and a mute switch for silent tuning.";

mute = checkbox("needle-tuner/[0]Mute");
referenceHz = hslider("needle-tuner/[1]Reference A [unit:Hz]", 440, 425, 455, 0.1);
response = hslider("needle-tuner/[2]Needle Speed [style:knob]", 0.50, 0.0, 1.0, 0.01);
noteMeter = hbargraph("needle-tuner/[3]Note (0=C ... 11=B)", 0, 11);
octaveMeter = hbargraph("needle-tuner/[4]Octave", 0, 8);
centsMeter = hbargraph("needle-tuner/[5]Cents", -50, 50);
freqMeter = hbargraph("needle-tuner/[6]Frequency [unit:Hz]", 0, 1500);

process = _,_ : tunerStereo
with {
  tunerStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    env = mono : an.amp_follower_ar(0.002, 0.1);
    playing = env > 0.003;
    // Coarse pitch from the zero-crossing-rate tracker steers a lowpass that isolates
    // the fundamental; the fine reading then times each cycle exactly.
    // The filter cutoff is snapped to the coarse note so it stays still during a note:
    // a moving cutoff would move the filter's phase delay and wobble the reading.
    coarse = mono : fi.lowpass(2, 1300.0) : an.pitchTracker(2, 0.02) : ba.sAndH(playing) : max(50.0) : min(1400.0)
      : si.smooth(ba.tau2pole(0.05));
    coarseF = 69.0 + 12.0 * log(coarse / 440.0) / log(2.0);
    // Hysteresis: only move to a new note when the coarse pitch strays well away.
    coarseNote = step ~ _
    with {
      step(held) = ba.if(abs(coarseF - held) > 0.8, floor(coarseF + 0.5), held);
    };
    isolateHz = 440.0 * pow(2.0, (coarseNote - 69.0) / 12.0) * 1.6;
    fundamental = mono : fi.highpass(2, 40.0) : fi.lowpass(4, isolateHz);

    // Period between upward zero crossings, with sub-sample linear interpolation of
    // each crossing point. 'age' counts samples since the last crossing.
    y = fundamental;
    loud = (y : abs : an.amp_follower_ar(0.001, 0.05)) > env * 0.05 + 0.0002;
    cross = (y' < 0.0) * (y >= 0.0) * loud;
    frac = y' / min(-0.0000001, y' - y);
    age = step ~ _
    with {
      step(a) = ba.if(cross, 1.0 - frac, min(a + 1.0, 100000.0));
    };
    period = ba.sAndH(cross, age' + frac) : max(20.0);
    // Average the per-cycle pitch; Needle Speed trades steadiness for response.
    // Only the deviation from an integer anchor note is smoothed: a slow one-pole on
    // Hz or on a full note number stalls in float32 (increments drop below the float
    // resolution) and freezes the needle a cent or so off. A jump of more than 0.6
    // semitone snaps instead of crawling.
    tau = 0.05 + (1.0 - response) * 0.3;
    rawNote = 69.0 + 12.0 * log(max(ma.SR / period, 20.0) / referenceHz) / log(2.0) : ba.sAndH(playing);
    anchor = step ~ _
    with {
      step(held) = ba.if(abs(rawNote - held) > 0.8, floor(rawNote + 0.5), held);
    };
    deviation = rawNote - anchor : step ~ _
    with {
      a = 1.0 - exp(-1.0 / (tau * ma.SR));
      step(prev, x) = ba.if(abs(x - prev) > 0.6, x, prev + (x - prev) * a);
    };
    noteF = anchor + deviation;
    nearest = floor(noteF + 0.5);
    cents = (noteF - nearest) * 100.0;
    noteIndex = int(nearest + 120.0) % 12;
    octave = floor(nearest / 12.0) - 1.0;
    hz = referenceHz * pow(2.0, (noteF - 69.0) / 12.0);
    meters = (noteIndex : noteMeter) + (octave : octaveMeter) + (cents : centsMeter) + (hz : freqMeter);
    pass = 1.0 - (mute > 0.5) : si.smooth(ba.tau2pole(0.005));
    outL = inL * pass : attach(_, meters);
    outR = inR * pass;
  };
};
