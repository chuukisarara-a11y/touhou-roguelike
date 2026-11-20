#!/usr/bin/env python3
"""8bit 风格编曲（加强版）：作者 MIDI 里的音符一音不改，在 8bit 音色的基础上叠加更多乐器层，尽量丰富听感。

作者写的内容（一音不改）：
  - 最高声部 → 主旋律：方波 1（12.5% 占空比，长音带颤音）+ 轻微失谐的副方波加厚；高潮段再叠一层高八度
  - 同时发声的其余音（和声、八度）→ 方波 2（25%）
  - 分解和弦轨 → 方波 3（50%）+ 附点八分回声（左右声道交错）
本脚本添加的伴奏（只用和弦音与调内音，不写新旋律）：
  - 主旋律下方三度的和声（强度 ≥3 的段落，只在调内音上）
  - 合成铺底（失谐锯齿波和弦，慢起慢收）
  - 钟琴（FM 音色，每小节第一拍点一下和弦音）
  - 三角波贝斯 + 正弦低音；强度 4 时贝斯改为八分音符律动
  - 没有分解和弦的段落，用和弦音补一条分解和弦
  - 鼓：底鼓、军鼓、闭镲/开镲、段落开头的吊镲、乐句末尾的通鼓过门、升段前的反向镲
  - 整体混响 + 立体声展开 + 软限幅
  - 主旋律加一层回声

用法: python3 tools/chiptune.py 输入.mid 输出名 --sections 段落描述 [--arp-track N] [--intro-prog 和弦]
  段落描述: "起始小节:调号:强度,..."，例如 "0:E:1,18:E:3,20:Eb:3,42:E:2,62:E:4"（调号后加 m 表示小调）
  强度 0=无鼓 1=铺底+贝斯 2=轻鼓+钟琴 3=完整+三度和声 4=完整+加花+高八度主旋律
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

def saw(freq, n, detune=0.0):
    ph = (np.arange(n) * freq * (1 + detune) / SR) % 1.0
    return ph * 2 - 1

def fm_bell(freq, n, decay=2.2, ratio=3.5, index=2.4):
    t = np.arange(n) / SR
    env = np.exp(-t * decay)
    mod = index * np.exp(-t * decay * 1.6) * np.sin(2 * np.pi * freq * ratio * t)
    return np.sin(2 * np.pi * freq * t + mod) * env

def sine(freq, n):
    return np.sin(2 * np.pi * freq * np.arange(n) / SR)

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
    """干声两声道 + 混响发送两声道。send = 送进混响的比例。"""
    def __init__(s, seconds):
        s.n = int(seconds * SR) + SR * 4
        s.L = np.zeros(s.n); s.R = np.zeros(s.n)
        s.vL = np.zeros(s.n); s.vR = np.zeros(s.n)
    def add(s, t, sig, vol, pan=0.0, send=0.12):
        i = int(t * SR)
        if i < 0: sig = sig[-i:]; i = 0
        j = min(s.n, i + len(sig))
        if j <= i: return
        sig = sig[:j - i] * vol
        l = sig * (1 - max(0, pan)); r = sig * (1 + min(0, pan))
        s.L[i:j] += l; s.R[i:j] += r
        if send > 0:
            s.vL[i:j] += l * send; s.vR[i:j] += r * send

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
    # --- 每小节的和弦（先算好，后面的伴奏都要用）
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
    def lv_at(t_beats):
        return section(int(t_beats // bpb))[3]
    def scale_at(t_beats):
        _, tonic, mode, _ = section(int(t_beats // bpb))
        return chord_table(tonic, mode)[1]

    # --- 作者的音符：主旋律
    for s0, d, p, v in lead:
        n = int(beat(d) * SR)
        if n <= 0: continue
        lv = lv_at(s0)
        e = env_adsr(n, s=0.7)
        sig = pulse(hz(p), n, 0.125, vib=d >= 1.0) * e
        thick = pulse(hz(p) * 1.0035, n, 0.25, vib=d >= 1.0) * e   # 失谐副方波，让主旋律更厚
        mix.add(beat(s0), sig, 0.19, -0.1, send=0.18)
        mix.add(beat(s0), thick, 0.07, 0.15, send=0.18)
        mix.add(beat(s0) + beat(0.75), sig * 0.9, 0.055, 0.55, send=0.3)    # 回声
        if lv >= 4:   # 高潮：高八度再叠一层
            mix.add(beat(s0), pulse(hz(p + 12), n, 0.25, vib=d >= 1.0) * env_adsr(n, s=0.6), 0.06, -0.3, send=0.25)
        if lv >= 3:   # 下方三度和声：只取调内音（主旋律不在调内就不配）
            sc = scale_at(s0)
            if p % 12 in sc:
                k = sc.index(p % 12)
                q = p - ((p % 12) - sc[(k - 2) % 7]) % 12
                if p - q < 3: q -= 12
                mix.add(beat(s0), tri(hz(q), n) * env_adsr(n, a=0.01, s=0.75), 0.11, 0.35, send=0.2)
    for s0, d, p, v in harm:
        n = int(beat(d) * SR)
        if n <= 0: continue
        mix.add(beat(s0), pulse(hz(p), n, 0.25) * env_adsr(n, s=0.55), 0.09, 0.3, send=0.18)
    for k, (s0, d, p, v) in enumerate(arp):
        n = int(beat(d) * 0.92 * SR)
        sig = pulse(hz(p), n, 0.5) * env_adsr(n, d=0.12, s=0.35)
        mix.add(beat(s0), sig, 0.07, -0.35, send=0.2)
        mix.add(beat(s0 + 0.75), sig, 0.03, 0.45, send=0.35)   # 附点八分回声，左右交错

    # --- 合成铺底：每小节一个和弦，慢起慢收
    for bar, ch in enumerate(bar_chords):
        lv = section(bar)[3]
        if lv < 1: continue
        n = int(beat(bpb) * 1.15 * SR)
        voice = sorted(55 + (pc - 55) % 12 for pc in ch["pcs"])
        sig = np.zeros(n)
        for q in voice:
            sig += saw(hz(q), n, -0.004) + saw(hz(q), n, 0.004)
        sig = lowpass(lowpass(sig, 1500), 1500) / 6.0
        e = env_adsr(n, a=0.18, d=0.3, s=0.8, r=0.25)
        vol = [0, 0.11, 0.13, 0.14, 0.16][lv]
        mix.add(beat(bar * bpb), sig * e, vol, 0.0, send=0.45)

    # --- 钟琴：小节第一拍点一下和弦里最高的音
    for bar, ch in enumerate(bar_chords):
        lv = section(bar)[3]
        if lv < 2 or (lv < 4 and bar % 2): continue
        top = max(84 + (pc - 84) % 12 for pc in ch["pcs"])
        n = int(1.4 * SR)
        mix.add(beat(bar * bpb), fm_bell(hz(top), n), 0.06, 0.4 if bar % 4 < 2 else -0.4, send=0.5)

    # --- 贝斯（三角波 + 正弦低音）与补充分解和弦
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
        if lv >= 4:   # 八分音符律动
            pat = [(i * 0.5, root if i % 2 == 0 else root + 12, 0.42) for i in range(int(bpb * 2))]
            pat[0] = (0, root, 0.45)
        for t0, p, d in pat:
            n = int(beat(d) * SR)
            e = env_adsr(n, a=0.002, d=0.05, s=0.85, r=0.02)
            mix.add(beat(a0 + t0), tri(hz(p), n) * e, 0.28, 0.0, send=0.03)
            mix.add(beat(a0 + t0), sine(hz(p - 12 if p >= 40 else p), n) * e, 0.16, 0.0, send=0.0)
        arp_here = any(a0 <= n[0] < a0 + bpb for n in arp)
        if not arp_here and lv >= 2:
            tones = sorted(set(60 + (pc - 60) % 12 for pc in ch["pcs"]))
            seq = [tones[0], tones[1], tones[2], tones[0] + 12, tones[2], tones[1]]
            for i in range(int(bpb * 2)):
                n = int(beat(0.5) * 0.85 * SR)
                p = seq[i % len(seq)] + 12
                mix.add(beat(a0 + i * 0.5), pulse(hz(p), n, 0.5) * env_adsr(n, d=0.1, s=0.3), 0.045, -0.45, send=0.3)

    # --- 鼓
    def kick(t, v=1.0):
        n = int(0.16 * SR); tt = np.arange(n) / SR
        f = 160 * np.exp(-tt * 30) + 42
        sig = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 14)
        mix.add(t, sig, 0.42 * v, 0.0, send=0.02)
        click = noise(int(0.006 * SR), short=True) * 0.5
        mix.add(t, click, 0.1 * v, 0.0, send=0.0)
    def snare(t, v=1.0):
        n = int(0.2 * SR); tt = np.arange(n) / SR
        body = np.sin(2 * np.pi * 185 * tt) * np.exp(-tt * 30)
        mix.add(t, noise(n) * np.exp(-tt * 18) * 0.8 + body * 0.6, 0.16 * v, 0.08, send=0.25)
    def hat(t, v=1.0, open_=False):
        n = int((0.16 if open_ else 0.035) * SR)
        sig = noise(n, short=True) * np.exp(-np.arange(n) / SR * (11 if open_ else 85))
        mix.add(t, sig, 0.06 * v, -0.2, send=0.08)
    def crash(t, v=1.0):
        n = int(1.6 * SR)
        sig = lowpass(noise(n, short=True), 9000) * np.exp(-np.arange(n) / SR * 2.6)
        mix.add(t, sig, 0.09 * v, 0.25, send=0.35)
    def tom(t, p, v=1.0):
        n = int(0.22 * SR); tt = np.arange(n) / SR
        f = hz(p) * (1 + 0.6 * np.exp(-tt * 25))
        mix.add(t, np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 12), 0.22 * v, 0.0, send=0.2)
    def riser(t_end, length):
        n = int(length * SR); tt = np.linspace(0, 1, n)
        sig = noise(n, short=True) * tt ** 2.5
        mix.add(t_end - length, lowpass(sig, 6000), 0.07, 0.0, send=0.4)
    for bar in range(bars):
        lv = section(bar)[3]
        a0 = bar * bpb
        nxt = section(bar + 1)
        up = bar + 1 == nxt[0] and nxt[3] > lv
        phrase_end = up or (bar % 8 == 7)
        if bar == section(bar)[0] and lv >= 3:
            crash(beat(a0))
        elif lv >= 4 and bar % 4 == 0:
            crash(beat(a0), 0.7)
        if lv >= 2:
            kick(beat(a0))
            for i in range(int(bpb)):
                hat(beat(a0 + i), 1.0 if i else 0.7)
        if lv >= 3:
            for i in range(int(bpb)):
                hat(beat(a0 + i + 0.5), 0.6, open_=(i == int(bpb) - 1 and bar % 2 == 1))
            if bpb == 3:
                snare(beat(a0 + 2), 0.9)
                if bar % 2 == 1: kick(beat(a0 + 1.5), 0.8)
            else:
                snare(beat(a0 + 1)); snare(beat(a0 + 3)); kick(beat(a0 + 2))
        if lv >= 4:
            kick(beat(a0 + 1), 0.6)
        if up:
            riser(beat(a0 + bpb), beat(bpb))
        if phrase_end and lv >= 2:
            if lv >= 3:   # 通鼓过门：从高到低
                for i, p in enumerate([52, 49, 45, 41]):
                    tom(beat(a0 + bpb - 1 + i * 0.25), p, 0.8 + i * 0.07)
            else:
                for i in range(4):
                    snare(beat(a0 + bpb - 1 + i * 0.25), 0.5 + i * 0.15)

    # --- 收尾：混响、软限幅；超出曲长的尾音折回开头，循环无缝
    from scipy.signal import fftconvolve
    L = int(secs * SR)
    rng = np.random.default_rng(7)
    ir_n = int(1.8 * SR)
    decay = np.exp(-np.arange(ir_n) / SR * 3.2)
    out = []
    for dry, wet in ((mix.L, mix.vL), (mix.R, mix.vR)):
        ir = rng.standard_normal(ir_n) * decay
        ir[: int(0.012 * SR)] = 0   # 预延迟
        ir = lowpass(ir, 5000)
        ir /= np.sqrt(np.sum(ir ** 2))
        verb = fftconvolve(wet, ir)[: len(dry)] * 0.9
        x = dry + verb
        y = x[:L].copy(); tail = x[L:]
        y[:min(len(tail), L)] += tail[:L]
        out.append(lowpass(y, 12000))
    st = np.stack(out, axis=1)
    st /= max(1e-9, np.percentile(np.abs(st), 99.9))
    st = np.tanh(st * 0.9) * 0.92
    wav = "/tmp/_chip.wav"
    wavfile.write(wav, SR, (st * 32767).astype(np.int16))
    dst = os.path.join(ROOT, "assets", "music", a.name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "6", dst], check=True)
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    print("速度 %.0f BPM，%d/4 拍，%d 小节，%.1f 秒" % (60 / spb, bpb, bars, secs))
    print("和弦:", " ".join(names[c["root"]] + ("m" if (c["pcs"][1] - c["root"]) % 12 == 3 else "") for c in bar_chords))
    print("已输出", dst)

if __name__ == "__main__":
    main()
