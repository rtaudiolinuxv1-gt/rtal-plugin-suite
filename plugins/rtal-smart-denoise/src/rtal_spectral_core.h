// Shared spectral building blocks for RTAL plugins that need frequency-domain
// processing: a radix-2 FFT, a short-time Fourier transform frame buffer with
// overlap-add resynthesis, and a per-instance state pool.
//
// Faust has no native STFT, so these plugins call a C++ engine through
// ffunction once per sample. Each plugin instance obtains its own engine slot
// through an fconstant that Faust evaluates in instanceConstants(), i.e. once
// per instance initialisation, so two instances never share state. Slots are
// allocated on first use (outside the audio thread) and reused round-robin.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_SPECTRAL_CORE_H
#define RTAL_SPECTRAL_CORE_H

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <vector>
#if defined(__SSE__) || defined(_M_X64) || defined(_M_IX86)
#include <xmmintrin.h>
#define RTAL_HAVE_MXCSR 1
#endif

namespace rtal {

static const float kPi = 3.14159265358979f;
static const float kTwoPi = 6.28318530717959f;

static inline float wrapPhase(float p)
{
    p = std::fmod(p + kPi, kTwoPi);
    if (p < 0.0f) p += kTwoPi;
    return p - kPi;
}

static inline bool finite(float x) { return std::isfinite(x); }

// Flush denormals to zero for the lifetime of the guard. Decaying signals in
// the spectral engines would otherwise reach denormal range in the silence
// after playing and cost many times the normal CPU. The previous mode is
// restored on exit, so the host's own settings are untouched.
struct DenormalGuard {
#ifdef RTAL_HAVE_MXCSR
    unsigned int saved;
    DenormalGuard() : saved(_mm_getcsr()) { _mm_setcsr(saved | 0x8040u); }  // FTZ | DAZ
    ~DenormalGuard() { _mm_setcsr(saved); }
#else
    DenormalGuard() {}
#endif
};

// In-place iterative radix-2 complex FFT of a fixed power-of-two size.
class Fft {
public:
    explicit Fft(int n = 0) { setup(n); }
    void setup(int n)
    {
        n_ = n;
        if (n <= 0) return;
        rev_.assign(n, 0);
        int bits = 0;
        while ((1 << bits) < n) ++bits;
        for (int i = 0; i < n; ++i) {
            int r = 0;
            for (int b = 0; b < bits; ++b)
                if (i & (1 << b)) r |= 1 << (bits - 1 - b);
            rev_[i] = r;
        }
        cosT_.resize(n / 2);
        sinT_.resize(n / 2);
        for (int i = 0; i < n / 2; ++i) {
            cosT_[i] = std::cos(kTwoPi * i / n);
            sinT_[i] = std::sin(kTwoPi * i / n);
        }
    }
    int size() const { return n_; }
    // inverse = true computes the unscaled inverse transform.
    void run(float* re, float* im, bool inverse) const
    {
        const int n = n_;
        for (int i = 0; i < n; ++i) {
            const int j = rev_[i];
            if (j > i) {
                float t = re[i]; re[i] = re[j]; re[j] = t;
                t = im[i]; im[i] = im[j]; im[j] = t;
            }
        }
        const float sign = inverse ? 1.0f : -1.0f;
        for (int len = 2; len <= n; len <<= 1) {
            const int half = len >> 1;
            const int step = n / len;
            for (int start = 0; start < n; start += len) {
                for (int k = 0; k < half; ++k) {
                    const float wr = cosT_[k * step];
                    const float wi = sign * sinT_[k * step];
                    const int a = start + k, b = a + half;
                    const float xr = re[b] * wr - im[b] * wi;
                    const float xi = re[b] * wi + im[b] * wr;
                    re[b] = re[a] - xr; im[b] = im[a] - xi;
                    re[a] += xr; im[a] += xi;
                }
            }
        }
    }
private:
    int n_ = 0;
    std::vector<int> rev_;
    std::vector<float> cosT_, sinT_;
};

// Real-input FFT of size N computed with one complex FFT of size N/2.
// forward: x[0..N) -> re/im[0..N/2]. inverse: re/im[0..N/2] -> x[0..N),
// unscaled (the result is N times the original), matching Fft::run.
class RealFft {
public:
    void setup(int n)
    {
        n_ = n;
        half_.setup(n / 2);
        zr_.assign(n / 2, 0.0f);
        zi_.assign(n / 2, 0.0f);
        wr_.resize(n / 2 + 1);
        wi_.resize(n / 2 + 1);
        for (int k = 0; k <= n / 2; ++k) {
            wr_[k] = std::cos(kTwoPi * k / n);
            wi_[k] = -std::sin(kTwoPi * k / n);
        }
    }
    int size() const { return n_; }
    void forward(const float* x, float* re, float* im)
    {
        const int h = n_ / 2;
        for (int i = 0; i < h; ++i) { zr_[i] = x[2 * i]; zi_[i] = x[2 * i + 1]; }
        half_.run(zr_.data(), zi_.data(), false);
        for (int k = 0; k <= h; ++k) {
            const int a = k % h, b = (h - k) % h;
            const float er = 0.5f * (zr_[a] + zr_[b]), ei = 0.5f * (zi_[a] - zi_[b]);
            const float orr = 0.5f * (zi_[a] + zi_[b]), oi = -0.5f * (zr_[a] - zr_[b]);
            re[k] = er + wr_[k] * orr - wi_[k] * oi;
            im[k] = ei + wr_[k] * oi + wi_[k] * orr;
        }
    }
    void inverse(const float* re, const float* im, float* x)
    {
        const int h = n_ / 2;
        for (int k = 0; k < h; ++k) {
            const int b = h - k;
            const float er = 0.5f * (re[k] + re[b]), ei = 0.5f * (im[k] - im[b]);
            const float dr = 0.5f * (re[k] - re[b]), di = 0.5f * (im[k] + im[b]);
            // odd part = d * conj(W^k)
            const float orr = dr * wr_[k] + di * wi_[k];
            const float oi = di * wr_[k] - dr * wi_[k];
            zr_[k] = er - oi;
            zi_[k] = ei + orr;
        }
        half_.run(zr_.data(), zi_.data(), true);
        for (int i = 0; i < h; ++i) { x[2 * i] = 2.0f * zr_[i]; x[2 * i + 1] = 2.0f * zi_[i]; }
    }
private:
    int n_ = 0;
    Fft half_;
    std::vector<float> zr_, zi_, wr_, wi_;
};

// Short-time Fourier analysis with sqrt-Hann windows and overlap-add
// resynthesis into any number of output streams. Call push() once per sample;
// it returns true when a new analysis frame is ready in re/im (bins 0..N/2;
// the arrays are N long but only the lower half is meaningful).
// The owner then fills the synthesis spectra (outRe/outIm per stream) and calls
// synthesize(). read(stream) gives the current output sample of a stream.
class Stft {
public:
    void setup(int n, int hop, int streams)
    {
        n_ = n; hop_ = hop; streams_ = streams;
        fft.setup(n);
        rfft.setup(n);
        frame.assign(n, 0.0f);
        win.resize(n);
        for (int i = 0; i < n; ++i) win[i] = std::sqrt(0.5f - 0.5f * std::cos(kTwoPi * i / n));
        // sqrt-Hann analysis x synthesis = Hann; overlap n/hop Hann windows sum to n/(2*hop).
        olaGain = 2.0f * hop / n / n;  // also folds in the 1/n of the inverse FFT
        in.assign(n, 0.0f);
        re.assign(n, 0.0f); im.assign(n, 0.0f);
        outRe.assign(streams, std::vector<float>(n, 0.0f));
        outIm.assign(streams, std::vector<float>(n, 0.0f));
        acc.assign(streams, std::vector<float>(n, 0.0f));
        inPos = 0; hopCount = 0; readPos = 0;
    }
    int size() const { return n_; }
    int hop() const { return hop_; }
    bool push(float x)
    {
        ++readPos;
        in[inPos] = finite(x) ? x : 0.0f;
        inPos = (inPos + 1) % n_;
        if (++hopCount < hop_) return false;
        hopCount = 0;
        for (int i = 0; i < n_; ++i) frame[i] = in[(inPos + i) % n_] * win[i];
        rfft.forward(frame.data(), re.data(), im.data());
        for (int s = 0; s < streams_; ++s) {
            std::fill(outRe[s].begin(), outRe[s].end(), 0.0f);
            std::fill(outIm[s].begin(), outIm[s].end(), 0.0f);
        }
        return true;
    }
    // Inverse-transform every stream's spectrum (bins 0..N/2 set by the owner;
    // the upper half is mirrored here) and overlap-add it.
    // 'count' limits how many streams are resynthesised (default: all).
    void synthesize(int count = -1)
    {
        const int active = (count < 0 || count > streams_) ? streams_ : count;
        for (int s = 0; s < active; ++s) {
            std::vector<float>& a = acc[s];
            // The first hop samples were played out since the last frame.
            std::memmove(a.data(), a.data() + hop_, sizeof(float) * (n_ - hop_));
            std::fill(a.begin() + (n_ - hop_), a.end(), 0.0f);
            float* r = outRe[s].data();
            float* m = outIm[s].data();
            m[0] = 0.0f;
            m[n_ / 2] = 0.0f;
            rfft.inverse(r, m, frame.data());
            for (int i = 0; i < n_; ++i) a[i] += frame[i] * win[i] * olaGain;
        }
        readPos = 0;
    }
    // Output sample 'readPos' samples after the latest synthesis.
    float read(int s) const
    {
        const float v = acc[s][readPos < hop_ ? readPos : hop_ - 1];
        return finite(v) ? v : 0.0f;
    }

