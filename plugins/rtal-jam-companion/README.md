# rtal-jam-companion

`rtal-jam-companion` is a drummer and bass player that listen to your tempo and chords and play along. They start when you start, stop when you stop, and change chords with you.

Release `0.1.0` is authored and maintained by `rtaudiolinux <rtaudiolinux.v1@gmail.com>`. Original project source is licensed under `DOC-1.0`.

## How it works

**Listening.** The engine (`rtal_jam_companion.h`) runs the same tempo and beat tracker as rtal-groove-lock (`rtal_tempo.h`) and the chord recogniser from rtal-chord-harmony (`rtal_chord_detect.h`). Every chord change is reported to the tempo tracker as downbeat evidence, because chords usually change on the first beat of a bar.

**The band.** Each style has sixteen-step patterns for kick, snare, closed and open hats and bass, with swing. `Complexity` adds ghost snares, extra sixteenth hats and a snare fill in the last bar of four, and `Humanize` varies the velocities. The kit is synthesised: a pitch-swept kick, a noise and tone snare, and closed and open hats, where a closed hat chokes the open one. The bass plays chord-aware notes (root, fifth, octave, third, seventh, with thirds and sevenths taken from the detected chord quality) through a ladder filter.

**Start and stop.** In *When I Play* mode the band starts and stops on bar lines: it plays while you have picked within the last bar and a half.

## Controls

- `Factory Preset`: Manual keeps every control live.
- `Style`: Rock, Funk, Shuffle, Half-Time, Ballad, Four on the Floor, Bossa or Punk.
- `Band Plays`: When I Play, Always, or Stopped.
- `Swing`: Delays every second sixteenth.
- `Complexity`: Ghost notes, extra hats and fills.
- `Humanize`: Velocity variation.
- `Tempo Source, Manual Tempo, Slowest / Fastest Tempo`: Tempo following (as in rtal-groove-lock).
- `Chord Source, Manual Root, Manual Chord`: Follow the chords you play or set one by hand.
- `Sensitivity`: How quiet the guitar can be and still be heard.
- `Drums / Drum Tone`: Kit level, decay and brightness.
- `Bass / Bass Tone / Bass Octave / Bass Note Length`: Bass level, filter, register and note length.
- `Guitar`: Level of your guitar in the output.
- `Heard meters`: Tempo, beat, chord root, chord quality, and whether the band is playing.

## Factory presets

- `Manual`: Every control as set by hand.
- `Rock Band`: Straight rock beat and eighth-note bass.
- `Funk Groove`: Syncopated kick, ghost snares, sixteenth hats and a busy bass.
- `Blues Shuffle`: Swung beat with a walking bass.
- `Indie Half-Time`: Half-time beat with sparse bass.
- `Bossa Lounge`: Bossa nova kick and rim pattern with a root-fifth bass.

## Build

```bash
cmake -S . -B build
cmake --build build
```

Useful targets:

```bash
cmake --build build --target rtal-jam-companion-lv2
cmake --build build --target rtal-jam-companion-standalone
cmake --build build --target rtal-jam-companion-vst2
cmake --build build --target rtal-jam-companion-package
```
