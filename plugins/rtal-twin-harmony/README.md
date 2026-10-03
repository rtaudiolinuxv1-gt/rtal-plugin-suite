# rtal-twin-harmony

`rtal-twin-harmony` is a two-voice diatonic harmonizer: it tracks the note you play and adds harmonies that stay in the chosen key and scale.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A pitch tracker estimates the played note, which is rounded to the nearest semitone and held between phrases. The note is located in the selected key and scale, moved the chosen number of scale steps, and the semitone difference drives a granular pitch shifter for each voice. A third above E in E minor is therefore a minor third (G) while a third above A is a minor third (C), exactly as a second guitarist would play it. `Humanize` adds slight timing and pitch drift so the voices sound like real doubles.

## Controls

- `Key`: tonic of the scale.
- `Scale`: Major, Natural Minor, Dorian, Mixolydian or Harmonic Minor.
- `Voice A`: interval for the first harmony voice: unison, third/fourth/fifth/sixth/octave up, third/fourth/sixth/octave down.
- `Voice B`: interval for the second harmony voice.
- `Level A`: first voice level.
- `Level B`: second voice level.
- `Humanize`: timing and pitch looseness of the harmonies.
- `Width`: stereo placement of the two voices.
- `Dry`: level of your original part.

## Factory presets

- `Twin Leads`: classic twin-guitar thirds. Uses the selected key and scale.
- `Power Stack`: fifth above and octave below.
- `Choir of Thirds`: thirds above and below, wide and humanized.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-twin-harmony-lv2
cmake --build build --target rtal-twin-harmony-standalone
cmake --build build --target rtal-twin-harmony-vst2
cmake --build build --target rtal-twin-harmony-package
```
