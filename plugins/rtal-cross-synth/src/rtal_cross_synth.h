// Engine for rtal-cross-synth: gives the guitar the texture of another sound.
//
// Per STFT frame, both the guitar and the texture are split into a smooth
// spectral envelope (a log-domain moving average across frequency) and the
// fine structure riding on it. The output magnitude is
//
//   guitar^keep * guitarEnvelope^(1-keep)      (keep = Pitch Keep)
//   * (texture / textureEnvelope)^imprint      (the texture's fine detail)
//   * (textureEnvelope / mean)^colour          (the texture's tone colour)
//
// and the phase blends from the guitar's (pitch stays exact) to the
// texture's (grain, noise and motion). The output is matched to the guitar's
// loudness frame by frame. Two texture streams give a decorrelated stereo pair.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_CROSS_SYNTH_H
#define RTAL_CROSS_SYNTH_H

#include "rtal_spectral_core.h"

namespace rtal {

struct CrossSynthEngine {
    static const int kN = 2048;
    static const int kHop = 512;
    static const int kBins = kN / 2 + 1;

    Stft guitar, tex[2];
    std::vector<float> gMag, gEnv, tMag, tEnv, logTmp, prefix;
    float gainSmooth[2] = {1.0f, 1.0f};
    float texAvg[2] = {0.0f, 0.0f};
    float outR = 0.0f;

    void reset()
    {
        guitar.setup(kN, kHop, 2);
        for (Stft& t : tex) t.setup(kN, kHop, 0);
        gMag.assign(kBins, 0.0f); gEnv.assign(kBins, 0.0f);
        tMag.assign(kBins, 0.0f); tEnv.assign(kBins, 0.0f);
        logTmp.assign(kBins, 0.0f); prefix.assign(kBins + 1, 0.0f);
        gainSmooth[0] = gainSmooth[1] = 1.0f;
        texAvg[0] = texAvg[1] = 0.0f;
        outR = 0.0f;
    }

    // Log-domain moving average across +-w bins (w grows with frequency).
    void envelope(const std::vector<float>& mag, std::vector<float>& env, float smoothing)
    {
        for (int k = 0; k < kBins; ++k) logTmp[k] = std::log(mag[k] + 1e-7f);
        prefix[0] = 0.0f;
        for (int k = 0; k < kBins; ++k) prefix[k + 1] = prefix[k] + logTmp[k];
        for (int k = 0; k < kBins; ++k) {
            const int w = 1 + int((2.0f + 0.06f * k) * smoothing);
            const int a = std::max(0, k - w), b = std::min(kBins - 1, k + w);
            env[k] = std::exp((prefix[b + 1] - prefix[a]) / float(b - a + 1));
        }
    }

    float process(float g, float t0, float t1, float imprint, float keep, float colour, float phaseBlend,
                  float smoothing)
    {
        const bool ready = guitar.push(g);
        tex[0].push(t0);
        tex[1].push(t1);
        if (ready) frame(imprint, keep, colour, phaseBlend, smoothing);
        outR = guitar.read(1);
        return guitar.read(0);
    }

