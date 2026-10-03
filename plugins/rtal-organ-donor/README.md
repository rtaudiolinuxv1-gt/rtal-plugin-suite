# rtal-organ-donor

`rtal-organ-donor` turns guitar into organ: a polyphonic drawbar-style stack of octaves and a quint, with key-click percussion, organ-like sustain, scanner vibrato and drive.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Each drawbar is the whole guitar signal shifted by a fixed interval with a granular pitch shifter, so chords stay polyphonic: 16' is an octave down, 4' an octave up, 2 2/3' an octave and a fifth up, 2' two octaves up. A level-normalising sustain stage softens the pick and holds notes like organ keys, an onset detector fires a decaying percussion blip on the 4' and 2 2/3' drawbars, and a scanner-style modulated delay adds vibrato and chorus.

## Controls

- `Sub 16'`: octave down.
- `Fund 8'`: original pitch.
- `Octave 4'`: octave up.
- `Quint 2 2/3'`: octave and a fifth up.
- `Super 2'`: two octaves up.
- `Percussion`: decaying key-click blip on each new note.
- `Sustain`: organ-like hold and pick softening.
- `Vibrato`: scanner vibrato/chorus depth.
- `Drive`: tube-style overdrive.
- `Mix`: dry/wet blend.

## Factory presets

- `Gospel Full`: all drawbars out with percussion and drive.
- `Church Flute`: soft, sustained flute stops.
- `Garage Combo`: bright, buzzy combo organ with heavy vibrato.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-organ-donor-lv2
cmake --build build --target rtal-organ-donor-standalone
cmake --build build --target rtal-organ-donor-vst2
cmake --build build --target rtal-organ-donor-package
```
