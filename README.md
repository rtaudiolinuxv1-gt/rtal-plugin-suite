# RTAL Plugin Suite (RTAudioLinux)

This repository contains all the RTAL guitar plugin projects into one build system.

Good plugins enabled by default:
- rtal-guitar-shadow
- rtal-In_Bloom
- rtal-live-forever
- rtal-mestophelies

Prerelease plugins available via explicit CMake options:
- rtal-dynamic-distortion
- rtal-crystal-pluck
- rtal-shite_amp
- rtal-silkcut-choir
- rtal-dreams-of-electric-cabinets
- rtal-tape-ghost
- rtal-orbit-phaser
- rtal-barberpole-shift
- rtal-sympathetic-strings
- rtal-glitter-grains
- rtal-leslie-weather
- rtal-backwards-sunday
- rtal-drip-tank
- rtal-sub-orbit
- rtal-vowel-mouth
- rtal-cathedral-shimmer
- rtal-stutter-gate
- rtal-envelope-yeti
- rtal-velvet-fuzz
- rtal-brownface-pulse
- rtal-pixel-rot
- rtal-glass-squeeze
- rtal-tri-chorus
- rtal-jet-wash
- rtal-twin-harmony
- rtal-attack-sculpt
- rtal-cassette-dream
- rtal-moon-ring
- rtal-rhythm-echo
- rtal-ice-age
- rtal-fold-space
- rtal-violin-swell
- rtal-mirror-detune
- rtal-crybaby-ghost
- rtal-whammy-dive
- rtal-plate-glow
- rtal-silence-keeper
- rtal-split-drive
- rtal-am-radio
- rtal-power-cut
- rtal-step-ladder
- rtal-orbit-3d
- rtal-organ-donor
- rtal-digital-dust
- rtal-firefly-taps
- rtal-brickwall
- rtal-air-lift
- rtal-eighty-gate
- rtal-crystal-echo
- rtal-fet-grab
- rtal-twelve-string
- rtal-endless-stair
- rtal-loop-lab
- rtal-coral-buzz
- rtal-synth-ghost
- rtal-acoustic-body
- rtal-slide-scoop
- rtal-stereo-sculpt
- rtal-tone-carver
- rtal-harmonic-forge
- rtal-chord-vocoder
- rtal-abbey-adt
- rtal-beat-repeat
- rtal-photocell-vibe
- rtal-velvet-hall
- rtal-snap-tune
- rtal-dub-station
- rtal-green-mile
- rtal-treble-boost
- rtal-lorenz-drift
- rtal-hum-killer
- rtal-needle-tuner
- rtal-hush-band
- rtal-tweed-glow
- rtal-skip-scratch
- rtal-inverse-cathedral
- rtal-gamelan-bells
- rtal-phase-mod
- rtal-pick-tamer
- rtal-passing-train
- rtal-cloud-bank
- rtal-human-tune

## New effects at a glance

Each plugin has its own README with a description of how it works, every control and the factory presets.

### Delay & echo

| Plugin | What it does |
| --- | --- |
| [`rtal-tape-ghost`](plugins/rtal-tape-ghost/README.md) | Three-head tape echo with wow, flutter, saturation and aging tape. |
| [`rtal-backwards-sunday`](plugins/rtal-backwards-sunday/README.md) | Reverse delay with crossfaded twin heads, octave-up reverse mode and feedback. |
| [`rtal-rhythm-echo`](plugins/rtal-rhythm-echo/README.md) | Tempo-synced ping-pong echo that ducks while you play and blooms when you stop. |
| [`rtal-digital-dust`](plugins/rtal-digital-dust/README.md) | Degrading digital delay: every repeat is re-crushed, so echoes crumble into bit dust. |
| [`rtal-firefly-taps`](plugins/rtal-firefly-taps/README.md) | Eight-tap scattered delay with rhythmic tap patterns, swelling or fading tap shapes and stereo spread. |
| [`rtal-crystal-echo`](plugins/rtal-crystal-echo/README.md) | Pitch-climbing echo: every repeat is transposed again, so echoes rise or fall in octaves, fifths or fourths. |
| [`rtal-glitter-grains`](plugins/rtal-glitter-grains/README.md) | Eight-voice granular cloud delay with pitch sets, reverse grains and feedback. |
| [`rtal-loop-lab`](plugins/rtal-loop-lab/README.md) | Stereo looper with record, overdub with fading layers, play/stop, clear, half-speed and reverse playback. |
| [`rtal-beat-repeat`](plugins/rtal-beat-repeat/README.md) | Performance beat repeat: hold the switch to loop the last slice in time, with decay and falling-pitch glitch. |
| [`rtal-dub-station`](plugins/rtal-dub-station/README.md) | Dub echo station: throw switch, sweepable loop filter, runaway feedback and a spring tank, all for live dubbing. |
| [`rtal-skip-scratch`](plugins/rtal-skip-scratch/README.md) | Skipping CD glitch: random jumps back in time, reversed fragments and returns to live, with click-free crossfades. |