    Fft fft;
    RealFft rfft;
    std::vector<float> win, in, re, im, frame;
    std::vector<std::vector<float>> outRe, outIm, acc;
    float olaGain = 1.0f;

private:
    int n_ = 0, hop_ = 0, streams_ = 0;
    int inPos = 0, hopCount = 0, readPos = 0;
};

// Per-frame spectral analysis on top of an Stft frame: magnitude, phase,
// instantaneous frequency per bin (phase-vocoder estimate) and peak picking.
struct Peak {
    int bin;      // bin of the local maximum
    int lo, hi;   // region of influence (inclusive)
    float freq;   // instantaneous frequency, Hz
    float mag;    // linear magnitude at the peak
};

class Analysis {
public:
    void setup(int n, int hop)
    {
        n_ = n; hop_ = hop;
        mag.assign(n / 2 + 1, 0.0f);
        phase.assign(n / 2 + 1, 0.0f);
        prevPhase.assign(n / 2 + 1, 0.0f);
        freq.assign(n / 2 + 1, 0.0f);
        peaks.clear();
        peaks.reserve(n / 4);
    }
    // Fill mag/phase/freq from the frame in re/im. Magnitudes are normalised so
    // a full-scale sinusoid reads about 1.0.
    void analyse(const float* re, const float* im, float sr)
    {
        const int half = n_ / 2;
        const float norm = kPi / n_;  // sqrt-Hann coherent gain is 2N/pi
        const float binHz = sr / n_;
        for (int k = 0; k <= half; ++k) {
            const float m = std::sqrt(re[k] * re[k] + im[k] * im[k]) * norm;
            const float ph = std::atan2(im[k], re[k]);
            const float expected = kTwoPi * k * hop_ / n_;
            const float dev = wrapPhase(ph - prevPhase[k] - expected);
            prevPhase[k] = ph;
            phase[k] = ph;
            mag[k] = finite(m) ? m : 0.0f;
            freq[k] = (k + dev * n_ / (kTwoPi * hop_)) * binHz;
        }
    }
    // Local maxima above an absolute floor and within rangeDb of the loudest.
    void findPeaks(float floorMag, float rangeDb, float minHz, float maxHz, float sr)
    {
        peaks.clear();
        const int half = n_ / 2;
        float top = 0.0f;
        for (int k = 2; k < half - 2; ++k) top = std::max(top, mag[k]);
        const float thr = std::max(floorMag, top * std::pow(10.0f, -rangeDb / 20.0f));
        const float binHz = sr / n_;
        for (int k = 2; k < half - 2; ++k) {
            const float m = mag[k];
            if (m < thr || m <= mag[k - 1] || m < mag[k + 1] || m <= mag[k - 2] || m < mag[k + 2]) continue;
            const float f = freq[k];
            if (f < minHz || f > maxHz || std::fabs(f - k * binHz) > 1.5f * binHz) continue;
            peaks.push_back(Peak{k, k, k, f, m});
        }
        // Regions: split at the magnitude minimum between neighbouring peaks.
        for (size_t i = 0; i < peaks.size(); ++i) {
            int lo = (i == 0) ? std::max(1, peaks[i].bin - 8) : peaks[i - 1].bin;
            int hi = (i + 1 == peaks.size()) ? std::min(half - 1, peaks[i].bin + 8) : peaks[i + 1].bin;
            int a = peaks[i].bin, b = peaks[i].bin;
            while (a > lo + 1 && a > peaks[i].bin - 8 && mag[a - 1] <= mag[a]) --a;
            while (b < hi - 1 && b < peaks[i].bin + 8 && mag[b + 1] <= mag[b]) ++b;
            peaks[i].lo = a;
            peaks[i].hi = b;
        }
        for (size_t i = 1; i < peaks.size(); ++i)
            if (peaks[i].lo <= peaks[i - 1].hi) peaks[i].lo = peaks[i - 1].hi + 1;
    }

