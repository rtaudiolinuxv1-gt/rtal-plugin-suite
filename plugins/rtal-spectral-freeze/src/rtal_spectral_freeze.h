// Engine for rtal-spectral-freeze: captures moments of the guitar as frozen
// spectra and plays them back indefinitely, morphing between two captures.
//
// A capture stores, per frequency bin, the magnitude (averaged over a few
// frames when Blur is up) and the instantaneous frequency measured from the
// phase vocoder, so frozen notes keep their exact pitch. Playback rebuilds
// each frame from the stored spectrum, advancing every bin's phase at its own
// frequency; Diffusion adds random phase so the sound smears into a wash, and
// Shimmer lets each bin's level drift slowly. The left and right outputs use
// independent random phases, which makes the freeze naturally wide.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_SPECTRAL_FREEZE_H
#define RTAL_SPECTRAL_FREEZE_H

#include "rtal_spectral_core.h"

namespace rtal {

struct SpectralFreezeEngine {
    static const int kN = 4096;
    static const int kHop = 1024;
    static const int kBins = kN / 2 + 1;

    struct Slot {
        std::vector<float> mag, omega;  // omega: phase advance per hop, radians
        bool filled = false;
    };

    Stft stft;
    Analysis ana;
    Slot slot[2];
    // Capture in progress: averaging frames into 'target'.
    std::vector<float> accMag, accOmega;
    int captureTarget = -1, captureFrames = 0, captureNeeded = 1, captureDelay = 0;
    int pendingAuto = -1;
    int lastCapA = 0, lastCapB = 0, lastClear = 0;
    int latest = 0, alternate = 0;
    // Playback
    std::vector<float> phase[2], drift, driftTarget;
    std::vector<float> prevLogMag;
    float fluxMean = 0.0f, prevFlux = 0.0f;
    int refractory = 0;
    Rng rng;
    float outR = 0.0f;

    void reset()
    {
        stft.setup(kN, kHop, 2);
        ana.setup(kN, kHop);
        for (Slot& s : slot) { s.mag.assign(kBins, 0.0f); s.omega.assign(kBins, 0.0f); s.filled = false; }
        accMag.assign(kBins, 0.0f); accOmega.assign(kBins, 0.0f);
        for (int c = 0; c < 2; ++c) phase[c].assign(kBins, 0.0f);
        drift.assign(kBins, 1.0f); driftTarget.assign(kBins, 1.0f);
        prevLogMag.assign(kBins, -12.0f);
        captureTarget = -1; captureFrames = 0; captureDelay = 0; pendingAuto = -1;
        lastCapA = lastCapB = lastClear = 0; latest = 0; alternate = 0;
        fluxMean = 0.0f; prevFlux = 0.0f; refractory = 0; outR = 0.0f;
        rng.seed(entropySeed(this));
        for (int c = 0; c < 2; ++c)
            for (float& p : phase[c]) p = (rng.uni() * 2.0f - 1.0f) * kPi;
    }

    void startCapture(int target, float blur, int delayFrames)
    {
        captureTarget = target;
        captureFrames = 0;
        captureNeeded = 1 + int(blur * 15.0f + 0.5f);
        captureDelay = delayFrames;
        std::fill(accMag.begin(), accMag.end(), 0.0f);
        std::fill(accOmega.begin(), accOmega.end(), 0.0f);
    }

    float process(float x, float sr, int capA, int capB, int autoMode, float sensitivity, float blur, float morph,
                  float diffusion, float shimmer, float shiftSemis, float tilt, int clear)
    {
        if (!(sr > 1000.0f)) sr = 48000.0f;
        // Button edges (checked every sample so short clicks are never missed).
        if (clear && !lastClear) { for (Slot& s : slot) { std::fill(s.mag.begin(), s.mag.end(), 0.0f); s.filled = false; } captureTarget = -1; }
        if (capA && !lastCapA) startCapture(0, blur, 0);
        if (capB && !lastCapB) startCapture(1, blur, 0);
        lastCapA = capA; lastCapB = capB; lastClear = clear;
        if (stft.push(x)) frame(sr, autoMode, sensitivity, blur, morph, diffusion, shimmer, shiftSemis, tilt);
        outR = stft.read(1);
        return stft.read(0);
    }