### Reverb & ambience

| Plugin | What it does |
| --- | --- |
| [`rtal-cathedral-shimmer`](plugins/rtal-cathedral-shimmer/README.md) | Shimmer reverb: a large hall whose tail is pitch-shifted back into itself. |
| [`rtal-drip-tank`](plugins/rtal-drip-tank/README.md) | Three-spring reverb tank with dispersive chirp, dwell drive and surf drip. |
| [`rtal-plate-glow`](plugins/rtal-plate-glow/README.md) | Dattorro plate reverb with pre-delay, input shimmer modulation, ducking and tilt EQ. |
| [`rtal-eighty-gate`](plugins/rtal-eighty-gate/README.md) | Eighties gated reverb and reverse-gate: a huge room chopped off by a gate keyed from your playing. |
| [`rtal-ice-age`](plugins/rtal-ice-age/README.md) | Infinite-sustain freeze pad: captures each new chord into a frozen tank and crossfades between layers. |
| [`rtal-sympathetic-strings`](plugins/rtal-sympathetic-strings/README.md) | Bank of tuned sympathetic strings that ring along with your playing in a chosen key and chord. |
| [`rtal-velvet-hall`](plugins/rtal-velvet-hall/README.md) | Lush modulated hall: eight-line feedback delay network with early reflections, bloom and chorused tail. |
| [`rtal-inverse-cathedral`](plugins/rtal-inverse-cathedral/README.md) | Reverse reverb: a big hall's tail is cut into windows and played backwards, so every phrase swells up out of nothing. |
| [`rtal-cloud-bank`](plugins/rtal-cloud-bank/README.md) | One-knob ambient machine: modulated echoes into a shimmering diffuse tank, with a freeze switch. |

### Modulation

| Plugin | What it does |
| --- | --- |
| [`rtal-orbit-phaser`](plugins/rtal-orbit-phaser/README.md) | Stereo 4/6/8/12-stage phaser with feedback, envelope sweep and orbiting LFOs. |
| [`rtal-tri-chorus`](plugins/rtal-tri-chorus/README.md) | Three-voice BBD-style chorus and string ensemble with dual LFOs, vibrato mode and stereo spread. |
| [`rtal-jet-wash`](plugins/rtal-jet-wash/README.md) | Through-zero tape flanger with classic mode, bipolar feedback and LFO or envelope sweep. |
| [`rtal-endless-stair`](plugins/rtal-endless-stair/README.md) | Barberpole flanger: a Shepard-style sweep that rises or falls forever without ever resetting. |
| [`rtal-leslie-weather`](plugins/rtal-leslie-weather/README.md) | Rotary speaker with separate horn and drum inertia, Doppler, tube drive and stereo mics. |
| [`rtal-brownface-pulse`](plugins/rtal-brownface-pulse/README.md) | Harmonic, classic and panning tremolo with morphing LFO shape and pick-reactive rate. |
| [`rtal-mirror-detune`](plugins/rtal-mirror-detune/README.md) | Studio micro-pitch doubler: mirrored detune and short delays for instant width, with mono-safe lows. |
| [`rtal-barberpole-shift`](plugins/rtal-barberpole-shift/README.md) | Bode-style frequency shifter with a delayed feedback loop for endless barberpole spirals. |
| [`rtal-moon-ring`](plugins/rtal-moon-ring/README.md) | Ring modulator with a pitch-tracked carrier that stays musical, plus fixed and swept modes. |
| [`rtal-orbit-3d`](plugins/rtal-orbit-3d/README.md) | Binaural spatializer for headphones: the guitar orbits your head using interaural time, level and shadow cues. |
| [`rtal-photocell-vibe`](plugins/rtal-photocell-vibe/README.md) | Photocell vibe: four staggered phase stages driven by a lagging lamp, for that throbbing chorus/vibrato. |
| [`rtal-abbey-adt`](plugins/rtal-abbey-adt/README.md) | Artificial double tracking: a varispeed tape copy wanders behind your part, or swoops into tape flanging. |
| [`rtal-lorenz-drift`](plugins/rtal-lorenz-drift/README.md) | Chaotic modulator: a Lorenz attractor steers a resonant filter, pitch wobble and stereo position, never repeating. |
| [`rtal-passing-train`](plugins/rtal-passing-train/README.md) | Doppler fly-by: your guitar races past the listener along a track, with true Doppler pitch, distance and air absorption. |

