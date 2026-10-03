// Engine for rtal-groove-lock: wraps the tempo tracker (rtal_tempo.h) so the
// Faust effects can follow the player's own tempo and beat.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_GROOVE_LOCK_H
#define RTAL_GROOVE_LOCK_H

#include "rtal_tempo.h"

namespace rtal {

struct GrooveLockEngine {
    TempoTracker tracker;
    void reset() { tracker.reset(); }
};

typedef Pool<GrooveLockEngine, 32> GrooveLockPool;

}  // namespace rtal

static inline int rtal_gl_open_fn() { return rtal::GrooveLockPool::open(); }
#define rtal_gl_open rtal_gl_open_fn()

// Advances the tracker by one sample; returns the bar position 0..4 (beats).
// mode: 0 follow tempo and beat, 1 hold tempo (beat still locks), 2 manual tempo.
static inline float rtal_gl_process(int h, float x, float sr, int mode, float manualBpm, float minBpm, float maxBpm,
                                    float sensitivity)
{
    rtal::DenormalGuard guard;
    if (!(sr > 1000.0f)) sr = 48000.0f;
    rtal::TempoTracker& t = rtal::GrooveLockPool::slot(h)->tracker;
    t.push(x, sr, mode, manualBpm, minBpm, maxBpm, sensitivity);
    return t.barPosition();
}

// which: 0 tempo in BPM, 1 lock confidence 0..1. 'tie' orders the call after process.
static inline float rtal_gl_info(int h, int which, float tie)
{
    (void)tie;
    const rtal::TempoTracker& t = rtal::GrooveLockPool::slot(h)->tracker;
    return which == 0 ? t.bpm : t.confidence;
}

#endif
