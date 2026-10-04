// Engine for rtal-smart-denoise: learns the noise of the rig on its own and
// removes it band by band without chewing up note tails.
//
// Noise profile: per frequency bin, the smoothed power is learned only in
// real gaps in the playing - frames whose broadband level is within about
// 5 dB of the quietest frame of the last five seconds and at least 25 dB
// below the loudest, for at least 0.15 s.
// While notes ring the profile can only drift down, so sustained and
// decaying notes are never mistaken for noise; steady hum and hiss, which
// are present in every gap, are. 'Learn Now' averages whatever is playing
// into the profile; 'Hold' freezes it. Nothing is removed until the first
// gap has been heard.
//
// Gain: a Wiener filter driven by a decision-directed a-priori SNR
// (Ephraim-Malah), which avoids the warbling "musical noise" of plain spectral
// subtraction. Gains are smoothed across neighbouring bins, never fall below
// the Reduction limit, and recover instantly but release slowly, so a note
// decaying into the noise fades naturally instead of being chopped.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_SMART_DENOISE_H
#define RTAL_SMART_DENOISE_H

#include "rtal_spectral_core.h"

namespace rtal {

struct SmartDenoiseEngine {
    static const int kN = 2048;
    static const int kHop = 512;
    static const int kBins = kN / 2 + 1;

    Stft ch[2];
    std::vector<float> smoothP, noise, prevGain, prevPost, gain, gainTmp, bbHistory;
    int bbPos = 0, bbFill = 0;
    float quietRun = 0.0f;
    int frames = 0;
    bool learnedOnce = false;
    float noiseDb = -120.0f, reductionDb = 0.0f, learning = 0.0f;
    int lastReset = 0;
    float outR = 0.0f, inL = 0.0f, inR = 0.0f;
    bool listening = false;

    void reset()
    {
        for (Stft& s : ch) s.setup(kN, kHop, 2);  // stream 0 cleaned, stream 1 removed noise
        smoothP.assign(kBins, 0.0f);
        noise.assign(kBins, 1e-15f);
        bbHistory.assign(470, 0.0f);
        bbPos = 0; bbFill = 0; quietRun = 0.0f;
        prevGain.assign(kBins, 1.0f);
        prevPost.assign(kBins, 1.0f);
        gain.assign(kBins, 1.0f);
        gainTmp.assign(kBins, 1.0f);
        frames = 0; learnedOnce = false;
        noiseDb = -120.0f; reductionDb = 0.0f; learning = 0.0f; lastReset = 0;
        outR = inL = inR = 0.0f;
    }

    float process(float l, float r, float sr, int mode, int learnNow, int resetBtn, float reduction, float sensitivity,
                  float releaseMs, float smoothing, int listenNoise)
    {
        if (!(sr > 1000.0f)) sr = 48000.0f;
        if (resetBtn && !lastReset) {
            std::fill(noise.begin(), noise.end(), 1e-15f);
            bbPos = 0; bbFill = 0; quietRun = 0.0f;
            std::fill(smoothP.begin(), smoothP.end(), 0.0f);
            frames = 0; learnedOnce = false;
        }
        lastReset = resetBtn;
        const bool ready = ch[0].push(l);
        ch[1].push(r);
        listening = listenNoise != 0;
        if (ready) frame(sr, mode, learnNow, reduction, sensitivity, releaseMs, smoothing);
        const int s = listenNoise ? 1 : 0;
        outR = ch[1].read(s);
        return ch[0].read(s);
    }

