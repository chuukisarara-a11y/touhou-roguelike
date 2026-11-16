#!/usr/bin/env python3
"""8bit 风格编曲：保留作者 MIDI 里的全部音符，叠加 8bit 伴奏后用自带的芯片音色合成器渲染。

作者写的内容（一音不改）：
  - 最高声部 → 方波 1（12.5% 占空比，长音带延迟颤音）
  - 同时发声的其余音（和声、八度）→ 方波 2（25%）
  - 分解和弦轨 → 方波 3（50%，略小声）
本脚本添加的伴奏：
  - 三角波贝斯（按每小节推断的和弦根音）
  - 没有分解和弦的段落，用和弦音补一条同样节型的分解和弦
  - 噪音鼓，按段落渐强；乐句末尾加过门
  - 主旋律加一层回声，左右声道略分开

用法: python3 tools/chiptune.py 输入.mid 输出名 [--sections 段落描述]
  段落描述: "起始小节:调号:强度,..."，例如 "0:E:1,18:E:3,20:Eb:3,42:E:2,62:E:4"
  强度 0=无鼓 1=只有贝斯 2=轻鼓 3=完整 4=完整+加花
输出: assets/music/<输出名>.ogg（可无缝循环）
"""
import sys, os, math, argparse, subprocess
import numpy as np
import mido
from scipy.io import wavfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from arrange import chord_table, harmonize

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SR = 44100
KEYS = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}

def read(path):
    m = mido.MidiFile(path)
    tempo, num, den = 500000, 4, 4
    tracks = []
    for tr in m.tracks:
        t, on, notes = 0, {}, []
        for msg in tr:
            t += msg.time
            if msg.type == "set_tempo": tempo = msg.tempo
            elif msg.type == "time_signature": num, den = msg.numerator, msg.denominator
            elif msg.type == "note_on" and msg.velocity > 0: on[msg.note] = (t, msg.velocity)
            elif msg.type in ("note_off", "note_on") and msg.note in on:
                s, v = on.pop(msg.note)
                notes.append([s / m.ticks_per_beat, (t - s) / m.ticks_per_beat, msg.note, v])
        if notes:
            tracks.append(sorted(notes))
    return tracks, tempo, num * 4.0 / den

def split_voices(notes):
    """同一时刻起音的音：最高的给主旋律，其余给和声。"""
    groups = {}
    for n in notes:
        groups.setdefault(round(n[0], 3), []).append(n)
    lead, harm = [], []
    for k in sorted(groups):
        g = sorted(groups[k], key=lambda n: -n[2])
        lead.append(g[0]); harm += g[1:]
    for i in range(len(lead) - 1):   # 主旋律单音化
        lead[i][1] = min(lead[i][1], lead[i + 1][0] - lead[i][0])
    return lead, harm

# ------------------------------------------------------------ 合成器
def hz(p): return 440.0 * 2 ** ((p - 69) / 12.0)

def env_adsr(n, a=0.004, d=0.09, s=0.62, r=0.035):
    e = np.full(n, s)
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na = min(na, n); e[:na] = np.linspace(0, 1, na, endpoint=False)
    nd = min(nd, n - na); e[na:na + nd] = np.linspace(1, s, nd, endpoint=False)
    nr = min(nr, n); e[n - nr:] *= np.linspace(1, 0, nr)
    return e

def pulse(freq, n, duty, vib=False):
    t = np.arange(n) / SR
    f = np.full(n, freq)
    if vib:   # 0.22 秒后渐入的颤音
        depth = np.clip((t - 0.22) / 0.3, 0, 1) * 0.0045
        f = f * (1 + depth * np.sin(2 * np.pi * 5.6 * t))
    ph = np.cumsum(f) / SR
    return np.where((ph % 1.0) < duty, 1.0, -1.0)

def tri(freq, n):
    ph = (np.arange(n) * freq / SR) % 1.0
    x = 1 - 4 * np.abs(ph - 0.5)
    return np.round(x * 7.5) / 7.5   # 4bit 台阶感

