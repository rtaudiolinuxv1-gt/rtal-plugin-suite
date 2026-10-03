# rtal-skip-scratch

`rtal-skip-scratch` is a skipping-CD glitch: random jumps back in time, reversed fragments and returns to live, all with click-free crossfades.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

A decision clock rolls the dice several times a second. When a skip happens, the idle one of two read heads is loaded with a new jump back into the recent past, sometimes playing backwards and sometimes snapping back to live, and the output crossfades to it. Playback is continuous from the jumped position, so you hear the stutters and time slips of a scratched disc rather than gated chops.

## Controls

- `Skip Rate`: how often skips happen.
- `Jump Range`: how far back a skip can jump, up to about 0.9 s.
- `Return Chance`: probability a skip returns to the live signal.
- `Reverse Chance`: probability a jump plays backwards.
- `Crossfade`: crossfade length between heads.
- `Mix`: dry/wet blend.

## Factory presets

- `Scratched Disc`: occasional short skips.
- `Broken Discman`: frequent, long jumps.
- `Reverse Flicker`: mostly reversed fragments.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-skip-scratch-lv2
cmake --build build --target rtal-skip-scratch-standalone
cmake --build build --target rtal-skip-scratch-vst2
cmake --build build --target rtal-skip-scratch-package
```
