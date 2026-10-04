// Live tempo and beat tracking from a guitar signal, with no host clock.
//
//  1. Onset strength: the signal is split into four bands; each band's
//     log-energy rise per 256-sample frame is summed and an adaptive mean is
//     removed, giving a curve that spikes on every pick or strum.
//  2. Tempo: every quarter second the autocorrelation of the last six seconds
//     of onset strength is scored with a comb (lags at 1, 2, 3 and 4 beats,
//     plus half-beats) across the allowed tempo range, weighted by a gentle
//     prior around 110 BPM so octave errors stay rare. A new tempo must win
//     repeatedly before it replaces the current one.
//  3. Phase: the recent onset curve is matched against a pulse train at the
//     current tempo (beats strong, eighths weaker); the best alignment pulls a
//     free-running beat clock gradually into place, like a phase-locked loop.
//  4. Bar: accents and chord changes are accumulated per beat of a 4/4 bar to
//     choose which beat is the downbeat.
//
// When the playing stops, the clock keeps running at the last tempo.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_TEMPO_H
#define RTAL_TEMPO_H

#include "rtal_spectral_core.h"

namespace rtal {

class TempoTracker {
public:
    static const int kHop = 256;
    static const int kHistory = 1200;  // frames (~6.4 s at 48 kHz)

    void reset()
    {
        odf.assign(kHistory, 0.0f);
        acf.assign(kHistory / 2, 0.0f);
        odfPos = 0; hopCount = 0; frames = 0;
        for (int b = 0; b < 4; ++b) { bandState[b][0] = bandState[b][1] = 0.0f; bandEnergy[b] = 0.0f; prevLog[b] = 0.0f; }
        meanOdf = 0.0f; frameEnergy = 0.0f; level = 0.0f;
        bpm = 110.0f; candidateBpm = 0.0f; candidateWins = 0; confidence = 0.0f;
        beatPhase = 0.0f; beatCount = 0; pendingCorrection = 0.0f;
        for (int i = 0; i < 4; ++i) barEvidence[i] = 0.0f;
        downbeat = 0; downbeatCandidate = 0; downbeatWins = 0; lastOdf = 0.0f; prevOdf = 0.0f; onsetFlag = false; sinceEstimate = 0;
        chordChangeFlag = false;
    }

    // Per-sample update. Returns true when a frame was completed.
    bool push(float x, float sr, int mode, float manualBpm, float minBpm, float maxBpm, float sensitivity)
    {
        if (!finite(x)) x = 0.0f;
        sr_ = sr;
        // Four-band split with one-pole filters (cheap; only energy matters).
        const float a1 = std::exp(-kTwoPi * 200.0f / sr), a2 = std::exp(-kTwoPi * 900.0f / sr),
                    a3 = std::exp(-kTwoPi * 3500.0f / sr);
        bandState[0][0] = x + (bandState[0][0] - x) * a1;   // < 200
        bandState[1][0] = x + (bandState[1][0] - x) * a2;   // < 900
        bandState[2][0] = x + (bandState[2][0] - x) * a3;   // < 3500
        const float b0 = bandState[0][0];
        const float b1 = bandState[1][0] - b0;
        const float b2 = bandState[2][0] - bandState[1][0];
        const float b3 = x - bandState[2][0];
        bandEnergy[0] += b0 * b0; bandEnergy[1] += b1 * b1; bandEnergy[2] += b2 * b2; bandEnergy[3] += b3 * b3;
        frameEnergy += x * x;

        // Beat clock, per sample.
        // Phase corrections speed the clock up or slow it down by at most 40%,
        // so it never runs backwards (which would re-fire rhythmic steps).
        const float nominal = bpm / 60.0f / sr;
        float inc = nominal;
        if (pendingCorrection != 0.0f) {
            float step = pendingCorrection * 0.0006f;
            step = std::min(std::max(step, -0.4f * nominal), 0.4f * nominal);
            inc += step;
            pendingCorrection -= step;
        }
        beatPhase += inc;
        while (beatPhase >= 1.0f) { beatPhase -= 1.0f; beatCount = (beatCount + 1) & 3; onBeat(); }
        while (beatPhase < 0.0f) { beatPhase += 1.0f; beatCount = (beatCount + 3) & 3; }

        if (++hopCount < kHop) return false;
        hopCount = 0;
        frame(mode, manualBpm, minBpm, maxBpm, sensitivity);
        return true;
    }

    // Tell the tracker a chord change happened now (adds downbeat evidence).
    void chordChanged() { chordChangeFlag = true; }