    std::vector<float> mag, phase, prevPhase, freq;
    std::vector<Peak> peaks;

private:
    int n_ = 0, hop_ = 0;
};

static inline float hzToMidi(float hz, float refA) { return 69.0f + 12.0f * std::log2(std::max(hz, 1.0f) / refA); }
static inline float midiToHz(float m, float refA) { return refA * std::pow(2.0f, (m - 69.0f) / 12.0f); }

// Round-robin pool of per-instance engines. T must be default-constructible.
template <class T, int Slots>
struct Pool {
    static T* slot(int h)
    {
        static T* slots[Slots] = {nullptr};
        h = ((h % Slots) + Slots) % Slots;
        if (!slots[h]) slots[h] = new T();
        return slots[h];
    }
    static int open()
    {
        static std::atomic<int> next{0};
        const int h = next.fetch_add(1) % Slots;
        slot(h)->reset();
        return h;
    }
};

// Small deterministic-per-activation random generator (xorshift32).
struct Rng {
    uint32_t s = 2463534242u;
    void seed(uint32_t v) { s = v ? v : 2463534242u; }
    float uni() { s ^= s << 13; s ^= s >> 17; s ^= s << 5; return (s >> 8) * (1.0f / 16777216.0f); }
};

static inline uint32_t entropySeed(const void* salt)
{
    uint64_t x = 0;
    static std::atomic<uint32_t> counter{0};
    x ^= uint64_t(reinterpret_cast<uintptr_t>(salt));
    x ^= uint64_t(counter.fetch_add(0x9E3779B9u)) << 21;
    x ^= uint64_t(reinterpret_cast<uintptr_t>(&x));
    x += 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    x ^= x >> 31;
    return uint32_t(x) | 1u;
}

}  // namespace rtal

#endif
