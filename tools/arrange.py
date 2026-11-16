#!/usr/bin/env python3
"""把一条单旋律 MIDI 编配成完整的游戏 BGM。
旋律原样保留（不改音高、不改节奏），本脚本只做「加法」：推断调性与和弦，
然后叠加 贝斯 / 弦乐铺底 / 分解和弦 / 鼓 / 旋律叠奏 / 三度和声，用 GM 音源渲染成可无缝循环的 OGG。

用法:
  python3 tools/arrange.py 旋律.mid 输出名 [--style stage|boss|calm] [--half] [--no-render]
输出:
  assets/music/<输出名>.ogg      游戏直接读取
  build/arranged/<输出名>.mid    编配后的多轨 MIDI，可拖进 FL Studio 继续改
"""
import sys, os, math, argparse, subprocess, random
import mido
import numpy as np
from scipy.io import wavfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SF2 = "/usr/share/sounds/sf2/FluidR3_GM.sf2"
TPB = 480
MAJ = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
MIN = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]
NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

STYLES = {
    # lead/double: (GM音色, 八度偏移, 力度)
    "stage": dict(lead=(56, 0, 104), double=(0, 0, 70), pad=48, arp=46, bass=33, drums="rock", arp_div=4, harmony=True),
    "boss": dict(lead=(81, 0, 96), double=(56, 0, 84), pad=48, arp=0, bass=38, drums="fast", arp_div=4, harmony=True),
    "calm": dict(lead=(0, 0, 96), double=(73, 12, 52), pad=48, arp=46, bass=32, drums="light", arp_div=2, harmony=False),
}

def read_melody(path):
    mid = mido.MidiFile(path)
    tempo, num, den = 500000, 4, 4
    got_tempo = got_ts = False
    notes, on = [], {}
    for tr in mid.tracks:
        t = 0
        for m in tr:
            t += m.time
            if m.type == "set_tempo" and not got_tempo:
                tempo, got_tempo = m.tempo, True
            elif m.type == "time_signature" and not got_ts:
                num, den, got_ts = m.numerator, m.denominator, True
            elif m.type == "note_on" and m.velocity > 0 and getattr(m, "channel", 0) != 9:
                on[(m.channel, m.note)] = (t, m.velocity)
            elif m.type in ("note_off", "note_on") and getattr(m, "channel", 0) != 9:
                k = (m.channel, m.note)
                if k in on:
                    s, v = on.pop(k)
                    notes.append([s / mid.ticks_per_beat, (t - s) / mid.ticks_per_beat, m.note, v])
    if not notes:
        sys.exit("这个 MIDI 里没有找到音符")
    notes.sort(key=lambda n: (n[0], -n[2]))
    mono = []
    for n in notes:   # 同一时刻有多个音时取最高音，保证是单旋律
        if mono and abs(mono[-1][0] - n[0]) < 1e-3:
            continue
        if mono and mono[-1][0] + mono[-1][1] > n[0]:
            mono[-1][1] = n[0] - mono[-1][0]
        mono.append(n)
    t0 = math.floor(mono[0][0] / (num * 4 / den)) * (num * 4 / den)   # 去掉开头的整小节空白
    for n in mono:
        n[0] -= t0
    return mono, tempo, num * 4.0 / den

def detect_key(notes):
    hist = [0.0] * 12
    for s, d, p, v in notes:
        hist[p % 12] += d
    best = (-9, 0, "minor")
    for tonic in range(12):
        for mode, prof in (("major", MAJ), ("minor", MIN)):
            rot = [hist[(tonic + i) % 12] for i in range(12)]
            c = np.corrcoef(rot, prof)[0, 1]
            if c > best[0]:
                best = (c, tonic, mode)
    return best[1], best[2]

