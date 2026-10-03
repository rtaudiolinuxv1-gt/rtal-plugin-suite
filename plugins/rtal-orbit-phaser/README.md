# rtal-orbit-phaser

`rtal-orbit-phaser` is a stereo phaser with selectable 4, 6, 8 or 12 allpass stages, bipolar feedback, envelope-driven sweeps and independently orbiting left/right LFOs.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Each channel runs a cascade of first-order allpass stages around a feedback loop. The sweep combines a rounded-triangle LFO with an envelope follower, so the notches can breathe with picking dynamics. `Spread` offsets the right channel's LFO phase for a rotating stereo image.

## Controls

- `Stages`: 4, 6, 8 or 12 allpass stages (2, 3, 4 or 6 notches).
- `Rate`: LFO speed, 0.03 Hz to 9 Hz.
- `Depth`: LFO sweep range.
- `Center`: sweep center frequency.
- `Feedback`: bipolar: right of center for vocal peaks, left of center for hollow inverted notches.
- `Envelope`: amount the picking envelope pushes the sweep upward.
- `Spread`: stereo LFO phase offset.
- `Mix`: dry/wet blend; 0.5 gives the deepest notches.

## Factory presets

- `Script Ninety`: classic 4-stage script-logo style swirl.
- `Liquid Orbit`: slow 8-stage stereo sweep with strong feedback.
- `Jet Funk`: 12-stage envelope phaser with inverted feedback for funk rhythm parts.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-orbit-phaser-lv2
cmake --build build --target rtal-orbit-phaser-standalone
cmake --build build --target rtal-orbit-phaser-vst2
cmake --build build --target rtal-orbit-phaser-package
```
