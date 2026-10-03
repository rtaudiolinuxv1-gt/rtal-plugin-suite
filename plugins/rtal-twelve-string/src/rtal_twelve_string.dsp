import("stdfaust.lib");

declare name "rtal-twelve-string";
declare version "0.1.0";
declare author "rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare license "DOC-1.0";
declare copyright "(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com>";
declare description "Twelve-string simulator: octave courses on the low strings, detuned unison courses and pick-timing spread.";

presetMode = nentry("twelve-string/[0]Factory Preset [style:menu{'Manual':0;'Jangle Pop':1;'Folk Strum':2;'Psychedelic Chime':3}]", 0, 0, 3, 1);
octaveManual = hslider("twelve-string/[1]Octave Course [style:knob]", 0.55, 0.0, 1.0, 0.01) : si.smoo;
focusManual = hslider("twelve-string/[2]Octave Focus [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
unisonManual = hslider("twelve-string/[3]Unison Course [style:knob]", 0.45, 0.0, 1.0, 0.01) : si.smoo;
detuneManual = hslider("twelve-string/[4]Detune [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
lagManual = hslider("twelve-string/[5]Pick Lag [style:knob]", 0.35, 0.0, 1.0, 0.01) : si.smoo;
chimeManual = hslider("twelve-string/[6]Chime [style:knob]", 0.40, 0.0, 1.0, 0.01) : si.smoo;
widthManual = hslider("twelve-string/[7]Width [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;
mixManual = hslider("twelve-string/[8]Mix [style:knob]", 0.60, 0.0, 1.0, 0.01) : si.smoo;

isManual = presetMode < 0.5;
isJangle = (presetMode >= 0.5) * (presetMode < 1.5);
isFolk = (presetMode >= 1.5) * (presetMode < 2.5);
isChime = presetMode >= 2.5;

selectPreset(manual, jangle, folk, chime) =
  manual * isManual +
  jangle * isJangle +
  folk * isFolk +
  chime * isChime;

octave = selectPreset(octaveManual, 0.65, 0.50, 0.70);
focus = selectPreset(focusManual, 0.45, 0.35, 0.55);
unison = selectPreset(unisonManual, 0.50, 0.55, 0.40);
detune = selectPreset(detuneManual, 0.30, 0.40, 0.55);
lag = selectPreset(lagManual, 0.30, 0.45, 0.25);
chime = selectPreset(chimeManual, 0.65, 0.30, 0.80);
width = selectPreset(widthManual, 0.60, 0.50, 0.85);
mix = selectPreset(mixManual, 0.60, 0.55, 0.65);

process = _,_ : twelveStereo
with {
  // On a real 12-string only the lower courses carry an octave string, so the
  // octave voice is fed from the low-passed part of the guitar.
  focusHz = 400.0 * pow(5.0, focus);
  lagMs = 2.0 + lag * 14.0;
  cents = detune * 14.0;

  twelveStereo(inL, inR) = outL, outR
  with {
    mono = (inL + inR) * 0.5;
    lowCourses = mono : fi.lowpassLR4(focusHz);
    octaveVoice = lowCourses : ef.transpose(1024, 256, 12.0 + no.lfnoise(0.4) * cents * 0.004)
      : de.fdelay(4096, lagMs * 0.6 * 0.001 * ma.SR)
      : fi.highpass(1, 200.0);
    unisonUp = mono : ef.transpose(1536, 384, cents * 0.01) : de.fdelay(4096, lagMs * 0.001 * ma.SR);
    unisonDown = mono : ef.transpose(1536, 384, 0.0 - cents * 0.007) : de.fdelay(4096, lagMs * 1.4 * 0.001 * ma.SR);

    // Chime: the thin octave strings are bright and a little compressed.
    sparkle = fi.high_shelf(chime * 6.0, 2500.0);
    courseL = (octaveVoice * octave * (0.5 + width * 0.5) + unisonUp * unison) : sparkle;
    courseR = (octaveVoice * octave * (0.5 - width * 0.5) + unisonDown * unison) : sparkle;
    outL = inL * (1.0 - mix * 0.4) + courseL * mix * 0.9;
    outR = inR * (1.0 - mix * 0.4) + courseR * mix * 0.9;
  };
};
