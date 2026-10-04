# rtal-cross-synth

`rtal-cross-synth` is a cross-synthesis effect. Your guitar takes on the texture of rain, wind, whispers, crackle, bubbles, metal, white noise or a second input, while keeping its own notes.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Textures.** Faust synthesises the texture: raindrops (random resonant ticks with hiss), gusting wind, a breathy formant whisper, vinyl/fire crackle, rising bubbles, white noise, or struck inharmonic metal. Alternatively, set the source to *Right Input*: the guitar is taken from the left input and the texture from the right, for example a voice or a drum loop.

**Cross-synthesis.** The engine (`rtal_cross_synth.h`) splits the guitar and the texture into a smooth spectral envelope and the fine structure riding on it, using 2048-point FFTs. The output magnitude is built from three factors:
- the guitar spectrum, which `Pitch Keep` blends towards the guitar's envelope only;
- the texture's fine detail, set by `Imprint`;
- optionally the texture's tone colour, set by `Texture Colour`.

`Texture Phase` blends the phase from the guitar's (pitch stays exact) to the texture's (grain and motion). The texture's own rhythm, such as drops and gusts, is kept. The output is matched to the guitar's loudness frame by frame.

**Stereo.** Two texture streams with different random seeds make the result stereo. Latency is about 43 ms.

## Controls

- `Factory Preset`: Manual keeps every control live.
- `Source`: Rain, Wind, Whisper, Crackle, Bubbles, White Noise, Metal or Right Input.
- `Texture Rate`: Density or speed of the texture.
- `Texture Pitch`: Register of the synthesised texture.
- `Imprint`: How much of the texture's fine detail is pressed into the guitar.
- `Pitch Keep`: 1 keeps the guitar's notes and harmonics exactly; 0 keeps only its tone envelope, so the texture takes over.
- `Texture Colour`: How much of the texture's tonal balance is applied.
- `Texture Phase`: Phase from the guitar (clear pitch) or the texture (grain).
- `Envelope Smoothing`: Resolution of the envelope/detail split.
- `Cross Level / Dry Level / Raw Texture`: Mix; Raw Texture lets you hear the texture itself.

## Factory presets

- `Manual`: Every control as set by hand.
- `Rain Guitar`: Notes made of raindrops.
- `Whisper Strings`: Breathy, voice-like guitar.
- `Wind Ghost`: The guitar blown through the wind.
- `Bubble Synth`: Bubbling, pitched blips.
- `Iron Bells`: Metallic, bell-like ringing.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-cross-synth-lv2
cmake --build build --target rtal-cross-synth-standalone
cmake --build build --target rtal-cross-synth-vst2
cmake --build build --target rtal-cross-synth-package
```
