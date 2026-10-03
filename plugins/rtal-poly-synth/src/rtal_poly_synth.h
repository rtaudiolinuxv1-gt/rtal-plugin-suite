// Engine for rtal-poly-synth: polyphonic note detection from a single guitar
// signal, feeding six synth voices.
//
// Each STFT frame is reduced to spectral peaks, then notes are pulled out one
// at a time (iterative multi-pitch estimation): every candidate fundamental is
// scored by how much harmonic energy it explains, the best one is taken, the
// peaks it explains are attenuated, and the search repeats. Detected notes are
// tracked across frames and given stable voice slots, so a held chord keeps
// each string on its own synth voice and bends glide that voice only.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_POLY_SYNTH_H
#define RTAL_POLY_SYNTH_H

#include "rtal_spectral_core.h"

namespace rtal {

struct PolySynthEngine {
    static const int kN = 4096;
    static const int kHop = 512;
    static const int kVoices = 6;

    struct Voice { float freq = 0.0f, amp = 0.0f; int missing = 0; bool on = false; };
    struct Cand { float freq; int count; };

    Stft stft;
    Analysis ana;
    Voice voice[kVoices];
    std::vector<float> work;
    std::vector<Cand> pendingNotes;
    float noteFreq[kVoices], noteAmp[kVoices];
    int noteCount = 0, activeCount = 0;

    void reset()
    {
        stft.setup(kN, kHop, 0);
        ana.setup(kN, kHop);
        for (Voice& v : voice) v = Voice();
        work.reserve(1024);
        pendingNotes.clear();
        pendingNotes.reserve(16);
        noteCount = 0; activeCount = 0;
    }

    // Iterative multi-pitch estimation on the current peak list.
    void detect(float floorMag, int maxNotes)
    {
        const std::vector<Peak>& pk = ana.peaks;
        const size_t n = pk.size();
        work.resize(n);
        for (size_t i = 0; i < n; ++i) work[i] = pk[i].mag;
        noteCount = 0;
        float firstSalience = 0.0f;
        for (int iter = 0; iter < maxNotes; ++iter) {
            float best = 0.0f, bestF = 0.0f;
            for (size_t c = 0; c < n; ++c) {
                const float f0 = pk[c].freq;
                if (f0 < 70.0f || f0 > 1400.0f || work[c] < floorMag) continue;
                bool dup = false;
                for (int d = 0; d < noteCount && !dup; ++d)
                    dup = std::fabs(12.0f * std::log2(f0 / noteFreq[d])) < 0.6f;
                if (dup) continue;
                // Upper harmonics of a found note need extra evidence to count as notes.
                float need = 0.25f;
                for (int d = 0; d < noteCount; ++d) {
                    const float r = f0 / noteFreq[d];
                    const float rr = std::round(r);
                    if (rr >= 2.0f && std::fabs(r - rr) < 0.02f * rr) need = 0.38f;
                }
                float sal = 0.0f;
                int hits = 0;
                size_t j = c;
                for (int h = 1; h <= 10; ++h) {
                    const float target = f0 * h;
                    // peaks are sorted by frequency; advance to the nearest one
                    while (j + 1 < n && pk[j + 1].freq < target * 1.03f) {
                        if (pk[j + 1].freq > target * 0.97f) break;
                        ++j;
                    }
                    float m = 0.0f;
                    for (size_t q = j; q < n && pk[q].freq < target * 1.03f; ++q)
                        if (pk[q].freq > target * 0.97f) m = std::max(m, work[q]);
                    if (m > 0.0f) { sal += std::sqrt(m) / (0.6f + 0.4f * h); ++hits; }
                }
                // A real note shows several harmonics and its own fundamental.
                if (hits < 2) sal *= 0.3f;
                if (iter > 0 && sal < firstSalience * need) continue;
                if (sal > best) { best = sal; bestF = f0; }
            }
            if (best <= 0.0f) break;
            if (iter == 0) firstSalience = best;
            // Refine f0 from the low harmonics and collect its loudness.
            float num = 0.0f, den = 0.0f, energy = 0.0f;
            for (size_t q = 0; q < n; ++q) {
                const float h = std::round(pk[q].freq / bestF);
                if (h < 1.0f || h > 10.0f) continue;
                if (std::fabs(pk[q].freq / (h * bestF) - 1.0f) > 0.03f) continue;
                if (h <= 4.0f) { num += pk[q].freq / h * work[q]; den += work[q]; }
                energy += work[q] * work[q];
                work[q] *= 0.25f;  // explained: leave a little for octave doublings
            }
            if (den <= 0.0f) break;
            noteFreq[noteCount] = num / den;
            noteAmp[noteCount] = std::sqrt(energy);
            ++noteCount;
        }
    }

