// Engine for rtal-auto-expression: hears how a note is played and reports six
// performance gestures as smooth 0..1 controls.
//
//   Pick Force  how hard the latest note was picked (its attack level)
//   Palm Mute   how quickly the note dies away and how dark it is
//   Bend        how far the pitch has been pushed above where the note started
//   Vibrato     depth of periodic pitch wobble (4-9 Hz)
//   Slide       pitch travelling quickly between notes without a new pick
//   Sustain     how long the current note has been ringing
//
// Pitch comes from a YIN estimator running on a 4x decimated copy of the
// signal (so it is cheap), notes are segmented at pick attacks, and every
// gesture is measured relative to the start of the current note.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_EXPRESSION_H
#define RTAL_EXPRESSION_H

#include "rtal_spectral_core.h"

namespace rtal {

// Second-order Butterworth lowpass (RBJ biquad), used before decimation.
struct Biquad {
    float b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0, z1 = 0, z2 = 0;
    void lowpass(float fc, float sr)
    {
        const float w = kTwoPi * fc / sr, c = std::cos(w), s = std::sin(w), alpha = s / (2.0f * 0.7071f);
        const float a0 = 1.0f + alpha;
        b0 = (1.0f - c) * 0.5f / a0; b1 = (1.0f - c) / a0; b2 = b0;
        a1 = -2.0f * c / a0; a2 = (1.0f - alpha) / a0;
    }
    float run(float x)
    {
        const float y = b0 * x + z1;
        z1 = b1 * x - a1 * y + z2;
        z2 = b2 * x - a2 * y;
        return y;
    }
};

struct ExpressionEngine {
    static const int kWin = 512;   // YIN window at the decimated rate
    static const int kFrame = 64;  // decimated samples per analysis frame
    enum { kForce = 0, kPalm, kBend, kVibrato, kSlide, kSustain, kGestures };

    float gesture[kGestures];
    std::vector<float> ds, diff;
    Biquad lp1, lp2;
    int dsPos = 0, decim = 4, decimCount = 0, frameCount = 0;
    float sr = 0.0f, dsRate = 12000.0f;
    // Envelope state over a frame
    float frameEnergy = 0.0f, hfEnergy = 0.0f, hpState = 0.0f;
    int frameSamples = 0;
    // Note state
    bool noteOn = false;
    float noteAge = 0.0f, peakDb = -120.0f, lastDb = -120.0f, minRecentDb = -120.0f, refractory = 0.0f;
    float startPitch = 0.0f, pitchSum = 0.0f;
    int pitchCount = 0;
    float hfAccum = 0.0f, totalAccum = 0.0f;
    float slowDev = 0.0f, fastDev = 0.0f, vibPower = 0.0f, lastPitch = 0.0f, pitchRate = 0.0f;
    float crossings = 0.0f, crossRate = 0.0f;
    int wobSign = 0;
    float dbHistory[4];

    void reset()
    {
        ds.assign(kWin, 0.0f);
        diff.assign(kWin / 2 + 1, 0.0f);
        for (float& g : gesture) g = 0.0f;
        dsPos = 0; decimCount = 0; frameCount = 0; sr = 0.0f;
        frameEnergy = hfEnergy = hpState = 0.0f; frameSamples = 0;
        noteOn = false; noteAge = 0.0f; peakDb = lastDb = minRecentDb = -120.0f; refractory = 0.0f;
        startPitch = 0.0f; pitchSum = 0.0f; pitchCount = 0; hfAccum = totalAccum = 0.0f;
        slowDev = fastDev = vibPower = lastPitch = pitchRate = 0.0f;
        crossings = crossRate = 0.0f; wobSign = 0;
        for (float& d : dbHistory) d = -120.0f;
    }

    void configure(float rate)
    {
        sr = rate;
        decim = std::max(1, int(std::lround(rate / 12000.0f)));
        dsRate = rate / decim;
        lp1.lowpass(dsRate * 0.42f, rate);
        lp2.lowpass(dsRate * 0.42f, rate);
    }