### Pitch & harmony

| Plugin | What it does |
| --- | --- |
| [`rtal-twin-harmony`](plugins/rtal-twin-harmony/README.md) | Two-voice diatonic harmonizer: tracks your pitch and adds harmonies that stay in key. |
| [`rtal-whammy-dive`](plugins/rtal-whammy-dive/README.md) | Expression pitch shifter for whammy bends, dive bombs and harmonies, with a momentary kick switch. |
| [`rtal-sub-orbit`](plugins/rtal-sub-orbit/README.md) | Analog-style flip-flop octaver with one and two octaves down plus rectified octave up. |
| [`rtal-organ-donor`](plugins/rtal-organ-donor/README.md) | Polyphonic guitar-to-organ: drawbar-style octave and quint stack with key-click percussion, sustain and scanner vibrato. |
| [`rtal-twelve-string`](plugins/rtal-twelve-string/README.md) | Twelve-string simulator: octave courses on the low strings, detuned unison courses and pick-timing spread. |
| [`rtal-slide-scoop`](plugins/rtal-slide-scoop/README.md) | Automatic pitch gestures: every note scoops up into pitch, dives in from above, or falls off as it decays. |
| [`rtal-synth-ghost`](plugins/rtal-synth-ghost/README.md) | Monophonic guitar synth: tracks your pitch and plays a saw/square oscillator through an enveloped ladder filter. |
| [`rtal-coral-buzz`](plugins/rtal-coral-buzz/README.md) | Electric sitar: a buzzing bridge whose bright jawari sweep climbs through the harmonics as each note decays. |
| [`rtal-chord-vocoder`](plugins/rtal-chord-vocoder/README.md) | Sixteen-band vocoder: your guitar articulates a synth chord pad, fixed in a key or following the note you play. |
| [`rtal-snap-tune`](plugins/rtal-snap-tune/README.md) | Scale-snapping pitch correction for single-note lines: from gentle tuning help to the hard robotic snap. |
| [`rtal-gamelan-bells`](plugins/rtal-gamelan-bells/README.md) | Modal resonator: each picked note strikes a tuned bell, gamelan gong, glass or marimba bar that rings at your pitch. |
| [`rtal-phase-mod`](plugins/rtal-phase-mod/README.md) | FM guitar: audio-rate phase modulation locked to your pitch, for DX-style bells, brass and metallic clangs. |
| [`rtal-human-tune`](plugins/rtal-human-tune/README.md) | Dynamic pitch correction that keeps the player human: a wandering reference around A440, per-note imperfection and vibrato-safe tracking, or a perfect A440 snap. |

### Filter & wah

| Plugin | What it does |
| --- | --- |
| [`rtal-envelope-yeti`](plugins/rtal-envelope-yeti/README.md) | Envelope filter / auto-wah with state-variable and ladder modes, up or down sweeps. |
| [`rtal-crybaby-ghost`](plugins/rtal-crybaby-ghost/README.md) | Wah pedal with an automatable treadle plus LFO and envelope 'ghost foot' modes, in three voicings. |
| [`rtal-vowel-mouth`](plugins/rtal-vowel-mouth/README.md) | Talkbox-style formant filter that morphs through A-E-I-O-U from a knob, LFO or pick envelope. |
| [`rtal-step-ladder`](plugins/rtal-step-ladder/README.md) | Tempo-synced 16-step sequenced ladder filter with glide, accent envelope and drive. |