    // Position in the bar, 0..4 (beats), with the detected downbeat at 0.
    float barPosition() const
    {
        const int beatInBar = (beatCount - downbeat + 4) & 3;
        return beatInBar + beatPhase;
    }

    float bpm = 110.0f, confidence = 0.0f, level = 0.0f, lastOdf = 0.0f;
    bool onsetFlag = false;

private:
    void onBeat()
    {
        for (int i = 0; i < 4; ++i) barEvidence[i] *= 0.97f;
    }

    float frameRate() const { return sr_ / kHop; }

    void frame(int mode, float manualBpm, float minBpm, float maxBpm, float sensitivity)
    {
        // Onset strength.
        const float floorE = 1e-7f;
        float flux = 0.0f;
        static const float weight[4] = {0.8f, 1.0f, 1.2f, 1.0f};
        for (int b = 0; b < 4; ++b) {
            const float lg = std::log(floorE + bandEnergy[b] / kHop);
            const float rise = lg - prevLog[b];
            if (rise > 0.0f) flux += rise * weight[b];
            prevLog[b] = lg;
            bandEnergy[b] = 0.0f;
        }
        const float rms = std::sqrt(frameEnergy / kHop);
        frameEnergy = 0.0f;
        level += (rms - level) * 0.05f;
        // Ignore the noise floor: scale by how far the frame is above -60..-40 dBFS.
        const float gateDb = -62.0f + 24.0f * (1.0f - sensitivity);
        const float db = 20.0f * std::log10(rms + 1e-9f);
        const float gate = std::min(1.0f, std::max(0.0f, (db - gateDb) / 12.0f));
        flux *= gate;
        meanOdf += (flux - meanOdf) * 0.02f;
        const float o = std::max(0.0f, flux - meanOdf * 1.2f);
        odf[odfPos] = o;
        odfPos = (odfPos + 1) % kHistory;
        ++frames;
        // Onset flag on local maxima well above the running mean.
        onsetFlag = (prevOdf > lastOdf && prevOdf > o && prevOdf > 0.5f) ;
        if (onsetFlag) {
            // Accent evidence for the beat this onset sits on.
            const float ph = beatPhase;
            if (ph < 0.12f || ph > 0.88f) {
                const int beat = (ph > 0.5f) ? ((beatCount + 1) & 3) : beatCount;
                barEvidence[beat] += prevRms * 4.0f;
            }
        }
        if (chordChangeFlag) {
            const int beat = (beatPhase > 0.5f) ? ((beatCount + 1) & 3) : beatCount;
            barEvidence[beat] += 2.0f;
            chordChangeFlag = false;
        }
        prevOdf = lastOdf;
        lastOdf = o;
        prevRms = std::max(rms, lastRms);
        lastRms = rms;

        if (mode == 2) {  // manual tempo, free-running clock
            bpm = std::min(std::max(manualBpm, 30.0f), 300.0f);
            return;
        }
        if (++sinceEstimate * kHop < sr_ * 0.25f) return;
        sinceEstimate = 0;
        if (frames < kHistory / 3) return;
        // Is anyone playing? Hold everything when the recent onset curve is flat.
        float recent = 0.0f;
        const int span = int(frameRate() * 2.0f);
        for (int i = 1; i <= span; ++i) recent += odf[(odfPos - i + kHistory) % kHistory];
        if (recent < 0.5f) return;
        if (mode == 0) estimateTempo(minBpm, maxBpm);
        estimatePhase();
        // A new downbeat must clearly beat the current one for two seconds:
        // moving it shifts the bar by whole beats, so it should be rare.
        int best = downbeat;
        for (int i = 0; i < 4; ++i)
            if (barEvidence[i] > barEvidence[best] * 1.3f) best = i;
        if (best != downbeat) {
            if (best == downbeatCandidate) {
                if (++downbeatWins >= 8) { downbeat = best; downbeatWins = 0; }
            } else {
                downbeatCandidate = best;
                downbeatWins = 1;
            }
        } else {
            downbeatWins = 0;
        }
    }

    float acfAt(float lag) const
    {
        const int i = int(lag);
        const float f = lag - i;
        if (i < 1 || i + 1 >= int(acf.size())) return 0.0f;
        return acf[i] * (1.0f - f) + acf[i + 1] * f;
    }