    void frame(float sr, int mode, int learnNow, float reduction, float sensitivity, float releaseMs, float smoothing)
    {
        const float hopSec = float(kHop) / sr;
        ++frames;
        float frameP = 0.0f, frameN = 0.0f;
        for (int k = 0; k < kBins; ++k) {
            float p = 0.0f;
            for (int c = 0; c < 2; ++c) p += ch[c].re[k] * ch[c].re[k] + ch[c].im[k] * ch[c].im[k];
            p *= 0.5f;
            smoothP[k] = (frames == 1) ? p : smoothP[k] * 0.7f + p * 0.3f;
            frameP += p;
            frameN += noise[k];
        }
        // Noise profile update. The profile only learns in real gaps (see the
        // header comment). While playing it can only
        // drift down, so ringing and decaying notes are never learned as noise.
        bbHistory[bbPos] = frameP;
        bbPos = (bbPos + 1) % int(bbHistory.size());
        if (bbFill < int(bbHistory.size())) ++bbFill;
        float bbMin = 1e30f, bbMax = 0.0f;
        for (int i = 0; i < bbFill; ++i) { bbMin = std::min(bbMin, bbHistory[i]); bbMax = std::max(bbMax, bbHistory[i]); }
        // A gap is near the quietest level and also far (25 dB) below the
        // loudest, so the tail of a repeated chord is not mistaken for one.
        const bool quiet = frameP <= bbMin * 3.0f + 1e-20f && frameP <= bbMax * 0.00316f + 1e-20f;
        quietRun = quiet ? quietRun + hopSec : 0.0f;
        learning = 0.0f;
        if (learnNow) {
            const float a = 1.0f - std::exp(-hopSec / 0.4f);
            for (int k = 0; k < kBins; ++k) noise[k] += (smoothP[k] - noise[k]) * a;
            learnedOnce = true;
            learning = 1.0f;
        } else if (mode == 0) {
            if (quietRun >= 0.15f) {
                const float a = learnedOnce ? 1.0f - std::exp(-hopSec / 0.4f) : 1.0f;
                for (int k = 0; k < kBins; ++k) noise[k] += (smoothP[k] - noise[k]) * a;
                learnedOnce = true;
                learning = 1.0f;
            } else {
                const float down = std::exp(-hopSec / 2.0f);
                for (int k = 0; k < kBins; ++k)
                    if (smoothP[k] < noise[k] * 0.5f) noise[k] = std::max(noise[k] * down, 1e-15f);
                learning = 0.5f;
            }
        }
        // Gains.
        const float floorGain = std::pow(10.0f, -std::min(std::max(reduction, 0.0f), 60.0f) / 20.0f);
        const float over = 1.0f + 3.0f * std::min(std::max(sensitivity, 0.0f), 1.0f);
        const float release = std::exp(-hopSec / std::max(0.005f, releaseMs * 0.001f));
        const float alpha = 0.98f;
        float sumIn = 0.0f, sumOut = 0.0f;
        for (int k = 0; k < kBins; ++k) {
            float p = 0.0f;
            for (int c = 0; c < 2; ++c) p += ch[c].re[k] * ch[c].re[k] + ch[c].im[k] * ch[c].im[k];
            p *= 0.5f;
            const float nk = noise[k] * over + 1e-15f;
            const float post = p / nk;
            const float prior = alpha * prevGain[k] * prevGain[k] * prevPost[k] + (1.0f - alpha) * std::max(post - 1.0f, 0.0f);
            float g = prior / (1.0f + prior);
            prevPost[k] = std::min(post, 1e6f);
            gainTmp[k] = g;
        }
        // Smooth across frequency (reduces isolated warbling bins).
        const int w = int(std::min(std::max(smoothing, 0.0f), 1.0f) * 4.0f + 0.5f);
        for (int k = 0; k < kBins; ++k) {
            float s = 0.0f;
            int n = 0;
            for (int j = std::max(0, k - w); j <= std::min(kBins - 1, k + w); ++j) { s += gainTmp[j]; ++n; }
            float g = std::max(s / n, floorGain);
            // Fast recovery, slow release: tails fade instead of being chopped.
            g = std::max(g, gain[k] * release);
            g = std::min(g, 1.0f);
            gain[k] = g;
            prevGain[k] = g;
        }
        for (int c = 0; c < 2; ++c) {
            Stft& s = ch[c];
            for (int k = 0; k < kBins; ++k) {
                const float g = (k == 0) ? floorGain : gain[k];
                s.outRe[0][k] = s.re[k] * g;
                s.outIm[0][k] = s.im[k] * g;
                s.outRe[1][k] = s.re[k] * (1.0f - g);
                s.outIm[1][k] = s.im[k] * (1.0f - g);
                const float pk = s.re[k] * s.re[k] + s.im[k] * s.im[k];
                sumIn += pk;
                sumOut += pk * g * g;
            }
            s.synthesize(listening ? 2 : 1);  // the removed-noise stream only when monitored
        }
        noiseDb = 10.0f * std::log10(frameN / (float(kN) * kN * 0.25f) + 1e-12f);
        const float red = 10.0f * std::log10((sumOut + 1e-12f) / (sumIn + 1e-12f));
        reductionDb += (red - reductionDb) * 0.3f;
    }
};

typedef Pool<SmartDenoiseEngine, 32> SmartDenoisePool;

}  // namespace rtal

static inline int rtal_dn_open_fn() { return rtal::SmartDenoisePool::open(); }
#define rtal_dn_open rtal_dn_open_fn()

// Stereo sample in; returns the left output (cleaned, or the removed noise when listenNoise).
static inline float rtal_dn_process(int h, float l, float r, float sr, int mode, int learnNow, int resetBtn,
                                    float reduction, float sensitivity, float releaseMs, float smoothing,
                                    int listenNoise)
{
    rtal::DenormalGuard guard;
    return rtal::SmartDenoisePool::slot(h)->process(l, r, sr, mode, learnNow, resetBtn, reduction, sensitivity,
                                                    releaseMs, smoothing, listenNoise);
}

// which: 0 right output, 1 noise floor (dBFS-ish), 2 current reduction (dB, <= 0),
// 3 learning state (0 holding, 0.5 tracking, 1 learning). 'tie' orders the call.
static inline float rtal_dn_info(int h, int which, float tie)
{
    (void)tie;
    const rtal::SmartDenoiseEngine* e = rtal::SmartDenoisePool::slot(h);
    switch (which) {
    case 0: return e->outR;
    case 1: return e->noiseDb;
    case 2: return e->reductionDb;
    default: return e->learning;
    }
}

#endif
