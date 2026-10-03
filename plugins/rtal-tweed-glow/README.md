# rtal-tweed-glow

`rtal-tweed-glow` is a tweed-style small amp: two triode stages, a simple tone control, a saggy push-pull power section and a 1x12 speaker.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

The first triode stage blends a normal and a bright channel and clips asymmetrically, as a triode does when its grid starts conducting. A single treble-cut tone control and a second triode stage follow. The push-pull power section has supply sag: hard playing pulls the rails down, compressing and softening the attack like an old rectifier. A 1x12 alnico-style speaker voicing can be blended out to feed your own cab simulator.

## Controls

- `Volume`: first-stage drive.
- `Tone`: treble cut.
- `Bright Channel`: normal versus bright channel blend.
- `Sag`: power supply sag and compression.
- `Power Drive`: power section drive.
- `Speaker`: speaker voicing amount; 0 bypasses it.
- `Level`: output level.

## Factory presets

- `Clean Sparkle`: bright, low-volume clean.
- `Edge of Breakup`: just breaking up when you dig in.
- `Cranked Tweed`: everything up, saggy and saturated.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-tweed-glow-lv2
cmake --build build --target rtal-tweed-glow-standalone
cmake --build build --target rtal-tweed-glow-vst2
cmake --build build --target rtal-tweed-glow-package
```
