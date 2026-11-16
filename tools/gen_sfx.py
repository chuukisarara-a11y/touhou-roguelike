#!/usr/bin/env python3
"""用波形合成全部音效，输出到 assets/sfx/*.wav。用法: python3 tools/gen_sfx.py"""
import os
import numpy as np
from scipy.io import wavfile
SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(5)

def t(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.003, r=0.05):
    e = np.ones(n); na = max(1, int(SR * a)); nr = max(1, min(n - na, int(SR * r)))
    e[:na] = np.linspace(0, 1, na); e[-nr:] = np.linspace(1, 0, nr) ** 2
    return e
def sweep(f0, f1, d, wave="sine"):
    x = t(d); f = f0 * (f1 / f0) ** (x / d); ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph)
    return np.sign(s) * 0.6 if wave == "square" else s
def noise(d, lp=None):
    n = rng.uniform(-1, 1, int(SR * d))
    if lp:
        k = max(1, int(SR / lp)); n = np.convolve(n, np.ones(k) / k, mode="same")
    return n
def tone(f, d, wave="sine"): return sweep(f, f, d, wave)
def decay(x, k): return x * np.exp(-np.arange(len(x)) / SR * k)
def cat(*xs): return np.concatenate(xs)
def mix(*xs):
    n = max(len(x) for x in xs); o = np.zeros(n)
    for x in xs: o[:len(x)] += x
    return o
def save(name, x, vol=0.8):
    x = x * env(len(x)); x = x / max(1e-9, np.abs(x).max()) * vol
    wavfile.write(os.path.join(OUT, name + ".wav"), SR, (x * 32767).astype(np.int16))

save("shoot", decay(sweep(1500, 900, 0.035, "square"), 60), 0.35)
save("hit", decay(noise(0.03, 6000), 90), 0.4)
save("kill", mix(decay(noise(0.14, 3000), 22), decay(sweep(700, 180, 0.14), 18) * 0.7), 0.7)
save("bosskill", mix(decay(noise(1.1, 1400), 3.2), decay(sweep(220, 40, 1.1), 3) * 0.9, decay(noise(0.3, 9000), 12) * 0.5), 0.95)
save("graze", decay(tone(2600, 0.04), 70), 0.3)
save("phit", mix(decay(sweep(900, 70, 0.5, "square"), 5), decay(noise(0.5, 2500), 7) * 0.8), 0.9)
save("bomb", mix(sweep(200, 1800, 0.7) * np.linspace(0.3, 1, int(SR * 0.7)), decay(noise(0.9, 5000), 3) * 0.6, cat(np.zeros(int(SR * 0.55)), decay(tone(1760, 0.35), 8))), 0.85)
save("coin", cat(decay(tone(1320, 0.05), 25), decay(tone(1976, 0.09), 22)), 0.4)
save("heal", cat(*[decay(tone(f, 0.09), 14) for f in (660, 880, 1320)]), 0.6)
save("click", decay(tone(880, 0.03, "square"), 70), 0.35)
save("select", cat(decay(tone(660, 0.05, "square"), 25), decay(tone(990, 0.09, "square"), 18)), 0.4)
save("phase", mix(decay(noise(0.35, 12000), 9), cat(np.zeros(int(SR * 0.03)), decay(tone(2093, 0.4), 7) * 0.7), decay(tone(3136, 0.3), 9) * 0.4), 0.8)
save("win", cat(*[decay(mix(tone(f, 0.16), tone(f * 2, 0.16) * 0.3), 9) for f in (523, 659, 784, 1047)]), 0.6)
save("warn", cat(*[cat(decay(tone(740, 0.12, "square"), 6), np.zeros(int(SR * 0.06))) for _ in range(3)]), 0.5)
print("sfx ok")