    // YIN pitch on the decimated window; returns MIDI pitch or 0 when unvoiced.
    float yin() const
    {
        const int tauMin = std::max(2, int(dsRate / 1100.0f));
        const int tauMax = std::min(kWin / 2 - 2, int(dsRate / 72.0f));
        const int len = kWin - tauMax;
        float* d = const_cast<float*>(diff.data());
        d[0] = 1.0f;
        float running = 0.0f;
        for (int tau = 1; tau <= tauMax; ++tau) {
            float s = 0.0f;
            for (int j = 0; j < len; ++j) {
                const float a = ds[(dsPos + j) % kWin] - ds[(dsPos + j + tau) % kWin];
                s += a * a;
            }
            running += s;
            d[tau] = running > 0.0f ? s * tau / running : 1.0f;
        }
        int best = -1;
        for (int tau = tauMin; tau < tauMax; ++tau) {
            if (d[tau] < 0.15f) {
                while (tau + 1 < tauMax && d[tau + 1] < d[tau]) ++tau;
                best = tau;
                break;
            }
        }
        if (best < 0) return 0.0f;
        const float y0 = d[best - 1], y1 = d[best], y2 = d[best + 1];
        const float den = y0 - 2.0f * y1 + y2;
        const float t = best + (den > 0.0f ? 0.5f * (y0 - y2) / den : 0.0f);
        return hzToMidi(dsRate / t, 440.0f);
    }

    static float clamp01(float x) { return std::min(1.0f, std::max(0.0f, x)); }

    void frame(float sensitivity)
    {
        const float hop = float(frameSamples) / sr;  // seconds per frame
        const float rms = std::sqrt(frameEnergy / std::max(1, frameSamples));
        const float db = 20.0f * std::log10(rms + 1e-9f);
        const float hfShare = hfEnergy / (frameEnergy + 1e-12f);
        frameEnergy = hfEnergy = 0.0f;
        frameSamples = 0;
        const float gateDb = -58.0f + 20.0f * (1.0f - sensitivity);

        // Onset: a clear rise above the recent minimum.
        float recentMin = dbHistory[0];
        for (float v : dbHistory) recentMin = std::min(recentMin, v);
        for (int i = 3; i > 0; --i) dbHistory[i] = dbHistory[i - 1];
        dbHistory[0] = db;
        refractory -= hop;
        const bool onset = db > gateDb && db - recentMin > 6.0f && refractory <= 0.0f;
        if (onset) {
            noteOn = true; noteAge = 0.0f; peakDb = db; refractory = 0.06f;
            pitchSum = 0.0f; pitchCount = 0; startPitch = 0.0f; hfAccum = totalAccum = 0.0f;
            slowDev = 0.0f; fastDev = 0.0f; vibPower = 0.0f;
            gesture[kPalm] = 0.0f;
        }
        if (noteOn) {
            noteAge += hop;
            if (noteAge < 0.04f) peakDb = std::max(peakDb, db);
            if (db < gateDb - 6.0f || db < peakDb - 45.0f) noteOn = false;
        }
        lastDb = db;

        // Pick force: attack level of the current note.
        if (noteOn && noteAge < 0.045f) gesture[kForce] = clamp01((peakDb + 40.0f) / 32.0f);

        // Palm mute: fast decay and a dark tone shortly after the attack.
        if (noteOn && noteAge > 0.025f && noteAge < 0.12f) { hfAccum += hfShare; totalAccum += 1.0f; }
        if (noteOn && noteAge > 0.09f && noteAge < 0.35f) {
            const float decay = (peakDb - db) / (noteAge - 0.02f);   // dB per second
            const float dark = totalAccum > 0.0f ? clamp01((0.10f - hfAccum / totalAccum) / 0.08f) : 0.0f;
            const float est = clamp01((decay - 18.0f) / 40.0f) * (0.55f + 0.45f * dark);
            gesture[kPalm] += (est - gesture[kPalm]) * 0.5f;
        }

        // Pitch gestures (single notes only: YIN fails on chords, which is fine).
        const float pitch = (db > gateDb && noteOn) ? yin() : 0.0f;
        if (pitch > 0.0f && noteAge > 0.02f) {
            if (pitchCount < 4) {
                pitchSum += pitch; ++pitchCount;
                startPitch = pitchSum / pitchCount;
            }
            const float dev = pitch - startPitch;
            const float a = 1.0f - std::exp(-hop / 0.15f);
            slowDev += (dev - slowDev) * a;
            // Vibrato band: fast-smoothed minus slow-smoothed pitch.
            fastDev += (dev - fastDev) * (1.0f - std::exp(-hop / 0.015f));
            const float wob = fastDev - slowDev;
            vibPower += (wob * wob - vibPower) * (1.0f - std::exp(-hop / 0.3f));
            // Count direction changes of the wobble (with 4 cent hysteresis):
            // real vibrato turns around 6-20 times a second, a bend does not.
            if ((wobSign >= 0 && wob < -0.04f) || (wobSign <= 0 && wob > 0.04f)) {
                if (wobSign != 0) crossings += 1.0f;
                wobSign = wob > 0.0f ? 1 : -1;
            }
            if (lastPitch > 0.0f) pitchRate += ((pitch - lastPitch) / hop - pitchRate) * 0.4f;
            lastPitch = pitch;
            // Beyond a whole-step-and-a-bit it is a slide, not a bend.
            gesture[kBend] = (pitchCount >= 4 && slowDev < 2.6f) ? clamp01(slowDev / 2.0f) : gesture[kBend] * 0.8f;
            const float rate = crossRate;
            const float periodic = clamp01((rate - 4.0f) / 3.0f) * clamp01((24.0f - rate) / 4.0f);
            gesture[kVibrato] = clamp01((std::sqrt(vibPower) * 100.0f - 4.0f) / 20.0f) * periodic;
            const bool travelled = slowDev < -0.6f || slowDev > 2.5f;
            if (pitchCount >= 4 && travelled && std::fabs(pitchRate) > 6.0f)
                gesture[kSlide] = std::max(gesture[kSlide], clamp01(std::fabs(pitchRate) / 30.0f));
        } else {
            lastPitch = 0.0f;
            pitchRate = 0.0f;
            gesture[kBend] *= 0.9f;
            gesture[kVibrato] *= 0.9f;
        }
        gesture[kSlide] *= std::exp(-hop / 0.25f);
        crossRate += (crossings / hop - crossRate) * (1.0f - std::exp(-hop / 0.4f));
        crossings = 0.0f;
        if (onset) startPitch = 0.0f;

        // Sustain: how long the note has rung (0 at the pick, 1 after ~3 s).
        gesture[kSustain] = noteOn ? clamp01((noteAge - 0.3f) / 2.7f) : gesture[kSustain] * 0.95f;
    }

