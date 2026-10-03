// Chord recognition from spectral peaks: a pitch-class profile (chroma) built
// from peak magnitudes, matched against chord templates with a bass-note bonus,
// time smoothing and hysteresis so the detected chord does not flicker.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_CHORD_DETECT_H
#define RTAL_CHORD_DETECT_H

#include "rtal_spectral_core.h"

namespace rtal {

// Chord qualities, in menu order.
enum { kMaj = 0, kMin, kDom7, kMaj7, kMin7, kSus2, kSus4, kDim, kAug, kPower, kNumQualities };

static inline int chordIntervals(int quality, int* out)
{
    static const int table[kNumQualities][5] = {
        {0, 4, 7, -1, -1}, {0, 3, 7, -1, -1}, {0, 4, 7, 10, -1}, {0, 4, 7, 11, -1}, {0, 3, 7, 10, -1},
        {0, 2, 7, -1, -1}, {0, 5, 7, -1, -1}, {0, 3, 6, -1, -1}, {0, 4, 8, -1, -1}, {0, 7, 12, -1, -1}};
    int n = 0;
    for (int i = 0; i < 5; ++i)
        if (table[quality][i] >= 0) out[n++] = table[quality][i] % 12;
    if (quality == kPower) n = 2;
    return n;
}

// Scale used for notes that are not chord tones (chord-scale theory).
static inline int chordScale(int quality, int* out)
{
    static const int ionian[7] = {0, 2, 4, 5, 7, 9, 11}, dorian[7] = {0, 2, 3, 5, 7, 9, 10},
                     mixo[7] = {0, 2, 4, 5, 7, 9, 10}, locrian[7] = {0, 1, 3, 5, 6, 8, 10},
                     lydAug[7] = {0, 2, 4, 6, 8, 9, 11};
    const int* s = ionian;
    switch (quality) {
    case kMin: case kMin7: s = dorian; break;
    case kDom7: case kSus2: case kSus4: case kPower: s = mixo; break;
    case kDim: s = locrian; break;
    case kAug: s = lydAug; break;
    default: s = ionian; break;
    }
    for (int i = 0; i < 7; ++i) out[i] = s[i];
    return 7;
}

class ChordDetector {
public:
    void reset()
    {
        for (int i = 0; i < 12; ++i) chroma[i] = 0.0f;
        root = 0; quality = kMaj; confidence = 0.0f; pending = -1; pendingCount = 0; energy = 0.0f;
        bassPc = -1;
    }
    // Feed one frame of peaks. frameSeconds is the hop duration.
    void update(const std::vector<Peak>& peaks, float refA, float frameSeconds, float floorMag)
    {
        float frame[12] = {0};
        float total = 0.0f;
        float lowest = 1e9f, lowestMag = 0.0f, loudest = 0.0f;
        for (const Peak& p : peaks) loudest = std::max(loudest, p.mag);
        for (const Peak& p : peaks) {
            if (p.freq < 60.0f || p.freq > 2200.0f) continue;
            const float m = hzToMidi(p.freq, refA);
            const float near = std::round(m);
            const float dev = std::fabs(m - near);
            if (dev > 0.4f) continue;
            const int pc = ((int(near) % 12) + 12) % 12;
            // Log-compressed weight, de-emphasising upper harmonics a little.
            float w = std::log1p(p.mag / std::max(floorMag, 1e-6f)) * (1.0f - dev * 1.5f);
            if (p.freq > 1000.0f) w *= 0.6f;
            frame[pc] += w;
            total += w;
            if (p.freq < lowest && p.mag > loudest * 0.08f) { lowest = p.freq; lowestMag = p.mag; }
        }
        (void)lowestMag;
        const float a = 1.0f - std::exp(-frameSeconds / 0.12f);
        energy += (total - energy) * a;
        if (total <= 0.0f) return;  // silence: hold the last chord
        for (int i = 0; i < 12; ++i) chroma[i] += (frame[i] / total - chroma[i]) * a;
        if (lowest < 1e8f) bassPc = ((int(std::round(hzToMidi(lowest, refA))) % 12) + 12) % 12;

        float best = -1.0f, currentScore = -1.0f;
        int bestRoot = root, bestQ = quality;
        for (int r = 0; r < 12; ++r)
            for (int q = 0; q < kNumQualities; ++q) {
                const float s = score(r, q);
                if (s > best) { best = s; bestRoot = r; bestQ = q; }
                if (r == root && q == quality) currentScore = s;
            }
        confidence = best;
        const int cand = bestRoot * 16 + bestQ;
        if (cand == root * 16 + quality) { pending = -1; pendingCount = 0; return; }
        if (best < currentScore + 0.03f) return;
        if (cand != pending) { pending = cand; pendingCount = 0; }
        if (++pendingCount * frameSeconds >= 0.06f) {
            root = bestRoot; quality = bestQ; pending = -1; pendingCount = 0;
        }
    }
    float score(int r, int q) const
    {
        int iv[5];
        const int n = chordIntervals(q, iv);
        float in = 0.0f, norm = 0.0f;
        for (int i = 0; i < 12; ++i) norm += chroma[i] * chroma[i];
        for (int i = 0; i < n; ++i) in += chroma[(r + iv[i]) % 12] * (i == 0 ? 1.15f : 1.0f);
        float s = in / std::sqrt(std::max(norm, 1e-9f) * n);
        // Prefer simple triads unless the extension is clearly present.
        if (q == kDom7 || q == kMaj7 || q == kMin7) s -= 0.04f;
        if (q == kSus2 || q == kSus4 || q == kAug || q == kDim) s -= 0.03f;
        if (q == kPower) s -= 0.02f;
        if (r == bassPc) s += 0.05f;
        return s;
    }

    float chroma[12];
    float energy = 0.0f, confidence = 0.0f;
    int root = 0, quality = kMaj, bassPc = -1;

private:
    int pending = -1, pendingCount = 0;
};

}  // namespace rtal

#endif