    void frame(float sr, int autoMode, float sensitivity, float blur, float morph, float diffusion, float shimmer,
               float shiftSemis, float tilt)
    {
        ana.analyse(stft.re.data(), stft.im.data(), sr);
        const float norm = float(kN) / kPi;  // back to raw FFT magnitude for resynthesis

        // Onset detection for automatic capture (positive log-spectral flux).
        float flux = 0.0f, energy = 0.0f;
        for (int k = 2; k < kBins - 1; ++k) {
            const float lm = std::log(ana.mag[k] + 1e-6f);
            const float d = lm - prevLogMag[k];
            if (d > 0.0f && k < kBins / 3) flux += d;
            prevLogMag[k] = lm;
            energy += ana.mag[k] * ana.mag[k];
        }
        flux /= float(kBins / 3);
        const float levelDb = 10.0f * std::log10(energy + 1e-12f);
        const float gateDb = -45.0f - 30.0f * sensitivity;
        const bool onset = refractory <= 0 && levelDb > gateDb && flux > fluxMean * 2.0f + 0.25f && flux > prevFlux;
        fluxMean += (flux - fluxMean) * 0.1f;
        prevFlux = flux;
        if (refractory > 0) --refractory;
        if (onset && autoMode > 0) {
            refractory = 8;
            int target = 0;
            if (autoMode == 2) { target = alternate; alternate ^= 1; }
            // Skip the pick attack: start averaging two frames later.
            startCapture(target, blur, 2);
        }

        // Capture.
        if (captureTarget >= 0) {
            if (captureDelay > 0) {
                --captureDelay;
            } else {
                for (int k = 0; k < kBins; ++k) {
                    accMag[k] += ana.mag[k] * norm;
                    const float binW = kTwoPi * k / kN;
                    accOmega[k] = (ana.freq[k] / sr) * kTwoPi * kHop;  // latest frame's estimate
                    if (!(accOmega[k] == accOmega[k])) accOmega[k] = binW * kHop;
                }
                if (++captureFrames >= captureNeeded) {
                    Slot& s = slot[captureTarget];
                    for (int k = 0; k < kBins; ++k) { s.mag[k] = accMag[k] / captureFrames; s.omega[k] = accOmega[k]; }
                    s.filled = true;
                    latest = captureTarget;
                    captureTarget = -1;
                }
            }
        }

        // Playback.
        const float m = std::min(std::max(morph, 0.0f), 1.0f);
        const float ratio = std::pow(2.0f, std::min(std::max(shiftSemis, -24.0f), 24.0f) / 12.0f);
        const float diff = std::min(std::max(diffusion, 0.0f), 1.0f);
        const float shim = std::min(std::max(shimmer, 0.0f), 1.0f);
        const bool anyFilled = slot[0].filled || slot[1].filled;
        for (int c = 0; c < 2; ++c) {
            float* yr = stft.outRe[c].data();
            float* yi = stft.outIm[c].data();
            if (!anyFilled) continue;
            for (int k = 1; k < kBins - 1; ++k) {
                const float a = slot[0].mag[k], b = slot[1].mag[k];
                // Part geometric (true spectral morph), part linear (so an empty slot fades, not vanishes).
                const float geo = std::exp((1.0f - m) * std::log(a + 1e-9f) + m * std::log(b + 1e-9f));
                const float mag = 0.6f * geo + 0.4f * ((1.0f - m) * a + m * b);
                if (mag < 1e-6f) continue;
                const float wa = a * (1.0f - m), wb = b * m;
                const float om = (wa * slot[0].omega[k] + wb * slot[1].omega[k]) / (wa + wb + 1e-12f);
                const int tk = int(std::lround(k * ratio));
                if (tk < 1 || tk >= kBins - 1) continue;
                const float tiltGain = std::pow(float(k) / 64.0f, tilt * 0.5f);
                float ph = phase[c][tk] + om * ratio;
                if (diff > 0.0f) ph += diff * (rng.uni() * 2.0f - 1.0f) * kPi;
                phase[c][tk] = wrapPhase(ph);
                const float level = mag * tiltGain * (c == 0 ? drift[k] : (2.0f - drift[k]));
                yr[tk] += level * std::cos(phase[c][tk]);
                yi[tk] += level * std::sin(phase[c][tk]);
            }
        }
        // Shimmer: every bin's level wanders towards a random target.
        for (int k = 0; k < kBins; ++k) {
            if (rng.uni() < 0.05f) driftTarget[k] = 1.0f + shim * (rng.uni() * 2.0f - 1.0f) * 0.9f;
            drift[k] += (driftTarget[k] - drift[k]) * 0.08f;
        }
        stft.synthesize();
    }
};

typedef Pool<SpectralFreezeEngine, 32> SpectralFreezePool;

}  // namespace rtal

static inline int rtal_sf_open_fn() { return rtal::SpectralFreezePool::open(); }
#define rtal_sf_open rtal_sf_open_fn()

// One sample in; returns the left frozen output.
static inline float rtal_sf_process(int h, float x, float sr, int capA, int capB, int autoMode, float sensitivity,
                                    float blur, float morph, float diffusion, float shimmer, float shift, float tilt,
                                    int clear)
{
    rtal::DenormalGuard guard;
    return rtal::SpectralFreezePool::slot(h)->process(x, sr, capA, capB, autoMode, sensitivity, blur, morph,
                                                      diffusion, shimmer, shift, tilt, clear);
}

// which: 0 right output, 1 slot captured most recently (0 = A, 1 = B),
// 2 slot A filled, 3 slot B filled. 'tie' orders the call after process.
static inline float rtal_sf_info(int h, int which, float tie)
{
    (void)tie;
    const rtal::SpectralFreezeEngine* e = rtal::SpectralFreezePool::slot(h);
    switch (which) {
    case 0: return e->outR;
    case 1: return float(e->latest);
    case 2: return e->slot[0].filled ? 1.0f : 0.0f;
    default: return e->slot[1].filled ? 1.0f : 0.0f;
    }
}

#endif
