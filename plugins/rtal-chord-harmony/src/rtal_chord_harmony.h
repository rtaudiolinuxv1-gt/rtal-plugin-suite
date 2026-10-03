// Engine for rtal-chord-harmony: a chord-aware polyphonic harmonizer.
//
// Each STFT frame is reduced to its spectral peaks. The chord is recognised
// from those peaks (or set by hand), and for every harmony voice each peak is
// moved to the chord tone a chosen number of chord steps away, so a strummed
// chord comes back as a new inversion of the same chord instead of a parallel
// (clashing) copy. Notes that are not chord tones move along the matching
// chord scale. Peaks are moved with phase-locked phase-vocoder region shifting:
// the whole lobe around each peak moves together and its phase advances at the
// exact target frequency, so pitch is precise even at low notes.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_CHORD_HARMONY_H
#define RTAL_CHORD_HARMONY_H

#include "rtal_chord_detect.h"

namespace rtal {

struct ChordHarmonyEngine {
    static const int kN = 4096;
    static const int kHop = 512;
    static const int kVoices = 2;

    struct Track { int anaBin; float phase; };

    Stft stft;
    Analysis ana;
    ChordDetector detector;
    std::vector<Track> prev[kVoices], cur[kVoices];
    std::vector<float> rawMag, ratio;
    float out[kVoices] = {0.0f, 0.0f};

    void reset()
    {
        stft.setup(kN, kHop, kVoices);
        ana.setup(kN, kHop);
        detector.reset();
        for (int v = 0; v < kVoices; ++v) { prev[v].clear(); cur[v].clear(); prev[v].reserve(512); cur[v].reserve(512); }
        rawMag.assign(kN / 2 + 1, 0.0f);
        ratio.reserve(1024);
        out[0] = out[1] = 0.0f;
    }

    // Chord tones of the active chord as sorted pitch classes.
    static int tones(int root, int quality, int* pcs)
    {
        int iv[5];
        const int n = chordIntervals(quality, iv);
        for (int i = 0; i < n; ++i) pcs[i] = (root + iv[i]) % 12;
        std::sort(pcs, pcs + n);
        return n;
    }

    // Nearest member of a pitch-class set to midi pitch m; returns its absolute pitch and index.
    static float nearest(float m, const int* pcs, int n, int* index)
    {
        float best = 1e9f, bestPitch = m;
        for (int i = 0; i < n; ++i) {
            const float c = std::round((m - pcs[i]) / 12.0f) * 12.0f + pcs[i];
            if (std::fabs(m - c) < best) { best = std::fabs(m - c); bestPitch = c; *index = i; }
        }
        return bestPitch;
    }

    // Move an absolute set member 'steps' places along the (octave-repeating) set.
    static float step(float pitch, int index, int steps, const int* pcs, int n)
    {
        const float octaveBase = pitch - pcs[index];
        int idx = index + steps;
        int oct = 0;
        while (idx < 0) { idx += n; --oct; }
        while (idx >= n) { idx -= n; ++oct; }
        return octaveBase + 12.0f * oct + pcs[idx];
    }

    float semitoneShift(float m, const int* ct, int nct, const int* sc, int steps, int octave) const
    {
        int i = 0;
        const float c0 = nearest(m, ct, nct, &i);
        if (std::fabs(m - c0) <= 0.6f)
            return step(c0, i, steps, ct, nct) + 12.0f * octave - c0;
        int scale[7];
        for (int k = 0; k < 7; ++k) scale[k] = (sc[k] + detector.root * 0) % 12;
        const float s0 = nearest(m, scale, 7, &i);
        return step(s0, i, steps * 2, scale, 7) + 12.0f * octave - s0;
    }

    float process(float x, float sr, int mode, int manRoot, int manQuality, const int* steps, const int* octaves,
                  float refA, float sensitivity)
    {
        if (!(sr > 1000.0f)) sr = 48000.0f;
        if (!(refA > 300.0f && refA < 600.0f)) refA = 440.0f;
        if (stft.push(x)) frame(sr, mode, manRoot, manQuality, steps, octaves, refA, sensitivity);
        out[0] = stft.read(0);
        out[1] = stft.read(1);
        return out[0];
    }

