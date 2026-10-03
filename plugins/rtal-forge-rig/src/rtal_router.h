// Effect-chain router for rtal-forge-rig.
//
// The DSP has 13 nodes: effects 1..12 and the amp (node 13). Each of the 12
// chain slots names an effect (0 = Off); the amp sits after slot 'ampAfter'
// (0 = before every slot). An effect is used at the first slot that selects it;
// later duplicates are ignored. This returns, for a node, the index of the node
// feeding it (0 = the dry input, -1 when the node is not in the chain), and for
// node 14 the node feeding the rig output.
//
// The Faust code calls it through ffunction with control-rate arguments only,
// so it is evaluated once per audio block rather than per sample.
//
// (c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
#ifndef RTAL_ROUTER_H
#define RTAL_ROUTER_H

static inline int rtal_route(int node, int s1, int s2, int s3, int s4, int s5, int s6, int s7, int s8, int s9,
                             int s10, int s11, int s12, int ampAfter)
{
    const int slots[12] = {s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12};
    const int kAmp = 13;
    bool used[14] = {false};
    int running = (ampAfter <= 0) ? kAmp : 0;  // node whose output is current
    if (node == kAmp && ampAfter <= 0) return 0;
    for (int k = 0; k < 12; ++k) {
        const int e = slots[k];
        if (e >= 1 && e <= 12 && !used[e]) {
            used[e] = true;
            if (e == node) return running;
            running = e;
        }
        if (ampAfter == k + 1) {
            if (node == kAmp) return running;
            running = kAmp;
        }
    }
    if (node == 14) return running;
    // The amp past the last slot (ampAfter >= 12 handled above); otherwise unused.
    return -1;
}

#endif