_lfsr = None
def noise(n, short=False):
    global _lfsr
    if _lfsr is None:
        reg, out = 1, []
        for _ in range(32767):
            bit = (reg ^ (reg >> 1)) & 1
            reg = (reg >> 1) | (bit << 14)
            out.append(1.0 if reg & 1 else -1.0)
        _lfsr = np.array(out)
    step = 2 if short else 6
    idx = (np.arange(n) // step) % len(_lfsr)
    return _lfsr[idx]

class Mix:
    def __init__(s, seconds):
        s.n = int(seconds * SR) + SR * 3
        s.L = np.zeros(s.n); s.R = np.zeros(s.n)
    def add(s, t, sig, vol, pan=0.0):
        i = int(t * SR)
        j = min(s.n, i + len(sig))
        if j <= i: return
        sig = sig[:j - i] * vol
        s.L[i:j] += sig * (1 - max(0, pan)); s.R[i:j] += sig * (1 + min(0, pan))

def lowpass(x, cut):
    a = math.exp(-2 * math.pi * cut / SR)
    y = np.empty_like(x); acc = 0.0
    # 向量化的一阶低通：分块近似
    from scipy.signal import lfilter
    return lfilter([1 - a], [1, -a], x)

# ------------------------------------------------------------ 编曲
def chord_of_bar(notes, a, b, chords, scale, prev):
    sub = [[max(0, n[0] - a), min(b, n[0] + n[1]) - max(a, n[0]), n[2], 100] for n in notes if n[0] < b and n[0] + n[1] > a]
    if not sub:
        return prev
    return harmonize(sub, b - a, b - a, 1, chords, scale)[0]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("midi"); ap.add_argument("name")
    ap.add_argument("--sections", required=True)
    ap.add_argument("--arp-track", type=int, default=0, help="哪条轨是分解和弦（按有音符的轨计数，-1 表示没有）")
    ap.add_argument("--intro-prog", default="", help="只有分解和弦的段落的贝斯走向，例如 E,C#m,A,B（每个和弦 2 小节）")
    a = ap.parse_args()
    tracks, tempo, bpb = read(a.midi)
    spb = tempo / 1e6
    arp = tracks[a.arp_track] if a.arp_track >= 0 else []
    melody = [n for i, tr in enumerate(tracks) if i != a.arp_track for n in tr]
    lead, harm = split_voices([list(n) for n in melody])
    end = max(n[0] + n[1] for tr in tracks for n in tr)
    bars = int(math.ceil(end / bpb - 1e-6))
    secs = bars * bpb * spb
    sec = []
    for part in a.sections.split(","):
        b0, k, lv = part.split(":")
        tonic = KEYS[k.rstrip("m")]
        sec.append((int(b0), tonic, "minor" if k.endswith("m") else "major", int(lv)))
    def section(bar):
        cur = sec[0]
        for s in sec:
            if bar >= s[0]: cur = s
        return cur
    intro = []
    for c in [x for x in a.intro_prog.split(",") if x]:
        minor = c.endswith("m"); r = KEYS[c.rstrip("m")]
        intro.append(dict(root=r, pcs=[r, (r + (3 if minor else 4)) % 12, (r + 7) % 12]))
    mix = Mix(secs)
    beat = lambda b: b * spb
    # --- 作者的音符
    for s, d, p, v in lead:
        n = int(beat(d) * SR); 
        if n <= 0: continue
        sig = pulse(hz(p), n, 0.125, vib=d >= 1.0) * env_adsr(n, s=0.7)
        mix.add(beat(s), sig, 0.20, -0.08)
        mix.add(beat(s) + beat(0.75), sig * 0.9, 0.06, 0.5)    # 回声
    for s, d, p, v in harm:
        n = int(beat(d) * SR)
        if n <= 0: continue
        mix.add(beat(s), pulse(hz(p), n, 0.25) * env_adsr(n, s=0.55), 0.10, 0.25)
    for s, d, p, v in arp:
        n = int(beat(d) * 0.92 * SR)
        mix.add(beat(s), pulse(hz(p), n, 0.5) * env_adsr(n, d=0.12, s=0.35), 0.075, -0.35)
    # --- 每小节的和弦
    prev = None
    bar_chords = []
    for bar in range(bars):
        b0, tonic, mode, lv = section(bar)
        chords, scale = chord_table(tonic, mode)
        a0, a1 = bar * bpb, (bar + 1) * bpb
        has_mel = any(n[0] < a1 and n[0] + n[1] > a0 for n in melody)
        if not has_mel and intro:
            k = (bar - b0) // 2 % len(intro)
            ch = intro[k]
        else:
            ch = chord_of_bar(melody, a0, a1, chords, scale, prev) or chords[0]
        if ch.get("dim"):   # 减三和弦当作属七和弦（去根音），贝斯走属音
            r = (ch["root"] - 4) % 12
            ch = dict(root=r, pcs=[r, (r + 4) % 12, (r + 7) % 12])
        bar_chords.append(ch); prev = ch
    # --- 贝斯（三角波）与补充分解和弦
    for bar, ch in enumerate(bar_chords):
        lv = section(bar)[3]
        if lv < 1: continue
        a0 = bar * bpb
        root = 36 + (ch["root"] - 36) % 12
        if root > 43: root -= 12
        fifth = root + 7
        pat = [(0, root, 1.0), (1, fifth, 0.5), (2, root + 12, 0.5)] if bpb == 3 else [(0, root, 1.0), (1, root + 12, 0.5), (2, fifth, 1.0), (3, root + 12, 0.5)]
        if lv >= 3 and bpb == 3:
            pat = [(0, root, 0.9), (1, root + 12, 0.45), (1.5, fifth, 0.45), (2, root + 12, 0.45), (2.5, fifth, 0.45)]
        for t0, p, d in pat:
            n = int(beat(d) * SR)
            mix.add(beat(a0 + t0), tri(hz(p), n) * env_adsr(n, a=0.002, d=0.05, s=0.85, r=0.02), 0.30, 0.0)
        arp_here = any(a0 <= n[0] < a0 + bpb for n in arp)
        if not arp_here and lv >= 2:
            tones = sorted(set(60 + (pc - 60) % 12 for pc in ch["pcs"]))
            seq = [tones[0], tones[1], tones[2], tones[0] + 12, tones[2], tones[1]]
            for i in range(int(bpb * 2)):
                n = int(beat(0.5) * 0.85 * SR)
                p = seq[i % len(seq)] + 12
                mix.add(beat(a0 + i * 0.5), pulse(hz(p), n, 0.5) * env_adsr(n, d=0.1, s=0.3), 0.05, -0.4)
    # --- 噪音鼓
    def kick(t):
        n = int(0.12 * SR); tt = np.arange(n) / SR
        f = 150 * np.exp(-tt * 28) + 45
        sig = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 18)
        mix.add(t, np.round(sig * 7.5) / 7.5, 0.34, 0.0)
    def snare(t, v=1.0):
        n = int(0.16 * SR)
        mix.add(t, noise(n) * np.exp(-np.arange(n) / SR * 22), 0.13 * v, 0.1)
    def hat(t, v=1.0, open_=False):
        n = int((0.12 if open_ else 0.03) * SR)
        sig = noise(n, short=True) * np.exp(-np.arange(n) / SR * (14 if open_ else 90))
        mix.add(t, sig, 0.07 * v, -0.15)
    for bar in range(bars):
        lv = section(bar)[3]
        a0 = bar * bpb
        nxt = section(bar + 1)
        phrase_end = (bar + 1 == nxt[0] and nxt[3] > lv) or (bar % 8 == 7)
        if lv >= 2:
            kick(beat(a0))
            for i in range(int(bpb)):
                hat(beat(a0 + i), 1.0 if i else 0.7)
        if lv >= 3:
            for i in range(int(bpb)):
                hat(beat(a0 + i + 0.5), 0.6)
            if bpb == 3:
                snare(beat(a0 + 2), 0.85)
                if bar % 2 == 1: kick(beat(a0 + 1.5))
            else:
                snare(beat(a0 + 1)); snare(beat(a0 + 3)); kick(beat(a0 + 2))
        if lv >= 4 and bar % 4 == 0:
            n = int(0.5 * SR)
            mix.add(beat(a0), noise(n) * np.exp(-np.arange(n) / SR * 5), 0.08, 0.0)   # 镲
        if phrase_end and lv >= 2:
            for i in range(4):
                snare(beat(a0 + bpb - 1 + i * 0.25), 0.55 + i * 0.15)
    # --- 收尾：把超出曲长的尾音折回开头，循环无缝
    L = int(secs * SR)
    out = []
    for ch in (mix.L, mix.R):
        x = ch[:L].copy(); tail = ch[L:]
        x[:len(tail)] += tail[:L]
        x = lowpass(x, 9000)
        out.append(x)
    st = np.stack(out, axis=1)
    st *= 0.9 / max(1e-9, np.abs(st).max())
    wav = "/tmp/_chip.wav"
    wavfile.write(wav, SR, (st * 32767).astype(np.int16))
    dst = os.path.join(ROOT, "assets", "music", a.name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", dst], check=True)
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    print("速度 %.0f BPM，%d/4 拍，%d 小节，%.1f 秒" % (60 / spb, bpb, bars, secs))
    print("和弦:", " ".join(names[c["root"]] + ("m" if (c["pcs"][1] - c["root"]) % 12 == 3 else "") for c in bar_chords))
    print("已输出", dst)

if __name__ == "__main__":
    main()
