import("stdfaust.lib");

declare name "rtal-sympathetic-strings";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Bank of tuned sympathetic strings that ring along with your playing in a chosen key and chord.";

presetMode = nentry("sympathetic-strings/[0]Factory Preset [style:menu{'Manual':0;'Sitar Room':1;'Harp Halo':2;'Drone Temple':3}]", 0, 0, 3, 1);
keyManual = nentry("sympathetic-strings/[1]Key [style:menu{'C':0;'C#':1;'D':2;'D#':3;'E':4;'F':5;'F#':6;'G':7;'G#':8;'A':9;'A#':10;'B':11}]", 4, 0, 11, 1);
chordManual = nentry("sympathetic-strings/[2]Chord [style:menu{'Major':0;'Minor':1;'Sus4':2;'Power':3;'Maj7':4;'Min7':5;'Raga Drone':6}]", 0, 0, 6, 1);
resonanceManual = hslider("sympathetic-strings/[3]Resonance [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
brightManual = hslider("sympathetic-strings/[4]Brightness [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
exciteManual = hslider("sympathetic-strings/[5]Excite [style:knob]", 0.50, 0.0, 1.0, 0.01) : si.smoo;
shimmerManual = hslider("sympathetic-strings/[6]Shimmer [style:knob]", 0.30, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("sympathetic-strings/[7]Width [style:knob]", 0.70, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("sympathetic-strings/[8]Mix [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isSitar = (presetMode >= 0.5) * (presetMode < 1.5);
isHarp = (presetMode >= 1.5) * (presetMode < 2.5);
isDrone = presetMode >= 2.5;

selectPreset(manual, sitar, harp, drone) =
  manual * isManual +
  sitar * isSitar +
  harp * isHarp +
  drone * isDrone;

// Key and chord stay with the manual menus; presets only shape the strings.
key = keyManual;
chord = int(selectPreset(chordManual, 6, chordManual, 3));
resonance = selectPreset(resonanceManual, 0.70, 0.62, 0.86);
bright = selectPreset(brightManual, 0.78, 0.48, 0.40);
excite = selectPreset(exciteManual, 0.66, 0.42, 0.55);
shimmer = selectPreset(shimmerManual, 0.20, 0.45, 0.60);
width = selectPreset(widthManual, 0.60, 0.85, 0.90);
mix = selectPreset(mixManual, 0.40, 0.36, 0.48);

process = _,_ : stringsStereo
with {
  maxDelay = 8192;
  nStrings = 6;

  // Root sits between C2 and B2 so the bank lives under and around the guitar.
  rootHz = 65.406 * pow(2.0, key / 12.0);

  interval(v) = ba.selectn(7, chord,
    ba.take(v + 1, (0, 4, 7, 12, 16, 19)),
    ba.take(v + 1, (0, 3, 7, 12, 15, 19)),
    ba.take(v + 1, (0, 5, 7, 12, 17, 19)),
    ba.take(v + 1, (0, 7, 12, 19, 24, 31)),
    ba.take(v + 1, (0, 4, 7, 11, 16, 23)),
    ba.take(v + 1, (0, 3, 7, 10, 15, 22)),
    ba.take(v + 1, (0, 7, 12, 14, 19, 24)));

  t60 = 0.4 * pow(30.0, resonance);
  dampHz = 1500.0 + bright * bright * 12000.0;

  // Karplus-Strong style string: fractional delay loop with damping and loss.
  string(v, x) = (+(x) : de.fdelay3(maxDelay, period) : damp) ~ *(g) : *(norm)
  with {
    drift = os.osc(0.11 + v * 0.037) * shimmer * 0.004 + no.lfnoise(0.7 + v * 0.3) * shimmer * 0.0025;
    f = rootHz * pow(2.0, interval(v) / 12.0) * (1.0 + drift);
    period = max(2.0, min(float(maxDelay - 4), ma.SR / f - 1.0));
    g = pow(0.001, (period / ma.SR) / t60);
    damp = fi.lowpass(1, dampHz);
    norm = sqrt(1.0 - g * g) * 3.0;
  };

  stringsStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5 : fi.highpass(2, 90.0);
    pick = max(0.0, mono - (mono : fi.lowpass(1, 1500.0)));
    drive = mono * (0.4 + excite * 1.2) + pick * excite * 2.5;
    exciter = ma.tanh(drive) * 0.6;

    voices = par(v, nStrings, string(v, exciter));
    pan(v) = 0.5 + width * 0.45 * (2.0 * (v % 2) - 1.0) * (0.6 + 0.4 * (v / (nStrings - 1)));
    wetL = voices : par(v, nStrings, *(1.0 - pan(v))) :> _ : fi.highpass(1, 70.0) : ma.tanh;
    wetR = voices : par(v, nStrings, *(pan(v))) :> _ : fi.highpass(1, 70.0) : ma.tanh;

    outL = inL * (1.0 - mix * 0.4) + wetL * mix;
    outR = inR * (1.0 - mix * 0.4) + wetR * mix;
  };
};
