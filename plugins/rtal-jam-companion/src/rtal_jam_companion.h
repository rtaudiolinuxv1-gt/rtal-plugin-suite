// Engine for rtal-jam-companion: listens to the guitar for tempo, beat and
// chords so the Faust side can play drums and a bass line along with it.
//
// Tempo and beat come from rtal_tempo.h; chords from rtal_chord_detect.h on a
// 4096-point spectrum every 1024 samples. Each chord change is reported to the
// tempo tracker as downbeat evidence, because chords usually change on the
// first beat of a bar. 'Active' says whether the guitar has been played in
// the last couple of bars, so the band can stop when the player stops.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_JAM_COMPANION_H
#define RTAL_JAM_COMPANION_H

#include "rtal_chord_detect.h"
#include "rtal_tempo.h"

namespace rtal {

struct JamCompanionEngine {
    static const int kN = 4096;
    static const int kHop = 1024;

    TempoTracker tracker;
    Stft stft;
    Analysis ana;
    ChordDetector chords;
    int lastChord = -1;
    float sinceOnset = 1e9f;
    float sr = 48000.0f;

    void reset()
    {
        tracker.reset();
        stft.setup(kN, kHop, 0);
        ana.setup(kN, kHop);
        chords.reset();
        lastChord = -1;
        sinceOnset = 1e9f;
    }

    float process(float x, float rate, int tempoMode, float manualBpm, float minBpm, float maxBpm, float sensitivity,
                  int chordMode, int manRoot, int manQuality)
    {
        if (!(rate > 1000.0f)) rate = 48000.0f;
        sr = rate;
        if (tracker.push(x, rate, tempoMode, manualBpm, minBpm, maxBpm, sensitivity)) {
            if (tracker.onsetFlag) sinceOnset = 0.0f;
            else sinceOnset += float(TempoTracker::kHop) / rate;
        }
        if (stft.push(x)) {
            ana.analyse(stft.re.data(), stft.im.data(), rate);
            const float floorMag = std::pow(10.0f, (-50.0f - 40.0f * sensitivity) / 20.0f);
            ana.findPeaks(floorMag, 50.0f, 50.0f, 5000.0f, rate);
            chords.update(ana.peaks, 440.0f, float(kHop) / rate, floorMag);
            if (chordMode == 1) { chords.root = ((manRoot % 12) + 12) % 12; chords.quality = std::min(std::max(manQuality, 0), kNumQualities - 1); }
            const int c = chords.root * 16 + chords.quality;
            if (c != lastChord) {
                if (lastChord >= 0 && chordMode == 0) tracker.chordChanged();
                lastChord = c;
            }
        }
        return tracker.barPosition();
    }

    // Seconds since the guitar was last picked.
    float idleSeconds() const { return sinceOnset; }
};

typedef Pool<JamCompanionEngine, 32> JamCompanionPool;

}  // namespace rtal

static inline int rtal_jc_open_fn() { return rtal::JamCompanionPool::open(); }
#define rtal_jc_open rtal_jc_open_fn()

// Returns the bar position 0..4 (beats).
static inline float rtal_jc_process(int h, float x, float sr, int tempoMode, float manualBpm, float minBpm,
                                    float maxBpm, float sensitivity, int chordMode, int manRoot, int manQuality)
{
    rtal::DenormalGuard guard;
    return rtal::JamCompanionPool::slot(h)->process(x, sr, tempoMode, manualBpm, minBpm, maxBpm, sensitivity,
                                                    chordMode, manRoot, manQuality);
}

// which: 0 BPM, 1 chord root (0-11), 2 chord quality, 3 seconds since the
// last pick, 4 tempo confidence. 'tie' orders the call after process.
static inline float rtal_jc_info(int h, int which, float tie)
{
    (void)tie;
    const rtal::JamCompanionEngine* e = rtal::JamCompanionPool::slot(h);
    switch (which) {
    case 0: return e->tracker.bpm;
    case 1: return float(e->chords.root);
    case 2: return float(e->chords.quality);
    case 3: return std::min(e->idleSeconds(), 1000.0f);
    default: return e->tracker.confidence;
    }
}

#endif
