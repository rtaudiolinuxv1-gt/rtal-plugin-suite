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