### Drive & texture

| Plugin | What it does |
| --- | --- |
| [`rtal-tweed-glow`](plugins/rtal-tweed-glow/README.md) | Tweed-style small amp: two triode stages, simple tone control, saggy push-pull power section and a 1x12 speaker. |
| [`rtal-green-mile`](plugins/rtal-green-mile/README.md) | Mid-hump overdrive: only the mids and highs are driven into soft diode clipping, keeping lows tight and notes clear. |
| [`rtal-treble-boost`](plugins/rtal-treble-boost/README.md) | Germanium-style range booster: a single-transistor treble, mid or full-range boost with gentle, lopsided grit. |
| [`rtal-velvet-fuzz`](plugins/rtal-velvet-fuzz/README.md) | Two-stage fuzz with bias starve, sputter gate, octave fuzz and a scoopable tone stack, using anti-aliased clipping. |
| [`rtal-split-drive`](plugins/rtal-split-drive/README.md) | Three-band multiband distortion: tight lows, crunchy mids and fizzy highs driven separately. |
| [`rtal-fold-space`](plugins/rtal-fold-space/README.md) | West-coast wavefolder distortion with anti-aliased sine folding, symmetry, dynamics and resonant colour filter. |
| [`rtal-pixel-rot`](plugins/rtal-pixel-rot/README.md) | Bit crusher and sample-rate reducer with clock jitter, glitch freezes and tone shaping. |
| [`rtal-cassette-dream`](plugins/rtal-cassette-dream/README.md) | Lo-fi cassette deck: wow, flutter, tape saturation, worn bandwidth, dropouts and hiss. |
| [`rtal-am-radio`](plugins/rtal-am-radio/README.md) | Old radio and telephone voice: band-limited speaker, tube grit, tuning drift, static and crackle. |
| [`rtal-harmonic-forge`](plugins/rtal-harmonic-forge/README.md) | Harmonic mixer: Chebyshev waveshaping adds exactly the 2nd, 3rd, 4th and 5th harmonics you dial in. |

### Dynamics

| Plugin | What it does |
| --- | --- |
| [`rtal-glass-squeeze`](plugins/rtal-glass-squeeze/README.md) | Opto-flavoured guitar compressor with program-dependent release, soft knee, sidechain filter and parallel blend. |
| [`rtal-fet-grab`](plugins/rtal-fet-grab/README.md) | FET-style peak compressor with ultra-fast attack, ratio buttons including all-buttons-in, and gain-dependent colour. |
| [`rtal-brickwall`](plugins/rtal-brickwall/README.md) | Lookahead brickwall limiter with drive, ceiling, adaptive release, stereo link and a final safety clip. |
| [`rtal-silence-keeper`](plugins/rtal-silence-keeper/README.md) | High-gain noise gate with hysteresis, hold, lookahead, sidechain filtering and a range control. |
| [`rtal-attack-sculpt`](plugins/rtal-attack-sculpt/README.md) | Level-independent transient shaper: boost or soften pick attack and sustain separately. |
| [`rtal-violin-swell`](plugins/rtal-violin-swell/README.md) | Automatic volume swell: every new note fades in from silence, with an optional ambient echo wash. |
| [`rtal-hush-band`](plugins/rtal-hush-band/README.md) | Three-band downward expander: quietly pushes down hiss and hum in each band without chopping your notes like a gate. |
| [`rtal-pick-tamer`](plugins/rtal-pick-tamer/README.md) | Two-band dynamic EQ: cuts harsh pick click and boomy low notes only when they jump out, leaving the rest alone. |

### Rhythm & performance

| Plugin | What it does |
| --- | --- |
| [`rtal-stutter-gate`](plugins/rtal-stutter-gate/README.md) | Sixteen-step rhythmic slicer with pattern bank, swing, duty and stereo ping-pong. |
| [`rtal-power-cut`](plugins/rtal-power-cut/README.md) | Tape stop and spin-up: flick the switch and the deck grinds to a halt, release it and the motor winds back up. |

