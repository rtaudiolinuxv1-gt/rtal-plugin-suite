# rtal-endless-stair

`rtal-endless-stair` is a barberpole flanger: a Shepard-style sweep that rises or falls forever without ever resetting.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Three, four or six comb-filter voices each glide exponentially from a long to a short delay, so their notches climb, and fade in and out with raised-cosine windows staggered evenly around the cycle. As one voice fades out at the top, another is fading in at the bottom, so the ear hears a sweep that rises (or falls) forever.

## Controls

- `Direction`: Up or Down.
- `Rate`: time for one climb, 30 s down to 1.5 s.
- `Range`: sweep span in octaves.
- `Feedback`: comb resonance.
- `Voices`: 3, 4 or 6 overlapping voices.
- `Width`: stereo spread of the voices.
- `Mix`: dry/wet blend.

## Factory presets

- `Rising Forever`: classic endless rising flange.
- `Falling Jet`: endless falling jet sweep.
- `Slow Cathedral Stair`: very slow, wide six-voice climb.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-endless-stair-lv2
cmake --build build --target rtal-endless-stair-standalone
cmake --build build --target rtal-endless-stair-vst2
cmake --build build --target rtal-endless-stair-package
```