def chord_table(tonic, mode):
    scale = [0, 2, 4, 5, 7, 9, 11] if mode == "major" else [0, 2, 3, 5, 7, 8, 10]
    chords = []
    for i in range(7):
        pcs = [(tonic + scale[(i + k) % 7] + (12 if i + k >= 7 else 0)) % 12 for k in (0, 2, 4)]
        iv = sorted(((pcs[1] - pcs[0]) % 12, (pcs[2] - pcs[0]) % 12))
        chords.append(dict(root=pcs[0], pcs=pcs, dim=(iv == [3, 6]), tonic=(i == 0), dom=(i == 4)))
    if mode == "minor":   # 小调补一个大属和弦
        r = (tonic + 7) % 12
        chords.append(dict(root=r, pcs=[r, (r + 4) % 12, (r + 7) % 12], dim=False, tonic=False, dom=True))
    return chords, [(tonic + s) % 12 for s in scale]

def harmonize(notes, bpb, unit, n_units, chords, scale):
    def score(u, ch):
        a, b = u * unit, (u + 1) * unit
        sc = 0.0
        for s, d, p, v in notes:
            ov = min(b, s + d) - max(a, s)
            if ov <= 0:
                continue
            w = ov * (1.6 if abs(s - a) < 0.01 else 1.0)
            pc = p % 12
            sc += w * (1.0 if pc in ch["pcs"] else (-0.25 if pc in scale else -0.7))
            if pc == ch["root"]:
                sc += 0.3 * ov
        sc += 0.12 * unit if ch["tonic"] else 0
        sc -= 1.2 * unit if ch["dim"] else 0
        return sc
    def trans(a, b):
        if a is b:
            return -0.3 * unit
        iv = (b["root"] - a["root"]) % 12
        return {5: 0.3, 7: 0.2, 2: 0.15, 10: 0.15, 1: 0.1, 11: 0.1}.get(iv, 0.05) * unit
    n = len(chords)
    dp = [[score(0, c) + (0.6 * unit if c["tonic"] else 0) for c in chords]]
    back = []
    for u in range(1, n_units):
        row, brow = [], []
        for j, c in enumerate(chords):
            cand = [dp[-1][i] + trans(chords[i], c) for i in range(n)]
            i = int(np.argmax(cand))
            extra = (0.5 * unit if (c["dom"] or c["tonic"]) else 0) if u == n_units - 1 else 0
            row.append(cand[i] + score(u, c) + extra); brow.append(i)
        dp.append(row); back.append(brow)
    j = int(np.argmax(dp[-1])); seq = [j]
    for brow in reversed(back):
        j = brow[j]; seq.append(j)
    return [chords[j] for j in reversed(seq)]

def near(pc, center):
    n = center - ((center - pc) % 12)
    return n + 12 if center - n > 6 else n

class Song:
    def __init__(s):
        s.tracks = {}
    def add(s, name, ch, prog, start, dur, pitch, vel):
        s.tracks.setdefault(name, dict(ch=ch, prog=prog, ev=[]))["ev"].append((start, dur, int(pitch), int(max(1, min(127, vel)))))