    void estimateTempo(float minBpm, float maxBpm)
    {
        const int n = kHistory;
        const int maxLag = int(acf.size()) - 1;
        // Unbiased autocorrelation of the onset history.
        for (int lag = 1; lag <= maxLag; ++lag) {
            float s = 0.0f;
            for (int i = lag; i < n; ++i) s += odf[(odfPos + i) % n] * odf[(odfPos + i - lag) % n];
            acf[lag] = s / (n - lag);
        }
        if (!(minBpm >= 30.0f)) minBpm = 60.0f;
        if (!(maxBpm > minBpm + 5.0f)) maxBpm = minBpm + 5.0f;
        maxBpm = std::min(maxBpm, 240.0f);
        const float fr = frameRate();
        float best = 0.0f, bestBpm = bpm, total = 0.0f;
        int count = 0;
        for (float b = minBpm; b <= maxBpm; b += 0.25f) {
            const float lag = fr * 60.0f / b;
            if (lag * 4.0f >= maxLag) continue;
            float s = acfAt(lag) + 0.6f * acfAt(2.0f * lag) + 0.25f * acfAt(3.0f * lag) + 0.9f * acfAt(4.0f * lag)
                      + 0.35f * acfAt(0.5f * lag);
            const float oct = std::log2(b / 110.0f);
            s *= std::exp(-0.5f * oct * oct / (0.85f * 0.85f));
            total += s; ++count;
            if (s > best) { best = s; bestBpm = b; }
        }
        if (count == 0 || best <= 0.0f) return;
        confidence = std::min(1.0f, (best / (total / count) - 1.0f) / 3.0f);
        // Refine with a parabola around the best tempo.
        {
            auto sc = [&](float b) {
                const float lag = fr * 60.0f / b;
                return acfAt(lag) + 0.6f * acfAt(2.0f * lag) + 0.25f * acfAt(3.0f * lag) + 0.9f * acfAt(4.0f * lag);
            };
            const float y0 = sc(bestBpm - 0.25f), y1 = sc(bestBpm), y2 = sc(bestBpm + 0.25f);
            const float d = y0 - 2.0f * y1 + y2;
            if (d < 0.0f) bestBpm += 0.25f * 0.5f * (y0 - y2) / d;
        }
        if (std::fabs(bestBpm - bpm) / bpm < 0.04f) {
            bpm += (bestBpm - bpm) * 0.35f;
            candidateWins = 0;
        } else if (candidateWins > 0 && std::fabs(bestBpm - candidateBpm) / candidateBpm < 0.04f) {
            if (++candidateWins >= 3) { bpm = bestBpm; candidateWins = 0; }
        } else {
            candidateBpm = bestBpm;
            candidateWins = 1;
        }
    }

    void estimatePhase()
    {
        const float fr = frameRate();
        const float beatLen = fr * 60.0f / bpm;
        const int window = std::min(kHistory - 2, int(beatLen * 4.0f));
        const int offsets = std::max(2, int(beatLen));
        float best = -1.0f;
        int bestO = 0;
        for (int o = 0; o < offsets; ++o) {
            float s = 0.0f;
            for (float t = float(o); t < window; t += beatLen) {
                s += sample(t);
                s += 0.5f * sample(t + beatLen * 0.5f);
            }
            // Continuity prior: once locked, prefer alignments near the current
            // beat so evenly accented eighths cannot flip it to the off-beat.
            const float nowAgo = beatPhase * beatLen;
            s *= 1.0f + 0.3f * std::cos(kTwoPi * (o - nowAgo) / beatLen);
            if (s > best) { best = s; bestO = o; }
        }
        if (best <= 0.0f) return;
        // The most recent beat happened bestO frames ago (plus the frame in progress).
        const float target = (bestO + float(hopCount) / kHop + 0.5f) / beatLen;
        const float err = wrapPhase((target - beatPhase) * kTwoPi) / kTwoPi;
        pendingCorrection = err * 0.5f;
    }

    // Onset strength 'ago' frames back (fractional, linear interpolation).
    float sample(float ago) const
    {
        const int i = int(ago);
        const float f = ago - i;
        const float a = odf[(odfPos - 1 - i + 2 * kHistory) % kHistory];
        const float b = odf[(odfPos - 2 - i + 2 * kHistory) % kHistory];
        return a * (1.0f - f) + b * f;
    }

    std::vector<float> odf, acf;
    int odfPos = 0, hopCount = 0, frames = 0, sinceEstimate = 0;
    float bandState[4][2];
    float bandEnergy[4], prevLog[4];
    float meanOdf = 0.0f, frameEnergy = 0.0f, prevOdf = 0.0f, prevRms = 0.0f, lastRms = 0.0f;
    float candidateBpm = 0.0f;
    int candidateWins = 0;
    float beatPhase = 0.0f, pendingCorrection = 0.0f;
    int beatCount = 0, downbeat = 0, downbeatCandidate = 0, downbeatWins = 0;
    float barEvidence[4];
    bool chordChangeFlag = false;
    float sr_ = 48000.0f;
};

}  // namespace rtal

#endif