    void frame(float sr, int mode, int manRoot, int manQuality, const int* steps, const int* octaves, float refA,
               float sensitivity)
    {
        const int half = kN / 2;
        const float binHz = sr / kN;
        ana.analyse(stft.re.data(), stft.im.data(), sr);
        for (int k = 0; k <= half; ++k) rawMag[k] = std::sqrt(stft.re[k] * stft.re[k] + stft.im[k] * stft.im[k]);
        // Sensitivity 0..1 sets the peak floor from -50 to -90 dBFS.
        const float floorMag = std::pow(10.0f, (-50.0f - 40.0f * sensitivity) / 20.0f);
        ana.findPeaks(floorMag, 50.0f, 50.0f, 6000.0f, sr);
        detector.update(ana.peaks, refA, float(kHop) / sr, floorMag);

        const int root = (mode == 1) ? ((manRoot % 12) + 12) % 12 : detector.root;
        const int quality = (mode == 1) ? std::min(std::max(manQuality, 0), kNumQualities - 1) : detector.quality;
        int ct[5];
        const int nct = tones(root, quality, ct);
        int scale[7];
        chordScale(quality, scale);
        for (int k = 0; k < 7; ++k) scale[k] = (scale[k] + root) % 12;
        std::sort(scale, scale + 7);

        const std::vector<Peak>& peaks = ana.peaks;
        for (int v = 0; v < kVoices; ++v) {
            float* yr = stft.outRe[v].data();
            float* yi = stft.outIm[v].data();
            cur[v].clear();
            if (steps[v] == 0 && octaves[v] == 0) {  // voice off
                prev[v].clear();
                continue;
            }
            ratio.assign(peaks.size(), 1.0f);
            for (size_t p = 0; p < peaks.size(); ++p) {
                const float m = hzToMidi(peaks[p].freq, refA);
                float semis = semitoneShift(m, ct, nct, scale, steps[v], octaves[v]);
                // Partials far from any chord tone are usually upper harmonics of
                // a lower note: move them with that note to keep it harmonic.
                int ci = 0;
                if (std::fabs(m - nearest(m, ct, nct, &ci)) > 0.6f) {
                    for (size_t q = 0; q < p; ++q) {
                        const float h = peaks[p].freq / peaks[q].freq;
                        const float hr = std::round(h);
                        if (hr >= 2.0f && hr <= 9.0f && std::fabs(h - hr) < 0.015f * hr &&
                            peaks[q].mag > peaks[p].mag * 0.3f) {
                            semis = 12.0f * std::log2(ratio[q]);
                            break;
                        }
                    }
                }
                ratio[p] = std::pow(2.0f, semis / 12.0f);
            }
            size_t searchFrom = 0;
            for (size_t p = 0; p < peaks.size(); ++p) {
                const Peak& pk = peaks[p];
                const float tf = pk.freq * ratio[p];
                const int kt = int(std::lround(tf / binHz));
                if (kt < 1 || kt >= half - 1) continue;
                // Continue the phase of the same partial from the previous frame.
                float theta = ana.phase[pk.bin];
                const std::vector<Track>& pv = prev[v];
                int bestD = 3;
                while (searchFrom < pv.size() && pv[searchFrom].anaBin < pk.bin - 2) ++searchFrom;
                for (size_t j = searchFrom; j < pv.size() && pv[j].anaBin <= pk.bin + 2; ++j) {
                    const int d = std::abs(pv[j].anaBin - pk.bin);
                    if (d < bestD) { bestD = d; theta = pv[j].phase + kTwoPi * tf * kHop / sr; }
                }
                theta = wrapPhase(theta);
                cur[v].push_back(Track{pk.bin, theta});
                const int shift = kt - pk.bin;
                for (int k = pk.lo; k <= pk.hi; ++k) {
                    const int tk = k + shift;
                    if (tk < 1 || tk >= half) continue;
                    const float ph = theta + (ana.phase[k] - ana.phase[pk.bin]);
                    yr[tk] += rawMag[k] * std::cos(ph);
                    yi[tk] += rawMag[k] * std::sin(ph);
                }
            }
            prev[v].swap(cur[v]);
        }
        stft.synthesize();
    }
};

typedef Pool<ChordHarmonyEngine, 32> ChordHarmonyPool;

}  // namespace rtal

// ---- Faust interface -------------------------------------------------------
static inline int rtal_ch_open_fn() { return rtal::ChordHarmonyPool::open(); }
#define rtal_ch_open rtal_ch_open_fn()

static inline float rtal_ch_process(int h, float x, float sr, int mode, int manRoot, int manQuality, int steps1,
                                    int oct1, int steps2, int oct2, float refA, float sensitivity)
{
    rtal::DenormalGuard guard;
    const int steps[2] = {steps1, steps2};
    const int octs[2] = {oct1, oct2};
    return rtal::ChordHarmonyPool::slot(h)->process(x, sr, mode, manRoot, manQuality, steps, octs, refA, sensitivity);
}

// Second voice of the latest sample. 'x' only ties the call to the audio rate.
static inline float rtal_ch_voice2(int h, float x)
{
    (void)x;
    return rtal::ChordHarmonyPool::slot(h)->out[1];
}

// which: 0 root (0-11), 1 quality, 2 confidence. 'x' ties the call to audio rate.
static inline float rtal_ch_meter(int h, int which, float x)
{
    (void)x;
    rtal::ChordHarmonyEngine* e = rtal::ChordHarmonyPool::slot(h);
    if (which == 0) return float(e->detector.root);
    if (which == 1) return float(e->detector.quality);
    return e->detector.confidence;
}

#endif