def build(notes, tempo, bpb, style_name, half):
    st = STYLES[style_name]
    rnd = random.Random(7)
    end = max(s + d for s, d, p, v in notes)
    bars = max(1, math.ceil(end / bpb - 1e-6))
    total = bars * bpb
    unit = bpb / 2 if (half and bpb == 4) else bpb
    n_units = int(round(total / unit))
    tonic, mode = detect_key(notes)
    chords, scale = chord_table(tonic, mode)
    prog = harmonize(notes, bpb, unit, n_units, chords, scale)
    song = Song()
    scale_notes = sorted(set(p for o in range(-1, 10) for p in [o * 12 + pc for pc in scale]))
    # 旋律：原样 + 叠奏
    prog_l, oct_l, vel_l = st["lead"]; prog_d, oct_d, vel_d = st["double"]
    for s, d, p, v in notes:
        song.add("lead", 0, prog_l, s, d * 0.97, p + oct_l, vel_l)
        song.add("double", 1, prog_d, s, d * 0.97, p + oct_d, vel_d)
        if st["harmony"] and d >= 1.0:   # 长音下方加一个调内三度
            i = min(range(len(scale_notes)), key=lambda k: abs(scale_notes[k] - p))
            song.add("harmony", 2, 48, s, d * 0.95, scale_notes[max(0, i - 2)], 46)
    prev_voicing = None
    for u, ch in enumerate(prog):
        a = u * unit
        bar = int(a // bpb)
        full = (bars < 16) or (bar >= 8) or (bar % 8 >= 4 and bars >= 16 and bar >= 4)
        root = near(ch["root"], 34)
        nxt = prog[(u + 1) % len(prog)]
        nroot = near(nxt["root"], 34)
        # 铺底：弦乐三和弦，取离上一个和弦最近的排列
        cands = [sorted(near(pc, c) for pc in ch["pcs"]) for c in (58, 62, 66)]
        voicing = min(cands, key=lambda vv: sum(abs(x - y) for x, y in zip(vv, prev_voicing))) if prev_voicing else cands[1]
        prev_voicing = voicing
        for p in voicing:
            song.add("pad", 3, st["pad"], a, unit * 0.98, p, 54)
        # 分解和弦
        if full:
            seq = [voicing[0], voicing[1], voicing[2], voicing[0] + 12, voicing[2], voicing[1]]
            step = 1.0 / st["arp_div"]
            for i in range(int(round(unit / step))):
                song.add("arp", 4, st["arp"], a + i * step, step * 0.9, seq[i % len(seq)] + 12, 58 if i % st["arp_div"] else 70)
        # 贝斯
        appr = nroot + (-1 if nroot <= root else 1) * (1 if rnd.random() < 0.5 else 2)
        if st["drums"] == "light":
            song.add("bass", 5, st["bass"], a, unit / 2 * 0.95, root, 84)
            song.add("bass", 5, st["bass"], a + unit / 2, unit / 2 * 0.95, root + 7, 76)
        else:
            div = 4 if st["drums"] == "fast" else 2
            n = int(round(unit * div))
            for i in range(n):
                p = root + (12 if (i % 4 == 2 or (div == 2 and i % 8 == 5)) else 0)
                if i == n - 1 and nroot != root:
                    p = appr
                song.add("bass", 5, st["bass"], a + i / div, 0.9 / div, p, 98 if i % div == 0 else 82)
    # 鼓（通道 9）
    K_, S_, H_, O_, C_, T1, T2, RIM = 36, 38, 42, 46, 49, 47, 45, 37
    for bar in range(bars):
        a = bar * bpb
        light_sec = bars >= 16 and bar < 4
        kind = st["drums"]
        def hit(t, n, v):
            song.add("drums", 9, 0, a + t, 0.1, n, v)
        if kind == "light":
            for b in range(int(bpb)):
                hit(b, H_, 44 if b else 56)
                if b % 2 == 1:
                    hit(b, RIM, 60)
            continue
        if bar % 8 == 0 and not light_sec:
            hit(0, C_, 96)
        if bpb == 3:
            hit(0, K_, 104); hit(1, S_, 86); hit(2, S_, 80)
            for i in range(6):
                hit(i * 0.5, H_, 66 if i % 2 == 0 else 48)
            continue
        if kind == "rock":
            kicks = [0, 1.5, 2] if not light_sec else [0, 2]
            hats = [i * 0.5 for i in range(int(bpb * 2))]
        else:
            kicks = [0, 1, 2, 3, 3.5] if not light_sec else [0, 2]
            hats = [i * 0.25 for i in range(int(bpb * 4))]
        for t in kicks:
            if t < bpb: hit(t, K_, 108)
        if not light_sec:
            for t in (1, 3):
                if t < bpb: hit(t, S_, 100)
        fill = (bar % 4 == 3) and not light_sec
        for i, t in enumerate(hats):
            if fill and t >= bpb - 1:
                continue
            hit(t, O_ if (abs(t - (bpb - 0.5)) < 1e-6 and not fill) else H_, 72 if abs(t - round(t)) < 1e-6 else 50)
        if fill:
            for i in range(4):
                hit(bpb - 1 + i * 0.25, [S_, S_, T1, T2][i], 78 + i * 9)
    info = dict(key="%s %s" % (NAMES[tonic], "大调" if mode == "major" else "小调"), bars=bars, bpm=60e6 / tempo,
                chords=" ".join(NAMES[c["root"]] + ("" if (c["pcs"][1] - c["root"]) % 12 == 4 else "m") for c in prog))
    return song, total, info

def write_midi(song, tempo, total, path, repeats=1):
    mid = mido.MidiFile(ticks_per_beat=TPB)
    meta = mido.MidiTrack(); mid.tracks.append(meta)
    meta.append(mido.MetaMessage("set_tempo", tempo=tempo, time=0))
    for name, tr in song.tracks.items():
        t = mido.MidiTrack(); mid.tracks.append(t)
        t.append(mido.MetaMessage("track_name", name=name, time=0))
        if tr["ch"] != 9:
            t.append(mido.Message("program_change", channel=tr["ch"], program=tr["prog"], time=0))
        ev = []
        for r in range(repeats):
            for s, d, p, v in tr["ev"]:
                a = int(round((s + r * total) * TPB)); b = max(a + 1, int(round((s + d + r * total) * TPB)))
                ev.append((a, 1, p, v)); ev.append((b, 0, p, 0))
        ev.sort(key=lambda e: (e[0], e[1]))
        last = 0
        for tick, on, p, v in ev:
            t.append(mido.Message("note_on" if on else "note_off", channel=tr["ch"], note=p, velocity=v, time=tick - last))
            last = tick
    mid.save(path)

def render(song, tempo, total, out_ogg):
    """把曲子连着渲染两遍，取第二遍：这样开头自带上一遍的混响尾巴，循环时无缝。"""
    tmp_mid, tmp_wav = "/tmp/_arr.mid", "/tmp/_arr.wav"
    write_midi(song, tempo, total, tmp_mid, repeats=2)
    subprocess.run(["fluidsynth", "-ni", "-g", "0.7", "-r", "44100", "-F", tmp_wav, SF2, tmp_mid], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    sr, data = wavfile.read(tmp_wav)
    L = int(round(total * tempo / 1e6 * sr))
    seg = data[L:2 * L].astype(np.float64)
    seg *= 0.89 * 32767 / max(1.0, np.abs(seg).max())
    wavfile.write(tmp_wav, sr, seg.astype(np.int16))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp_wav, "-c:a", "libvorbis", "-q:a", "4", out_ogg], check=True)
    return L / sr

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("midi"); ap.add_argument("name")
    ap.add_argument("--style", default="stage", choices=list(STYLES))
    ap.add_argument("--half", action="store_true", help="每半小节换一次和弦（仅 4/4）")
    ap.add_argument("--no-render", action="store_true")
    a = ap.parse_args()
    notes, tempo, bpb = read_melody(a.midi)
    song, total, info = build(notes, tempo, bpb, a.style, a.half)
    os.makedirs(os.path.join(ROOT, "build", "arranged"), exist_ok=True)
    write_midi(song, tempo, total, os.path.join(ROOT, "build", "arranged", a.name + ".mid"))
    print("调性: %(key)s | 速度: %(bpm).0f | 小节: %(bars)d\n和弦: %(chords)s" % info)
    if not a.no_render:
        secs = render(song, tempo, total, os.path.join(ROOT, "assets", "music", a.name + ".ogg"))
        print("已输出 assets/music/%s.ogg（%.1f 秒，可循环）" % (a.name, secs))