    void frame(float imprint, float keep, float colour, float phaseBlend, float smoothing)
    {
        imprint = std::min(std::max(imprint, 0.0f), 1.0f);
        keep = std::min(std::max(keep, 0.0f), 1.0f);
        colour = std::min(std::max(colour, 0.0f), 1.0f);
        phaseBlend = std::min(std::max(phaseBlend, 0.0f), 1.0f);
        smoothing = 0.3f + 3.0f * std::min(std::max(smoothing, 0.0f), 1.0f);
        const float* gr = guitar.re.data();
        const float* gi = guitar.im.data();
        float gEnergy = 0.0f;
        for (int k = 0; k < kBins; ++k) {
            gMag[k] = std::sqrt(gr[k] * gr[k] + gi[k] * gi[k]);
            gEnergy += gMag[k] * gMag[k];
        }
        envelope(gMag, gEnv, smoothing);
        for (int s = 0; s < 2; ++s) {
            const float* tr = tex[s].re.data();
            const float* ti = tex[s].im.data();
            float meanEnv = 0.0f, tEnergy = 0.0f;
            for (int k = 0; k < kBins; ++k) {
                tMag[k] = std::sqrt(tr[k] * tr[k] + ti[k] * ti[k]);
                tEnergy += tMag[k] * tMag[k];
            }
            // The texture's own rhythm (rain drops, gusts): its frame level
            // against a slow average, applied after loudness matching.
            texAvg[s] += (tEnergy - texAvg[s]) * 0.03f;
            const float pulse = std::min(4.0f, std::pow((tEnergy + 1e-12f) / (texAvg[s] + 1e-12f), 0.25f * imprint));
            envelope(tMag, tEnv, smoothing);
            for (int k = 1; k < kBins - 1; ++k) meanEnv += std::log(tEnv[k]);
            meanEnv = std::exp(meanEnv / (kBins - 2));
            float* yr = guitar.outRe[s].data();
            float* yi = guitar.outIm[s].data();
            float yEnergy = 0.0f;
            for (int k = 1; k < kBins - 1; ++k) {
                const float base = std::pow(gMag[k] + 1e-9f, keep) * std::pow(gEnv[k], 1.0f - keep);
                const float fine = std::pow(tMag[k] / tEnv[k] + 1e-6f, imprint);
                const float tone = std::pow(tEnv[k] / (meanEnv + 1e-9f) + 1e-6f, colour);
                const float mag = base * fine * tone;
                // Phase: unit vectors of guitar and texture, blended.
                const float gu = gMag[k] > 1e-9f ? 1.0f / gMag[k] : 0.0f;
                const float tu = tMag[k] > 1e-9f ? 1.0f / tMag[k] : 0.0f;
                float pr = (1.0f - phaseBlend) * gr[k] * gu + phaseBlend * tr[k] * tu;
                float pi = (1.0f - phaseBlend) * gi[k] * gu + phaseBlend * ti[k] * tu;
                const float pn = std::sqrt(pr * pr + pi * pi);
                if (pn < 1e-6f) { pr = 1.0f; pi = 0.0f; } else { pr /= pn; pi /= pn; }
                yr[k] = mag * pr;
                yi[k] = mag * pi;
                yEnergy += mag * mag;
            }
            // Match the guitar's loudness (smoothed so it does not pump).
            const float target = yEnergy > 1e-12f ? std::sqrt(gEnergy / yEnergy) : 0.0f;
            const float clampT = std::min(target, 8.0f);
            gainSmooth[s] += (clampT - gainSmooth[s]) * 0.5f;
            const float g = gainSmooth[s] * pulse;
            for (int k = 1; k < kBins - 1; ++k) { yr[k] *= g; yi[k] *= g; }
            yr[0] = yi[0] = 0.0f;
        }
        guitar.synthesize();
    }
};

typedef Pool<CrossSynthEngine, 32> CrossSynthPool;

}  // namespace rtal

static inline int rtal_xs_open_fn() { return rtal::CrossSynthPool::open(); }
#define rtal_xs_open rtal_xs_open_fn()

// Guitar sample and two texture samples in; returns the left output.
static inline float rtal_xs_process(int h, float g, float t0, float t1, float imprint, float keep, float colour,
                                    float phaseBlend, float smoothing)
{
    rtal::DenormalGuard guard;
    return rtal::CrossSynthPool::slot(h)->process(g, t0, t1, imprint, keep, colour, phaseBlend, smoothing);
}

// Right output of the latest sample. 'tie' orders the call after process.
static inline float rtal_xs_right(int h, float tie)
{
    (void)tie;
    return rtal::CrossSynthPool::slot(h)->outR;
}

#endif