### Tone & utility

| Plugin | What it does |
| --- | --- |
| [`rtal-tone-carver`](plugins/rtal-tone-carver/README.md) | Guitar parametric EQ: cuts, shelves and two sweepable mid bands, with guitar-tuned factory curves. |
| [`rtal-air-lift`](plugins/rtal-air-lift/README.md) | Harmonic exciter: generates fresh upper harmonics for air and saturated low harmonics for body. |
| [`rtal-acoustic-body`](plugins/rtal-acoustic-body/README.md) | Electric-to-acoustic simulator: wooden body resonances, top brightness, pick attack and a small room. |
| [`rtal-stereo-sculpt`](plugins/rtal-stereo-sculpt/README.md) | Mid/side stereo imager: width, bass mono, side brightness, Haas widening for mono sources and balance. |
| [`rtal-hum-killer`](plugins/rtal-hum-killer/README.md) | Mains hum and hiss remover: notches 50/60 Hz and its harmonics, plus a dynamic hiss filter for the quiet bits. |
| [`rtal-needle-tuner`](plugins/rtal-needle-tuner/README.md) | Chromatic tuner: note, octave and cents meters with adjustable reference pitch and a mute switch for silent tuning. |
## Configure

Release is the default:

bash
cmake -S . -B build


Example with explicit options:

bash
cmake -S . -B build \
  -DRTAL_BUILD_MODE=RELEASE \
  -DBUILD_LV2=ON \
  -DBUILD_STANDALONE=ON \
  -DBUILD_VST2=ON \
  -DVST2_SDK_DIR=/home/jim/PLUGINS/vstsdk2.4 \
  -DRTAL_EXTRA_CFLAGS="-O2 -pipe" \
  -DPORTABLE_X86_64=ON \
  -DENABLE_PRERELEASE_RTAL_CRYSTAL_PLUCK=ON


Debug example:

bash
cmake -S . -B build -DRTAL_BUILD_MODE=DEBUG


## Build

bash
cmake --build build


Create a combined distributable package:

bash
cmake --build build --target rtal-suite-package


## Notes

- BUILD_LV2, BUILD_STANDALONE, and BUILD_VST2 toggle formats globally.
- PORTABLE_X86_64=ON adds generic x86_64 codegen flags for broader compatibility.
- VST2_SDK_DIR is the correct CMake variable for the VST2 SDK path.
- Combined release packages are written under release/.

## Testing and adding plugins

`scripts/smoke-test.sh` compiles each plugin's DSP, runs its license audit and renders a synthetic
guitar performance (melody, strums, palm mutes, full-scale hits and a long silent tail) through the
defaults, every factory preset, the all-min/all-max corners and twelve seeded random states. It fails
on non-finite output, runaway gain, silent output, DC offset or a tail that never decays, and reports
CPU use per state. It needs `faust` and a C++17 compiler.

```bash
scripts/smoke-test.sh                       # every plugin
scripts/smoke-test.sh rtal-tape-ghost       # selected plugins
WAV_DIR=renders scripts/smoke-test.sh       # also write default/preset renders
```

A plugin can relax one check where the behaviour is intentional, with Faust metadata:
`declare rtal_smoke "allow-quiet";` (swells and gates), `"allow-sustain"` (infinite freezes) or
`"allow-gain"` (EQ/utility gain at extreme settings; defaults and presets are still checked).

The compiled harness also has a probe mode for checking behaviour by ear or by spectrum:

```bash
build-smoke/rtal-barberpole-shift/harness --probe sine:440 --set Shift=0.8 --set Mix=1 --out probe.wav
```

Probe inputs are `sine:<Hz>`, `burst:<Hz>` (one second of tone, then silence), `guitar`, `impulse` and
`noise`; `--set` takes a parameter label or full path.

`scripts/new-plugin.sh rtal-new-name` scaffolds a new plugin directory with the shared CMake, export,
install, packaging and license-audit scripts; write `src/<stem>.dsp` and `README.md`, then add the
plugin to the root `CMakeLists.txt`.
