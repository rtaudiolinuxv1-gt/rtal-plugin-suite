# rtal-acoustic-body

`rtal-acoustic-body` makes an electric guitar sound acoustic: wooden body resonances, top brightness, pick attack and a small room.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

First the magnetic pickup's mid hump is scooped out. Then three resonant body modes per guitar type are added: the air (Helmholtz) resonance, the main top mode and a back mode. A top-plate brightness shelf and a transient detector restore the bright pick attack an acoustic has. Nylon mode rolls off the top for a classical voice, and a few early reflections place it in a small room.

## Controls

- `Body`: Dreadnought, Parlour, Jumbo or Nylon Classical.
- `Body Resonance`: strength of the body modes.
- `Top`: top-plate brightness.
- `Pick Attack`: transient brightness on each pick.
- `Magnetic Scoop`: removal of the electric pickup's mid hump.
- `Room`: small-room reflections.
- `Level`: output level.
- `Mix`: dry/wet blend.

## Factory presets

- `Dreadnought`: full, balanced steel-string.
- `Parlour`: small, bright, boxy parlour guitar.
- `Jumbo Strummer`: big, resonant strummer.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-acoustic-body-lv2
cmake --build build --target rtal-acoustic-body-standalone
cmake --build build --target rtal-acoustic-body-vst2
cmake --build build --target rtal-acoustic-body-package
```
