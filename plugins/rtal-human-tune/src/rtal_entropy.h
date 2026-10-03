// Per-activation entropy for rtal-human-tune.
//
// The Faust DSP declares `fconstant(int rtal_entropy_seed, "rtal_entropy.h")`.
// Faust evaluates foreign constants in instanceConstants(), i.e. every time a
// plugin instance is initialised or re-initialised by the host, so each
// activation receives a fresh seed and the humanisation never repeats.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_ENTROPY_H
#define RTAL_ENTROPY_H

#include <atomic>
#include <chrono>
#include <cstdint>
#include <random>

static inline int rtal_entropy_seed_fn()
{
    static std::atomic<uint32_t> counter{0};
    uint64_t x = 0;
    // OS entropy where available...
    try {
        std::random_device rd;
        x = (uint64_t(rd()) << 32) ^ uint64_t(rd());
    } catch (...) {
    }
    // ...mixed with the high-resolution clock, a per-process counter and a stack
    // address (randomised by ASLR), so even a platform without a real
    // random_device produces different seeds per activation and per instance.
    x ^= uint64_t(std::chrono::high_resolution_clock::now().time_since_epoch().count());
    x ^= uint64_t(counter.fetch_add(0x9E3779B9u)) << 17;
    x ^= uint64_t(reinterpret_cast<uintptr_t>(&x));
    // splitmix64 finaliser to spread every input bit across the result.
    x += 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    x ^= x >> 31;
    return int(x & 0x7FFFFFFFu);
}

#define rtal_entropy_seed rtal_entropy_seed_fn()

#endif
