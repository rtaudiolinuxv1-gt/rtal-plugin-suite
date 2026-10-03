# rtal-rhythm-echo

`rtal-rhythm-echo` is a tempo-synced ping-pong echo that ducks while you play and blooms when you stop.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

Two delay lines cross-feed each other so repeats bounce between the speakers, with adjustable ping-pong amount. An envelope follower ducks the echoes while you play and lets them swell in the gaps, keeping busy parts clear. Optional allpass diffusion smears each repeat a little more, and gentle modulation adds tape-like movement.

## Controls

- `BPM`: tempo, 40 to 240. Presets keep the tempo you set.
- `Division`: 1/4, dotted 1/8, 1/8, 1/4 triplet, 1/16 or dotted 1/4.
- `Feedback`: number of repeats.
- `Ping Pong`: 0 is parallel stereo echoes, 1 bounces fully between sides.
- `Duck`: how much the echoes step back while you play.
- `Diffuse`: allpass smear that grows with each repeat.
- `Tone`: feedback bandwidth.
- `Modulation`: subtle delay-time wobble.
- `Mix`: dry/wet blend.

## Factory presets

- `Dotted Eighth Stadium`: the classic dotted-eighth anthem echo.
- `Ducked Lead`: quarter-note echoes that stay out of the way of a busy lead.
- `Diffuse Bounce`: eighth-note ping-pong melting into a wash.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-rhythm-echo-lv2
cmake --build build --target rtal-rhythm-echo-standalone
cmake --build build --target rtal-rhythm-echo-vst2
cmake --build build --target rtal-rhythm-echo-package
```