    void process(float x, float rate, float sensitivity)
    {
        if (!(rate > 1000.0f)) rate = 48000.0f;
        if (rate != sr) configure(rate);
        if (!finite(x)) x = 0.0f;
        frameEnergy += x * x;
        hpState += (x - hpState) * (1.0f - std::exp(-kTwoPi * 2000.0f / sr));
        const float hp = x - hpState;
        hfEnergy += hp * hp;
        ++frameSamples;
        const float y = lp2.run(lp1.run(x));
        if (++decimCount < decim) return;
        decimCount = 0;
        ds[dsPos] = y;
        dsPos = (dsPos + 1) % kWin;
        if (++frameCount < kFrame) return;
        frameCount = 0;
        frame(sensitivity);
    }
};

typedef Pool<ExpressionEngine, 32> ExpressionPool;

}  // namespace rtal

static inline int rtal_ae_open_fn() { return rtal::ExpressionPool::open(); }
#define rtal_ae_open rtal_ae_open_fn()

// Feeds one sample; returns the Pick Force gesture.
static inline float rtal_ae_process(int h, float x, float sr, float sensitivity)
{
    rtal::DenormalGuard guard;
    rtal::ExpressionEngine* e = rtal::ExpressionPool::slot(h);
    e->process(x, sr, sensitivity);
    return e->gesture[0];
}

// Gesture 0..5 (force, palm, bend, vibrato, slide, sustain). 'tie' orders the call after process.
static inline float rtal_ae_gesture(int h, int which, float tie)
{
    (void)tie;
    return rtal::ExpressionPool::slot(h)->gesture[std::min(std::max(which, 0), 5)];
}

#endif
