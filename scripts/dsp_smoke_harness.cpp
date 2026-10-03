// Offline smoke-test architecture for RTAL Faust plugins.
//
// Usage: faust -a scripts/dsp_smoke_harness.cpp -o test.cpp plugin.dsp
//        g++ -O2 -std=c++17 test.cpp -o test && ./test [--wav out_prefix]
//        ./test --probe sine:440 --set /group/Mix=1 --seconds 4 --out probe.wav
//
// Renders a synthetic guitar performance (plucked strings, strums, low-E chugs,
// full-scale bursts and a long silent tail) through the DSP for the default
// state, every factory preset, the all-min/all-max corners and a set of
// seeded random parameter states. Fails on NaN/Inf, runaway gain, dead output
// or a tail that never decays.

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <random>
#include <string>
#include <vector>

#include "faust/dsp/dsp.h"
#include "faust/gui/MapUI.h"
#include "faust/gui/meta.h"

<<includeIntrinsic>>

<<includeclass>>

namespace {

constexpr int kSampleRate = 48000;
constexpr int kBlock = 256;
constexpr double kPlaySeconds = 9.0;
constexpr double kTailSeconds = 7.0;

struct Param {
    std::string path;
    FAUSTFLOAT min;
    FAUSTFLOAT max;
    FAUSTFLOAT init;
    FAUSTFLOAT step;
};

struct ParamCollector : public MapUI {
    std::vector<Param> params;
    void add(const char* label, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
    {
        params.push_back({buildPath(label), min, max, init, step});
    }
    void addHorizontalSlider(const char* l, FAUSTFLOAT* z, FAUSTFLOAT i, FAUSTFLOAT mn, FAUSTFLOAT mx, FAUSTFLOAT s) override
    {
        add(l, i, mn, mx, s);
        MapUI::addHorizontalSlider(l, z, i, mn, mx, s);
    }
    void addVerticalSlider(const char* l, FAUSTFLOAT* z, FAUSTFLOAT i, FAUSTFLOAT mn, FAUSTFLOAT mx, FAUSTFLOAT s) override
    {
        add(l, i, mn, mx, s);
        MapUI::addVerticalSlider(l, z, i, mn, mx, s);
    }
    void addNumEntry(const char* l, FAUSTFLOAT* z, FAUSTFLOAT i, FAUSTFLOAT mn, FAUSTFLOAT mx, FAUSTFLOAT s) override
    {
        add(l, i, mn, mx, s);
        MapUI::addNumEntry(l, z, i, mn, mx, s);
    }
};

// Karplus-Strong pluck, good enough to look like a guitar to the DSP.
struct Pluck {
    std::vector<float> line;
    size_t pos = 0;
    float gain = 0.0f;
    float last = 0.0f;
    float decay = 0.996f;
    void trigger(double freq, float amp, std::mt19937& rng)
    {
        line.assign(std::max<size_t>(2, size_t(kSampleRate / freq)), 0.0f);
        std::uniform_real_distribution<float> d(-1.0f, 1.0f);
        for (auto& s : line) s = d(rng);
        pos = 0;
        gain = amp;
        decay = 0.9965f;
    }
    float tick()
    {
        if (line.empty()) return 0.0f;
        size_t next = (pos + 1) % line.size();
        float out = line[pos];
        line[pos] = decay * 0.5f * (line[pos] + line[next]);
        pos = next;
        last = out;
        return out * gain;
    }
};

std::vector<float> makeGuitar(int frames)
{
    std::mt19937 rng(1234);
    std::vector<float> out(frames, 0.0f);
    std::vector<Pluck> strings(6);
    const double tuning[6] = {82.41, 110.0, 146.83, 196.0, 246.94, 329.63};
    int playFrames = int(kPlaySeconds * kSampleRate);
    for (int n = 0; n < frames; ++n) {
        double t = double(n) / kSampleRate;
        if (n < playFrames) {
            int beat = int(t * 4.0);
            int beatStart = int(beat * kSampleRate / 4.0);
            if (n == beatStart) {
                if (t < 3.0) {
                    // single-note melody
                    int s = (beat * 5) % 6;
                    strings[s].trigger(tuning[s] * std::pow(2.0, ((beat * 7) % 12) / 12.0), 0.45f, rng);
                } else if (t < 6.0) {
                    // strummed chords (staggered strings)
                    for (int s = 0; s < 6; ++s) strings[s].trigger(tuning[s] * (beat % 2 ? 1.122 : 1.0), 0.22f, rng);
                } else if (t < 8.0) {
                    // palm-muted low-E chugs
                    strings[0].trigger(tuning[0], 0.6f, rng);
                    strings[0].decay = 0.985f;
                } else {
                    // full-scale hit
                    for (int s = 0; s < 6; ++s) strings[s].trigger(tuning[s] * 2.0, 0.5f, rng);
                }
            }
        }
        float x = 0.0f;
        for (auto& s : strings) x += s.tick();
        if (n >= playFrames) {
            for (auto& s : strings) s.gain *= 0.999f;
        }
        out[n] = std::max(-1.0f, std::min(1.0f, x));
    }
    return out;
}

void writeWav(const std::string& path, const std::vector<float>& l, const std::vector<float>& r)
{
    FILE* f = std::fopen(path.c_str(), "wb");
    if (!f) return;
    uint32_t frames = uint32_t(l.size());
    uint32_t dataBytes = frames * 2 * 2;
    auto w32 = [&](uint32_t v) { std::fwrite(&v, 4, 1, f); };
    auto w16 = [&](uint16_t v) { std::fwrite(&v, 2, 1, f); };
    std::fwrite("RIFF", 1, 4, f); w32(36 + dataBytes); std::fwrite("WAVE", 1, 4, f);
    std::fwrite("fmt ", 1, 4, f); w32(16); w16(1); w16(2); w32(kSampleRate); w32(kSampleRate * 4); w16(4); w16(16);
    std::fwrite("data", 1, 4, f); w32(dataBytes);
    for (uint32_t i = 0; i < frames; ++i) {
        int16_t a = int16_t(std::max(-1.0f, std::min(1.0f, l[i])) * 32767.0f);
        int16_t b = int16_t(std::max(-1.0f, std::min(1.0f, r[i])) * 32767.0f);
        std::fwrite(&a, 2, 1, f); std::fwrite(&b, 2, 1, f);
    }
    std::fclose(f);
}

void writeFloatWav(const std::string& path, const std::vector<float>& l, const std::vector<float>& r)
{
    FILE* f = std::fopen(path.c_str(), "wb");
    if (!f) return;
    uint32_t frames = uint32_t(l.size());
    uint32_t dataBytes = frames * 2 * 4;
    auto w32 = [&](uint32_t v) { std::fwrite(&v, 4, 1, f); };
    auto w16 = [&](uint16_t v) { std::fwrite(&v, 2, 1, f); };
    std::fwrite("RIFF", 1, 4, f); w32(36 + dataBytes); std::fwrite("WAVE", 1, 4, f);
    std::fwrite("fmt ", 1, 4, f); w32(16); w16(3); w16(2); w32(kSampleRate); w32(kSampleRate * 8); w16(8); w16(32);
    std::fwrite("data", 1, 4, f); w32(dataBytes);
    for (uint32_t i = 0; i < frames; ++i) {
        std::fwrite(&l[i], 4, 1, f);
        std::fwrite(&r[i], 4, 1, f);
    }
    std::fclose(f);
}

struct Result {
    bool finite = true;
    double peak = 0.0;
    double playRms = 0.0;
    double tailRms = 0.0;
    double dc = 0.0;
    double cpuRealtime = 0.0;
};

Result render(dsp* d, const std::vector<float>& input, std::vector<float>* keepL, std::vector<float>* keepR)
{
    Result res;
    int frames = int(input.size());
    int ins = d->getNumInputs();
    int outs = d->getNumOutputs();
    std::vector<std::vector<FAUSTFLOAT>> inBuf(std::max(ins, 1), std::vector<FAUSTFLOAT>(kBlock));
    std::vector<std::vector<FAUSTFLOAT>> outBuf(std::max(outs, 1), std::vector<FAUSTFLOAT>(kBlock));
    std::vector<FAUSTFLOAT*> inPtr, outPtr;
    for (auto& b : inBuf) inPtr.push_back(b.data());
    for (auto& b : outBuf) outPtr.push_back(b.data());
    int playFrames = int(kPlaySeconds * kSampleRate);
    int tailStart = frames - kSampleRate * 2;  // last two seconds
    double playSq = 0.0, tailSq = 0.0, sum = 0.0;
    auto t0 = std::chrono::steady_clock::now();
    for (int pos = 0; pos < frames; pos += kBlock) {
        int n = std::min(kBlock, frames - pos);
        for (int c = 0; c < ins; ++c)
            for (int i = 0; i < n; ++i) inBuf[c][i] = input[pos + i] * (c == 1 ? 0.97f : 1.0f);
        d->compute(n, inPtr.data(), outPtr.data());
        for (int i = 0; i < n; ++i) {
            for (int c = 0; c < outs; ++c) {
                double v = outBuf[c][i];
                if (!std::isfinite(v)) res.finite = false;
                res.peak = std::max(res.peak, std::fabs(v));
                if (pos + i < playFrames) playSq += v * v;
                if (pos + i >= tailStart) tailSq += v * v;
                sum += v;
            }
            if (keepL) keepL->push_back(outBuf[0][i]);
            if (keepR) keepR->push_back(outBuf[outs > 1 ? 1 : 0][i]);
        }
    }
    auto t1 = std::chrono::steady_clock::now();
    double secs = std::chrono::duration<double>(t1 - t0).count();
    res.cpuRealtime = secs / (double(frames) / kSampleRate);
    res.playRms = std::sqrt(playSq / (double(playFrames) * outs));
    res.tailRms = std::sqrt(tailSq / (double(frames - tailStart) * outs));
    res.dc = sum / (double(frames) * outs);
    return res;
}

// Probe mode: render one input through one parameter state and save float WAV.
//   --probe sine:440|burst:440|guitar|impulse|noise --set /path=value --seconds 4 --out x.wav
int runProbe(const std::string& input, const std::vector<std::pair<std::string, float>>& sets, double seconds,
             const std::string& outPath)
{
    int frames = int(seconds * kSampleRate);
    std::vector<float> sig(frames, 0.0f);
    if (input.rfind("sine:", 0) == 0) {
        double f = std::atof(input.c_str() + 5);
        for (int n = 0; n < frames; ++n) sig[n] = float(0.5 * std::sin(2.0 * M_PI * f * n / kSampleRate));
    } else if (input.rfind("burst:", 0) == 0) {
        double f = std::atof(input.c_str() + 6);
        for (int n = 0; n < std::min(frames, kSampleRate); ++n) sig[n] = float(0.5 * std::sin(2.0 * M_PI * f * n / kSampleRate));
    } else if (input == "guitar") {
        sig = makeGuitar(frames);
    } else if (input == "impulse") {
        sig[0] = 1.0f;
    } else if (input == "noise") {
        std::mt19937 rng(7);
        std::uniform_real_distribution<float> d(-0.5f, 0.5f);
        for (auto& v : sig) v = d(rng);
    } else {
        std::fprintf(stderr, "unknown probe input %s\n", input.c_str());
        return 2;
    }
    // Heap allocation: large delay lines would overflow the stack.
    std::unique_ptr<mydsp> d(new mydsp());
    d->init(kSampleRate);
    MapUI ui;
    d->buildUserInterface(&ui);
    for (auto kv : sets) {
        // Accept a bare label ("Mix") as well as a full path.
        for (auto& p : ui.getFullpathMap()) {
            const std::string& full = p.first;
            if (full.size() > kv.first.size() && full.compare(full.size() - kv.first.size(), kv.first.size(), kv.first) == 0
                && full[full.size() - kv.first.size() - 1] == '/') {
                kv.first = full;
                break;
            }
        }
        if (!ui.getParamZone(kv.first)) {
            std::fprintf(stderr, "unknown parameter %s\n", kv.first.c_str());
            for (auto& p : ui.getFullpathMap()) std::fprintf(stderr, "  %s\n", p.first.c_str());
            return 2;
        }
        ui.setParamValue(kv.first, kv.second);
    }
    std::vector<float> l, r;
    render(d.get(), sig, &l, &r);
    writeFloatWav(outPath, l, r);
    return 0;
}

}  // namespace

int main(int argc, char** argv)
{
    std::string wavPrefix, probe, probeOut = "probe.wav";
    double probeSeconds = 4.0;
    std::vector<std::pair<std::string, float>> sets;
    for (int i = 1; i < argc; ++i) {
        if (!std::strcmp(argv[i], "--wav") && i + 1 < argc) wavPrefix = argv[++i];
        else if (!std::strcmp(argv[i], "--probe") && i + 1 < argc) probe = argv[++i];
        else if (!std::strcmp(argv[i], "--out") && i + 1 < argc) probeOut = argv[++i];
        else if (!std::strcmp(argv[i], "--seconds") && i + 1 < argc) probeSeconds = std::atof(argv[++i]);
        else if (!std::strcmp(argv[i], "--set") && i + 1 < argc) {
            std::string kv = argv[++i];
            size_t eq = kv.rfind('=');
            if (eq != std::string::npos) sets.push_back({kv.substr(0, eq), float(std::atof(kv.c_str() + eq + 1))});
        }
    }
    if (!probe.empty()) return runProbe(probe, sets, probeSeconds, probeOut);

    int frames = int((kPlaySeconds + kTailSeconds) * kSampleRate);
    std::vector<float> guitar = makeGuitar(frames);

    std::unique_ptr<mydsp> probeDsp(new mydsp());
    ParamCollector collector;
    probeDsp->buildUserInterface(&collector);

    std::string presetPath;
    FAUSTFLOAT presetMax = 0;
    for (auto& p : collector.params) {
        if (p.path.find("Preset") != std::string::npos) {
            presetPath = p.path;
            presetMax = p.max;
        }
    }

    struct Scenario {
        std::string name;
        std::map<std::string, FAUSTFLOAT> values;
    };
    std::vector<Scenario> scenarios;
    scenarios.push_back({"default", {}});
    if (!presetPath.empty()) {
        for (int i = 1; i <= int(presetMax); ++i) scenarios.push_back({"preset-" + std::to_string(i), {{presetPath, FAUSTFLOAT(i)}}});
    }
    Scenario allMin{"all-min", {}}, allMax{"all-max", {}};
    for (auto& p : collector.params) {
        if (p.path == presetPath) continue;
        allMin.values[p.path] = p.min;
        allMax.values[p.path] = p.max;
    }
    scenarios.push_back(allMin);
    scenarios.push_back(allMax);
    std::mt19937 rng(42);
    for (int r = 0; r < 12; ++r) {
        Scenario s{"random-" + std::to_string(r), {}};
        for (auto& p : collector.params) {
            if (p.path == presetPath) continue;
            std::uniform_real_distribution<float> d(p.min, p.max);
            float v = d(rng);
            if (p.step > 0) v = p.min + std::round((v - p.min) / p.step) * p.step;
            s.values[p.path] = v;
        }
        scenarios.push_back(s);
    }

    int failures = 0;
    double worstCpu = 0.0;
    for (auto& sc : scenarios) {
        std::unique_ptr<mydsp> d(new mydsp());
        d->init(kSampleRate);
        MapUI ui;
        d->buildUserInterface(&ui);
        for (auto& kv : sc.values) ui.setParamValue(kv.first, kv.second);
        bool keep = !wavPrefix.empty() && (sc.name == "default" || sc.name.rfind("preset-", 0) == 0);
        std::vector<float> l, r;
        Result res = render(d.get(), guitar, keep ? &l : nullptr, keep ? &r : nullptr);
        worstCpu = std::max(worstCpu, res.cpuRealtime);
        std::vector<std::string> problems;
        if (!res.finite) problems.push_back("non-finite output");
        if (res.peak > 6.0) problems.push_back("runaway peak");
        if (res.tailRms > 0.25) problems.push_back("tail not decaying");
        if (std::fabs(res.dc) > 0.05) problems.push_back("dc offset");
        bool wantSignal = sc.name == "default" || sc.name.rfind("preset-", 0) == 0;
        if (wantSignal && res.playRms < 1e-3) problems.push_back("silent output");
        std::printf("  %-10s peak %6.3f  rms %6.4f  tail %8.6f  dc %+8.5f  cpu %5.2f%%  %s\n",
                    sc.name.c_str(), res.peak, res.playRms, res.tailRms, res.dc, res.cpuRealtime * 100.0,
                    problems.empty() ? "ok" : "FAIL");
        for (auto& p : problems) std::printf("      -> %s\n", p.c_str());
        if (!problems.empty()) ++failures;
        if (keep) writeWav(wavPrefix + "-" + sc.name + ".wav", l, r);
    }
    std::printf("  worst cpu %.2f%% of realtime (single core, 48 kHz)\n", worstCpu * 100.0);
    if (failures) {
        std::printf("  %d scenario(s) FAILED\n", failures);
        return 1;
    }
    return 0;
}