    // Keep each note on the same voice from frame to frame.
    void track(float refA)
    {
        bool used[kVoices] = {false};
        bool matched[kVoices] = {false};
        for (int i = 0; i < noteCount; ++i) {
            const float m = hzToMidi(noteFreq[i], refA);
            int bestV = -1;
            float bestD = 0.75f;
            for (int v = 0; v < kVoices; ++v) {
                if (!voice[v].on || used[v]) continue;
                const float d = std::fabs(hzToMidi(voice[v].freq, refA) - m);
                if (d < bestD) { bestD = d; bestV = v; }
            }
            if (bestV >= 0) {
                used[bestV] = true;
                matched[i] = true;
                voice[bestV].freq = noteFreq[i];
                voice[bestV].amp = noteAmp[i];
                voice[bestV].missing = 0;
            }
        }
        // New notes must persist for two frames before taking a voice.
        std::vector<Cand> next;
        for (int i = 0; i < noteCount; ++i) {
            if (matched[i]) continue;
            int count = 1;
            for (const Cand& c : pendingNotes)
                if (std::fabs(hzToMidi(c.freq, refA) - hzToMidi(noteFreq[i], refA)) < 0.75f) count = c.count + 1;
            if (count < 2) { next.push_back(Cand{noteFreq[i], count}); continue; }
            int slot = -1;
            for (int v = 0; v < kVoices && slot < 0; ++v)
                if (!voice[v].on && !used[v]) slot = v;
            if (slot < 0) {  // steal the quietest unmatched voice
                float q = 1e9f;
                for (int v = 0; v < kVoices; ++v)
                    if (!used[v] && voice[v].amp < q) { q = voice[v].amp; slot = v; }
            }
            if (slot < 0) continue;
            used[slot] = true;
            voice[slot].on = true;
            voice[slot].freq = noteFreq[i];
            voice[slot].amp = noteAmp[i];
            voice[slot].missing = 0;
        }
        pendingNotes.swap(next);
        activeCount = 0;
        for (int v = 0; v < kVoices; ++v) {
            if (!voice[v].on) continue;
            if (!used[v]) {
                voice[v].amp *= 0.6f;
                if (++voice[v].missing > 4) { voice[v].on = false; voice[v].amp = 0.0f; }
            }
            if (voice[v].on) ++activeCount;
        }
    }

    float process(float x, float sr, float sensitivity, int maxNotes, float refA)
    {
        if (!(sr > 1000.0f)) sr = 48000.0f;
        if (!(refA > 300.0f && refA < 600.0f)) refA = 440.0f;
        maxNotes = std::min(std::max(maxNotes, 1), kVoices);
        if (stft.push(x)) {
            ana.analyse(stft.re.data(), stft.im.data(), sr);
            const float floorMag = std::pow(10.0f, (-45.0f - 35.0f * sensitivity) / 20.0f);
            ana.findPeaks(floorMag, 45.0f, 60.0f, 8000.0f, sr);
            detect(floorMag, maxNotes);
            track(refA);
        }
        return float(activeCount);
    }
};

typedef Pool<PolySynthEngine, 32> PolySynthPool;

}  // namespace rtal

static inline int rtal_ps_open_fn() { return rtal::PolySynthPool::open(); }
#define rtal_ps_open rtal_ps_open_fn()

static inline float rtal_ps_process(int h, float x, float sr, float sensitivity, int maxNotes, float refA)
{
    rtal::DenormalGuard guard;
    return rtal::PolySynthPool::slot(h)->process(x, sr, sensitivity, maxNotes, refA);
}

// Voice v frequency in Hz after pitch snap (0..1 towards the nearest
// semitone) and octave shift; 0 when the voice is idle. 'tie' orders the call
// after process.
static inline float rtal_ps_freq(int h, int v, float tie, float snap, int octave, float refA)
{
    (void)tie;
    const rtal::PolySynthEngine::Voice& vc = rtal::PolySynthPool::slot(h)->voice[std::min(std::max(v, 0), 5)];
    if (!vc.on) return 0.0f;
    if (!(refA > 300.0f && refA < 600.0f)) refA = 440.0f;
    const float m = rtal::hzToMidi(vc.freq, refA);
    const float snapped = m + (std::round(m) - m) * std::min(std::max(snap, 0.0f), 1.0f) + 12.0f * octave;
    return rtal::midiToHz(snapped, refA);
}

// Voice v level (linear spectral magnitude, 0 when idle).
static inline float rtal_ps_amp(int h, int v, float tie)
{
    (void)tie;
    const rtal::PolySynthEngine::Voice& vc = rtal::PolySynthPool::slot(h)->voice[std::min(std::max(v, 0), 5)];
    return vc.on ? vc.amp : 0.0f;
}

#endif
