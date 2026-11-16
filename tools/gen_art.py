#!/usr/bin/env python3
"""生成全部美术（2 倍像素密度）：角色、立绘、敌人、子弹、图标、背景、事件插画、应用图标。
游戏逻辑坐标 1 单位 = 这里的 2 像素；游戏加载贴图时按一半尺寸显示。
用法: python3 tools/gen_art.py   （输出到 assets/sprites/ 与 assets/icon.png）"""
import os, random, math
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
os.makedirs(OUT, exist_ok=True)
S = 2                           # 像素密度
K = (38, 26, 52, 255)           # 描边色
SKIN = (255, 228, 205, 255)
SKIN_D = (236, 184, 164, 255)
RED = (222, 60, 70); WHITE = (252, 250, 244); BLUE = (84, 132, 232); YEL = (252, 212, 84)

def rgba(c):
    return (c[0], c[1], c[2], c[3] if len(c) > 3 else 255)
def dark(c, k=0.7):
    return (int(c[0] * k), int(c[1] * k * 0.96), int(min(255, c[2] * k * 1.06)), 255)
def light(c, k=0.35):
    return (int(c[0] + (255 - c[0]) * k), int(c[1] + (255 - c[1]) * k), int(c[2] + (255 - c[2]) * k), 255)

class Dr:
    """按比例 k 作画的画布：坐标用设计单位，实际像素 = 单位 × k。"""
    def __init__(s, w, h, k, oy=0):
        s.k = k; s.oy = oy; s.w = w; s.h = h
        s.im = Image.new("RGBA", (int(round(w * k)), int(round(h * k))), (0, 0, 0, 0))
        s.d = ImageDraw.Draw(s.im)
    def _p(s, x, y):
        return (x * s.k, (y + s.oy) * s.k)
    def ell(s, cx, cy, rx, ry, c):
        x0, y0 = s._p(cx - rx, cy - ry); x1, y1 = s._p(cx + rx, cy + ry)
        s.d.ellipse([x0, y0, max(x0, x1 - 1), max(y0, y1 - 1)], fill=rgba(c))
    def poly(s, pts, c):
        s.d.polygon([s._p(x, y) for x, y in pts], fill=rgba(c))
    def rect(s, x0, y0, x1, y1, c):
        a = s._p(x0, y0); b = s._p(x1, y1)
        s.d.rectangle([a[0], a[1], max(a[0], b[0] - 1), max(a[1], b[1] - 1)], fill=rgba(c))
    def line(s, pts, c, w=1.0):
        s.d.line([s._p(x, y) for x, y in pts], fill=rgba(c), width=max(1, int(round(w * s.k))), joint="curve")
    def px(s, x, y, c):
        s.rect(x, y, x + 1, y + 1, c)
    def paste(s, im, x, y):
        s.im.alpha_composite(im, (int(round(x * s.k)), int(round((y + s.oy) * s.k))))
        s.d = ImageDraw.Draw(s.im)
    def save(s, name):
        s.im.save(os.path.join(OUT, name + ".png"))
        return s.im

def outlined(im, t=1, color=K):
    a = im.split()[3].point(lambda v: 255 if v > 150 else 0)
    big = a.filter(ImageFilter.MaxFilter(2 * t + 1))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    edge = Image.new("RGBA", im.size, color)
    out.paste(edge, (0, 0), big)
    out.alpha_composite(im)
    return out

def mir(pts, m):
    return pts if m == 1 else [(48 - x, y) for x, y in pts]
def mx(x, m):
    return x if m == 1 else 48 - x

# ------------------------------------------------------------------ Q版角色（参数化，可任意放大成立绘）
BANGS = {
    1: [(11, 18, (13, 24.5)), (17, 25, (20.5, 23.5)), (24, 31, (27.5, 23)), (30, 37, (35, 24.5))],
    2: [(11, 20, (14, 24)), (20, 28, (24, 22.5)), (28, 37, (34, 24))],
    3: [(11, 17, (12.5, 25)), (16, 24, (21, 22.5)), (23, 32, (26, 23.5)), (31, 37, (35.5, 25))],
}

def draw_char(sp, k, frame=0):
    d = Dr(48, 76, k, oy=13)
    H = sp["hair"]; Hd = dark(H, 0.74); Hl = light(H, 0.4)
    dress = sp["dress"]; top = sp.get("top", dress); slv = sp.get("sleeve", top)
    trim = sp.get("trim", WHITE); eye = sp["eye"]; shoe = sp.get("shoe", (120, 56, 60))
    for fn in sp.get("back", []):
        fn(d, frame)
    style = sp.get("style", "short")
    if style == "long":
        d.poly([(9, 20), (39, 20), (42.5, 45), (36, 49), (12, 49), (5.5, 45)], Hd)
    elif style == "verylong":
        d.poly([(9, 20), (39, 20), (44, 54), (37, 59), (11, 59), (4, 54)], Hd)
    elif style == "bob":
        d.ell(24, 25, 17, 13.5, Hd)
    if not sp.get("robe"):
        d.rect(19, 54, 22.6, 60, SKIN); d.rect(25.4, 54, 29, 60, SKIN)
        d.rect(21.6, 54, 22.6, 60, SKIN_D); d.rect(28, 54, 29, 60, SKIN_D)
    d.ell(20.3, 61, 3.7, 2.4, shoe); d.ell(27.7, 61, 3.7, 2.4, shoe)
    if sp.get("robe"):
        d.poly([(16, 43), (32, 43), (35.5, 60), (12.5, 60)], dress)
        d.poly([(28, 43), (32, 43), (35.5, 60), (30.5, 60)], dark(dress, 0.8))
        d.line([(24, 44), (24, 60)], dark(dress, 0.7), 0.7)
    else:
        d.poly([(16, 43), (32, 43), (39.5, 56), (8.5, 56)], dress)
        d.poly([(28, 43), (32, 43), (39.5, 56), (32.5, 56)], dark(dress, 0.82))
        for x in (15.5, 21.5, 27):
            d.line([(x + (x - 24) * 0.1, 46.5), (x + (x - 24) * 0.42, 53.2)], dark(dress, 0.8), 0.55)
        d.poly([(9.4, 53.8), (38.6, 53.8), (39.5, 56), (8.5, 56)], trim)
    d.poly([(17, 35), (31, 35), (32.6, 44.5), (15.4, 44.5)], top)
    d.poly([(28, 35), (31, 35), (32.6, 44.5), (29.6, 44.5)], dark(top, 0.82))
    for m in (1, -1):
        if sp.get("arms_out"):
            d.poly(mir([(17.5, 35.5), (3.5, 34.8), (3.5, 41), (17.5, 43)], m), slv)
            d.ell(mx(2.6, m), 38, 2.5, 2.7, SKIN)
        else:
            d.poly(mir([(17.2, 35.6), (12, 37.6), (8.4, 46.8), (13.6, 48.6), (17.6, 43)], m), slv)
            d.poly(mir([(10.2, 45), (8.4, 46.8), (13.6, 48.6), (14.6, 46.4)], m), dark(slv, 0.86))
            d.ell(mx(10.7, m), 49.6, 2.5, 2.5, SKIN)
    d.rect(22, 32, 26, 36, SKIN_D)
    for fn in sp.get("mid", []):
        fn(d, frame)
    d.ell(24, 20, 15.6, 14.2, H)
    d.poly([(9, 22), (12, 30), (15, 33), (9.5, 31)], Hd); d.poly([(39, 22), (36, 30), (33, 33), (38.5, 31)], Hd)
    d.ell(24, 24, 12, 10.4, SKIN)
    d.ell(24, 32.6, 6, 1.6, SKIN)
    d.ell(24, 13.2, 13.6, 6.6, H)
    for x0, x1, tip in BANGS[sp.get("bangs", 1)]:
        d.poly([(x0, 13.5), (x1, 13.5), tip], H)
    for m in (1, -1):
        d.poly(mir([(8.6, 17), (13.2, 16.5), (12.4, 31.5), (9.6, 30.5)], m), H)
    d.line([(13, 12.5), (17.5, 9.3), (25, 7.8)], Hl, 1.1)
    if k >= 3:   # 立绘细节：发丝
        for pts in ([(15, 9), (13.5, 16)], [(21, 7), (19.5, 15)], [(30, 7.5), (32, 15)], [(35, 11), (36.5, 18)]):
            d.line(pts, Hd, 0.4)
    for cx in (18, 30):
        d.ell(cx, 25.2, 3.0, 4.0, dark(eye, 0.42))
        d.ell(cx, 25.9, 2.3, 3.1, eye)
        d.ell(cx, 27.3, 1.7, 1.4, light(eye, 0.5))
        d.ell(cx - 1.0, 23.7, 1.05, 1.15, WHITE)
        if k >= 3:
            d.ell(cx + 1.1, 27.6, 0.5, 0.5, WHITE)
        d.line([(cx - 3.3, 21.8), (cx + 3.3, 21.6)], K, 0.8)
    for m in (1, -1):
        d.ell(mx(13.6, m), 29.2, 2.3, 1.15, (255, 176, 176, 255))
    d.line([(22.8, 30.8), (24, 31.5), (25.2, 30.8)], (196, 104, 104), 0.6)
    for fn in sp.get("front", []):
        fn(d, frame)
    return outlined(d.im, max(1, int(round(k * 0.55))))

def f_apron(d, fr):
    d.poly([(19.5, 42), (28.5, 42), (31, 54), (17, 54)], WHITE)
    d.line([(17.6, 52.6), (30.4, 52.6)], (214, 214, 230), 0.5)
def f_band(d, fr):
    d.poly([(12.5, 9.5), (35.5, 9.5), (33.5, 5.6), (14.5, 5.6)], WHITE)
    for x in (16, 20, 24, 28, 32):
        d.ell(x, 5.6, 2, 1.6, WHITE)
def f_ears(tall=1.0, c=WHITE):
    def f(d, fr):
        for m in (1, -1):
            d.ell(mx(17.5, m), 2 - 5 * tall, 2.9, 8.5 * tall, c)
            d.ell(mx(17.5, m), 2 - 5 * tall, 1.2, 6.2 * tall, (255, 186, 196))
    return f
def f_beret(c):
    def f(d, fr):
        d.ell(24, 6.4, 14, 5.6, c); d.ell(27, 7.4, 9, 3.4, dark(c, 0.84))
        d.ell(24, 6, 2.3, 2.3, YEL)
    return f
def f_mobcap(c):
    def f(d, fr):
        d.ell(24, 5.2, 14.5, 7.2, c); d.poly([(9.8, 8.6), (38.2, 8.6), (38.2, 11.2), (9.8, 11.2)], dark(c, 0.86))
        d.ell(24, 4.4, 2.4, 2.4, YEL); d.ell(25, 3.8, 1.9, 1.9, c)
    return f
def f_braids(H, ribbon):
    def f(d, fr):
        for m in (1, -1):
            d.poly(mir([(9, 24), (12.6, 24), (12.2, 37), (9.6, 37)], m), H)
            d.ell(mx(10.9, m), 30.5, 2, 1.6, ribbon)
    return f
def f_hime(H):
    def f(d, fr):
        d.poly([(11.6, 13), (36.4, 13), (36.4, 21.4), (11.6, 21.4)], H)
        for m in (1, -1):
            d.poly(mir([(8.6, 17), (13.6, 17), (13.6, 33), (9.2, 33)], m), H)
    return f
def f_bow(c, y=0):
    def f(d, fr):
        for m in (1, -1):
            d.poly(mir([(23, 5 + y), (8.5, -3 + y), (5.5, 9.5 + y), (21, 10 + y)], m), c)
            d.poly(mir([(20.5, 6 + y), (10.5, 1.2 + y), (9.5, 8.2 + y)], m), dark(c, 0.76))
        d.ell(24, 7 + y, 3.4, 3.6, c); d.ell(24.6, 7.6 + y, 1.6, 1.8, dark(c, 0.8))
    return f
def f_tubes(d, fr):
    for m in (1, -1):
        d.poly(mir([(7.4, 21), (12.2, 21), (12.2, 36), (7.4, 36)], m), RED)
        d.poly(mir([(7.4, 24.5), (12.2, 24.5), (12.2, 26.6), (7.4, 26.6)], m), WHITE)
        d.poly(mir([(7.4, 30.5), (12.2, 30.5), (12.2, 32.6), (7.4, 32.6)], m), WHITE)
def f_collar(c):
    def f(d, fr):
        d.poly([(18.4, 35), (29.6, 35), (24, 39.2)], WHITE)
        d.poly([(22.2, 36.6), (25.8, 36.6), (24, 42.4)], c)
    return f
def f_cuffs(c):
    def f(d, fr):
        for m in (1, -1):
            d.line(mir([(9.0, 46.2), (13.8, 47.9)], m), c, 1.0)
    return f
def f_wings(c, big=False):
    def f(d, fr):
        for m in (1, -1):
            d.ell(mx(5.5 if big else 7.5, m), 34 + fr * 1.6, 10 if big else 8.2, 7 - fr * 1.6, c + (225,))
            d.ell(mx(8.5, m), 44.5 - fr, 6.4, 4.2, tuple(dark(c, 0.9)[:3]) + (225,))
            d.line([(mx(13, m), 37), (mx(3 if big else 5, m), 32 + fr * 1.6)], WHITE, 0.4)
    return f
def f_ice(d, fr):
    for m in (1, -1):
        for i, (x, y) in enumerate(((5.4, 27), (1.9, 37.5), (6.2, 47.5))):
            yy = y + (fr * 1.2 if i == 1 else -fr * 0.6)
            x = mx(x, m)
            d.poly([(x, yy - 6.4), (x + 3.3, yy), (x, yy + 6.4), (x - 3.3, yy)], (150, 226, 255))
            d.poly([(x, yy - 3.8), (x + 1.5, yy), (x, yy + 3.8), (x - 1.5, yy)], (238, 252, 255))
def f_ribbon(c):
    def f(d, fr):
        d.poly([(33, 3.5), (41.5, 0.5), (42.5, 9.5), (35, 10.5)], c); d.ell(35.2, 7, 2, 2, dark(c, 0.78))
    return f
def f_ponytail_b(H):
    def f(d, fr):
        d.ell(4.8, 17, 5.2, 8.4, dark(H, 0.8))
    return f
def f_dot(x, y, r, c):
    def f(d, fr):
        d.ell(x, y, r, r, c)
    return f
def f_cap(c):
    def f(d, fr):
        d.poly([(10.5, 9.5), (37.5, 9.5), (34.5, -0.5), (13.5, -0.5)], c)
        d.poly([(30, -0.5), (34.5, -0.5), (37.5, 9.5), (33, 9.5)], dark(c, 0.82))
        d.poly([(7.5, 9), (40.5, 9), (40.5, 12.4), (7.5, 12.4)], dark(c, 0.72))
    return f
def f_twin(H):
    def f(d, fr):
        for m in (1, -1):
            d.ell(mx(5.6, m), 28, 4.8, 7.8, dark(H, 0.82))
    return f
def f_glasses(d, fr):
    g = (84, 84, 112)
    for cx in (18, 30):
        d.line([(cx - 3.8, 21.4), (cx + 3.8, 21.4), (cx + 3.8, 29.4), (cx - 3.8, 29.4), (cx - 3.8, 21.4)], g, 0.6)
    d.line([(21.8, 24.4), (26.2, 24.4)], g, 0.6)
def f_flower(d, fr):
    for i in range(8):
        a = i / 8 * math.tau
        d.ell(24 + math.cos(a) * 5, 3 + math.sin(a) * 3.2, 2.6, 2.0, YEL)
    d.ell(24, 3, 3.2, 2.4, (158, 96, 48))

SPECS = {
    "reimu": dict(hair=(84, 54, 52), dress=RED, sleeve=WHITE, style="long", eye=(150, 70, 60), mid=[f_collar(YEL)], front=[f_bow(RED), f_tubes, f_cuffs(RED)]),
    "fairy": dict(hair=(252, 220, 104), dress=BLUE, eye=(70, 110, 190), back=[f_wings((196, 238, 255))], mid=[f_collar(YEL)], style="bob"),
    "fairy_red": dict(hair=(252, 160, 84), dress=RED, eye=(170, 60, 60), back=[f_wings((255, 226, 208))], mid=[f_collar(WHITE)], style="bob", bangs=3),
    "bigfairy": dict(hair=(120, 206, 120), dress=(250, 206, 76), eye=(60, 130, 70), back=[f_wings((255, 246, 196), True)], mid=[f_collar(RED)], front=[f_flower], style="long", bangs=2),
    "rumia": dict(hair=(252, 220, 104), dress=(62, 54, 80), sleeve=WHITE, arms_out=True, eye=(226, 60, 70), mid=[f_collar(RED)], front=[f_ribbon(RED)], shoe=(160, 50, 60), style="bob"),
    "daiyousei": dict(hair=(100, 206, 132), dress=BLUE, eye=(60, 130, 90), back=[f_wings((228, 250, 238), True), f_ponytail_b((100, 206, 132))], mid=[f_collar(YEL)], front=[f_dot(9.6, 11, 2.3, YEL)], bangs=3),
    "cirno": dict(hair=(132, 200, 252), dress=BLUE, sleeve=WHITE, eye=(70, 120, 226), back=[f_ice, f_bow((60, 110, 206), 1)], mid=[f_collar(RED)], shoe=(70, 90, 170), style="bob", bangs=2),
    "nitori": dict(hair=(100, 168, 234), dress=(100, 178, 226), eye=(70, 120, 206), back=[f_twin((100, 168, 234))], mid=[f_collar(WHITE), f_dot(24, 41, 1.7, YEL)], front=[f_cap((100, 178, 120))], shoe=(70, 100, 130)),
    "rinnosuke": dict(hair=(220, 220, 230), dress=(70, 90, 160), top=(50, 60, 84), robe=True, eye=(200, 170, 80), front=[f_glasses], shoe=(60, 50, 50), bangs=2),
    "maid": dict(hair=(156, 116, 86), dress=(66, 78, 140), eye=(120, 90, 70), back=[f_wings((214, 228, 255))], mid=[f_collar(RED), f_apron], front=[f_band], style="bob"),
    "bamboo": dict(hair=(70, 160, 100), dress=(130, 196, 120), eye=(50, 120, 70), back=[f_wings((224, 250, 214))], mid=[f_collar(WHITE)], style="bob", bangs=3),
    "rabbit": dict(hair=(206, 186, 226), dress=(246, 170, 190), eye=(220, 60, 70), back=[f_ears(0.9)], mid=[f_collar(WHITE)], style="bob", bangs=2),
    "tewi": dict(hair=(70, 60, 72), dress=(250, 186, 200), eye=(210, 70, 80), back=[f_ears(0.8)], mid=[f_dot(24, 40, 2, (250, 150, 60))], style="bob", bangs=3),
    "reisen": dict(hair=(196, 160, 226), dress=(244, 160, 180), top=(58, 58, 80), eye=(226, 56, 66), back=[f_ears(1.25)], mid=[f_collar(RED)], style="long"),
    "meiling": dict(hair=(232, 88, 78), dress=(100, 176, 120), eye=(90, 150, 206), mid=[f_collar(WHITE)], front=[f_beret((100, 176, 120)), f_braids((232, 88, 78), (40, 40, 50))], style="long", bangs=2, shoe=(50, 50, 60)),
    "patchouli": dict(hair=(166, 108, 196), dress=(236, 200, 236), robe=True, eye=(130, 80, 170), mid=[f_collar((170, 90, 200))], front=[f_mobcap((244, 226, 244))], style="long", bangs=2, shoe=(150, 100, 170)),
    "sakuya": dict(hair=(218, 224, 238), dress=(66, 86, 166), eye=(100, 120, 206), mid=[f_collar((60, 150, 90)), f_apron], front=[f_band, f_braids((218, 224, 238), (60, 160, 96))], style="bob", bangs=3, shoe=(50, 50, 70)),
    "kaguya": dict(hair=(46, 40, 56), dress=(156, 46, 66), top=(248, 176, 196), robe=True, eye=(130, 76, 66), mid=[f_collar(WHITE)], front=[f_hime((46, 40, 56))], style="verylong", shoe=(120, 40, 50)),
    "ran": dict(hair=(250, 214, 110), dress=(250, 250, 255), top=(70, 100, 190), robe=True, eye=(210, 160, 60), back=[lambda d, fr: [d.ell(24 + math.cos(a) * 15, 40 + math.sin(a) * 13, 6.5, 4, (250, 206, 96)) for a in [math.pi + i * math.pi / 8 for i in range(9)]]], mid=[f_collar((70, 100, 190))], front=[f_mobcap((250, 250, 255)), lambda d, fr: [d.poly([(mx(13, m), 1), (mx(10, m), -7), (mx(18, m), -1)], (250, 250, 255)) for m in (1, -1)]], style="bob", bangs=2, shoe=(60, 60, 80)),
    "yukari": dict(hair=(252, 226, 130), dress=(140, 80, 190), eye=(170, 90, 200), mid=[f_collar(WHITE)], front=[f_mobcap((250, 250, 255)), f_dot(24, 9.6, 2, RED)], style="verylong", bangs=3, shoe=(90, 50, 120)),
    "sunny": dict(hair=(252, 198, 104), dress=RED, eye=(70, 130, 206), back=[f_wings((255, 242, 206)), f_twin((252, 198, 104))], mid=[f_collar(WHITE)]),
    "luna": dict(hair=(252, 238, 160), dress=WHITE, trim=(200, 200, 220), eye=(200, 70, 70), back=[f_wings((232, 232, 255))], mid=[f_collar((60, 54, 70))], front=[f_bow((60, 54, 70))], style="long", bangs=2),
    "starf": dict(hair=(70, 60, 92), dress=BLUE, eye=(130, 96, 70), back=[f_wings((214, 228, 255))], mid=[f_collar(WHITE)], front=[f_bow(BLUE)], style="long", bangs=3),
}
ANIM = {"fairy", "fairy_red", "bigfairy", "daiyousei", "cirno", "maid", "bamboo"}
PORTRAITS = ["reimu", "rumia", "daiyousei", "cirno", "nitori", "rinnosuke", "meiling", "patchouli", "tewi", "reisen", "sakuya", "kaguya", "ran", "yukari"]

def char_img(name, k, frame=0):
    return draw_char(SPECS[name], k, frame)

for name in SPECS:
    if name in ("sunny", "luna", "starf"):
        continue
    if name in ANIM:
        for f in range(2):
            char_img(name, S, f).save(os.path.join(OUT, "c_%s_%d.png" % (name, f)))
    else:
        char_img(name, S).save(os.path.join(OUT, "c_" + name + ".png"))
for name in PORTRAITS:   # 立绘：4 倍放大的半身像
    im = char_img(name, 4)
    im.crop((0, 0, 192, 240)).save(os.path.join(OUT, "p_%s.png" % name))

# 毛玉（两帧）
def kedama(k, f):
    d = Dr(16, 16, k)
    for i in range(16):
        a = i / 16 * math.tau + f * 0.2
        r1 = 7.4 if i % 2 == 0 else 6.2
        d.poly([(8 + math.cos(a - 0.2) * 4.5, 8 + math.sin(a - 0.2) * 4.5), (8 + math.cos(a) * r1, 8 + math.sin(a) * r1), (8 + math.cos(a + 0.2) * 4.5, 8 + math.sin(a + 0.2) * 4.5)], WHITE)
    d.ell(8, 8, 5.6, 5.6, WHITE); d.ell(8.8, 9.6, 4, 3.4, (222, 226, 240))
    d.ell(5.8, 7.4, 0.8, 1.6, K); d.ell(10.2, 7.4, 0.8, 1.6, K)
    d.line([(6.6, 10.6), (8, 11.3), (9.4, 10.6)], (226, 90, 100), 0.6)
    return outlined(d.im, 1)
for f in range(2):
    kedama(S, f).save(os.path.join(OUT, "kedama_%d.png" % f))

# 蝙蝠 / 魔导书 / 幽灵
def bat(k, f):
    d = Dr(22, 14, k)
    c = (96, 60, 126)
    for m in (1, -1):
        pts = [(9.6, 5.6), (1, 1.5 + f * 4), (2.4, 8), (5.2, 6.6), (6.6, 10.4), (9.8, 9)]
        d.poly(pts if m == 1 else [(22 - x, y) for x, y in pts], c)
    d.ell(11, 7.2, 3, 3.8, dark(c, 0.8)); d.poly([(8.6, 4.4), (9.6, 1.6), (10.6, 4.4)], dark(c, 0.8)); d.poly([(11.4, 4.4), (12.4, 1.6), (13.4, 4.4)], dark(c, 0.8))
    d.ell(9.8, 6.6, 0.7, 0.7, RED); d.ell(12.2, 6.6, 0.7, 0.7, RED)
    return outlined(d.im, 1)
for f in range(2):
    bat(S, f).save(os.path.join(OUT, "bat_%d.png" % f))
d = Dr(15, 18, S)
d.rect(1, 1, 14, 17, (176, 56, 70)); d.rect(1, 1, 3.4, 17, (120, 36, 56)); d.rect(12.6, 2, 14, 16, WHITE)
d.line([(4.6, 2.6), (11.6, 2.6), (11.6, 15.4), (4.6, 15.4), (4.6, 2.6)], YEL, 0.5)
d.ell(8.1, 9, 2.6, 2.6, YEL); d.ell(8.1, 9, 1.4, 1.4, (176, 56, 70))
outlined(d.im, 1).save(os.path.join(OUT, "book.png"))
def ghost(k):
    d = Dr(18, 22, k)
    c = (226, 240, 255, 240)
    d.ell(9, 8, 7.4, 7.4, c); d.poly([(2.4, 10), (15.6, 10), (13, 16.5), (10.6, 21), (8.4, 16), (5.4, 19)], c)
    d.ell(11, 10, 4.5, 4, (196, 216, 246, 240))
    d.ell(6.4, 7.4, 1, 1.9, K); d.ell(11.6, 7.4, 1, 1.9, K); d.ell(9, 11, 1.2, 0.9, (150, 170, 210))
    return outlined(d.im, 1)
ghost(S).save(os.path.join(OUT, "ghost.png")); ghost(S * 1.6).save(os.path.join(OUT, "ghost_big.png"))

# 隙间之眼 / 式神纸人
def eye(k):
    d = Dr(22, 12, k)
    d.poly([(0, 6), (5, 1.5), (11, 0), (17, 1.5), (22, 6), (17, 10.5), (11, 12), (5, 10.5)], (70, 30, 100))
    d.poly([(2.4, 6), (6, 3), (11, 2), (16, 3), (19.6, 6), (16, 9), (11, 10), (6, 9)], (24, 14, 36))
    d.ell(11, 6, 3.4, 3.6, (226, 50, 70)); d.ell(11, 6, 1.2, 2.6, (30, 10, 20)); d.ell(9.8, 4.6, 0.8, 0.8, WHITE)
    return outlined(d.im, 1)
eye(S).save(os.path.join(OUT, "eye.png")); eye(S * 1.7).save(os.path.join(OUT, "eye_big.png"))
d = Dr(14, 16, S)
d.ell(7, 3.6, 3, 3, WHITE); d.poly([(1, 6), (13, 6), (12, 9), (9.6, 8.6), (10.6, 15), (3.4, 15), (4.4, 8.6), (2, 9)], WHITE)
d.line([(7, 7.6), (7, 12.6)], RED, 0.6); d.line([(5, 9.6), (9, 9.6)], RED, 0.6)
outlined(d.im, 1).save(os.path.join(OUT, "shiki.png"))
d = Dr(200, 256, S)
d.rect(0, 0, 200, 256, (30, 14, 48))
r3 = random.Random(77)
for i in range(60):
    x = r3.uniform(0, 200); y = r3.uniform(0, 256); l = r3.uniform(8, 30)
    d.rect(x, y, x + 0.6, y + l, r3.choice([(52, 26, 80), (44, 20, 70), (70, 36, 104)]))
for i in range(14):
    x = r3.uniform(10, 180); y = r3.uniform(6, 244); w = r3.uniform(8, 16)
    d.poly([(x, y), (x + w / 2, y - w * 0.28), (x + w, y), (x + w / 2, y + w * 0.28)], (16, 8, 26))
    d.ell(x + w / 2, y, w * 0.14, w * 0.18, (150, 40, 70))
d.save("bg_gap")

# ------------------------------------------------------------------ 字符画小图（自机弹、图标），按密度放大
P = {"R": RED, "r": (150, 30, 48), "W": WHITE, "w": (200, 204, 220), "Y": YEL, "B": BLUE, "b": (40, 80, 170),
     "c": (170, 230, 250), "O": (250, 150, 50), "K": K, "S": SKIN, "V": (170, 100, 240), "v": (110, 60, 180), "G": (90, 200, 110),
     "o": (200, 140, 30), "D": (120, 80, 20)}
def spr(name, rows, outline=False):
    h, w = len(rows), max(len(r) for r in rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                im.putpixel((x, y), rgba(P[ch]))
    im = im.resize((w * S, h * S), Image.NEAREST)
    if outline:
        pad = Image.new("RGBA", (im.width + 2, im.height + 2), (0, 0, 0, 0))
        pad.alpha_composite(im, (1, 1))
        im = outlined(pad, 1)
    im.save(os.path.join(OUT, name + ".png"))
spr("gapshot", [".VV.", "VWWV", "VWWV", "VWWV", "VWWV", ".VV."])
spr("gap", ["....vvvvvv....", "..vvKKKKKKvv..", "vvKKKRWWRKKKvv", "..vvKKKKKKvv..", "....vvvvvv...."])
spr("heart_empty", [".ww.ww.", "w..w..w", "w.....w", "w.....w", ".w...w.", "..w.w..", "...w..."])
spr("star", ["...Y...", "...Y...", "YYYYYYY", ".YYWYY.", "..YYY..", ".YY.YY.", ".Y...Y."])
spr("knife", [".W.", "WWW", "WWW", "WwW", "WwW", "WWW", "KKK", ".b.", ".b."])
spr("bat", ["R.......R", "RR.R.R.RR", "RRRRRRRRR", ".RRrRrRR.", "..RR.RR.."])
spr("fire", ["..O..", ".OYO.", ".OYO.", "OYYYO", "OOYOO", ".ROR.", "..R.."])
spr("ice", ["..W..", ".WcW.", ".ccc.", "ccccc", ".ccB.", ".cB..", "..B.."])
spr("moon", ["..YYY..", ".YYY...", "YYY....", "YYY....", "YYY....", ".YYY...", "..YYY.."])
spr("doll", ["..YYYY..", ".YYYYYY.", ".YSSSSY.", ".YSKKSY.", "..SSSS..", ".BBWWBB.", ".BBBBBB.", "BBBBBBBB", ".WWWWWW.", "..S..S.."], True)
spr("ic_laser", ["...cc...", "...WW...", "...WW...", "...WW...", "...WW...", "...WW...", "..BWWB..", ".BBBBBB."])
spr("ic_pillar", ["OOOOOOOO", ".oYYYYo.", ".oYYYYo.", ".oYYYYo.", ".oYYYYo.", ".oYYYYo.", ".oYYYYo.", "OOOOOOOO"])
spr("ic_starmap", ["Y......c", "..c.....", "....Y...", ".Y......", "......c.", "...c....", "Y.....Y.", "....c..."])
spr("n_battle", ["......WW.", ".....WWW.", "....WWW..", "...WWW...", "o.WWW....", ".oWW.....", "DDo......", "DD.o....."])
spr("n_elite", [".R.....R.", ".RR...RR.", ".RRRRRRR.", "RRWRRRWRR", "RRKRRRKRR", "RRRRRRRRR", ".RWRWRWR.", "..RRRRR.."])
spr("n_event", ["..GGGG...", ".GG..GG..", ".....GG..", "....GG...", "...GG....", "...GG....", ".........", "...GG...."])
spr("n_shop", ["..oooo...", "...oo....", "..YYYY...", ".YYYYYY..", "YYYDDYYY.", "YYYDDYYY.", ".YYYYYY..", "..YYYY..."])
spr("n_rest", ["RRRRRRRRR", ".RRRRRRR.", "..R...R..", ".RRRRRRR.", "..R...R..", "..R...R..", "..R...R..", "..R...R.."])
spr("n_boss", ["Y...Y...Y", "YY.YYY.YY", "YYYYYYYYY", "YYRYYYRYY", "YYYYYYYYY", ".YYYYYYY.", ".ooooooo.", "........."])

# 高密度重画的小物件
def small(name, w, h, build, ol=True):
    d = Dr(w, h, S)
    build(d)
    im = outlined(d.im, 1) if ol else d.im
    im.save(os.path.join(OUT, name + ".png"))
def b_amulet(d):
    d.rect(0.5, 0.5, 4.5, 7.5, WHITE); d.rect(0.5, 0.5, 4.5, 1.5, RED); d.rect(0.5, 6.5, 4.5, 7.5, RED); d.rect(2, 2.5, 3, 5.5, RED)
small("amulet", 5, 8, b_amulet)
def b_needle(d):
    d.poly([(1.5, 0), (3, 8), (1.5, 10), (0, 8)], (190, 236, 255)); d.line([(1.5, 1), (1.5, 8)], WHITE, 0.5)
small("needle", 3, 10, b_needle, False)
def b_orb(d):
    d.ell(5, 5, 4.6, 4.6, RED); d.ell(5, 5, 3.4, 3.4, (255, 190, 196)); d.ell(5, 5, 2.2, 2.2, WHITE)
small("orb", 10, 10, b_orb, False)
def b_hit(d):
    d.ell(3, 3, 2.9, 2.9, RED); d.ell(3, 3, 1.9, 1.9, WHITE)
small("hitbox", 6, 6, b_hit, False)
def b_heart(d):
    d.ell(2.6, 2.6, 2.4, 2.4, RED); d.ell(6.4, 2.6, 2.4, 2.4, RED); d.poly([(0.4, 3.4), (8.6, 3.4), (4.5, 8.2)], RED)
    d.ell(2.2, 2.1, 0.9, 0.9, (255, 190, 196))
small("heart", 9, 9, b_heart)
def b_yy(d):
    d.ell(5, 5, 4.6, 4.6, WHITE); d.d.pieslice([0.4 * S, 0.4 * S, 9.6 * S - 1, 9.6 * S - 1], -90, 90, fill=rgba(RED))
    d.ell(5, 2.7, 2.3, 2.3, RED); d.ell(5, 7.3, 2.3, 2.3, WHITE); d.ell(5, 2.7, 0.8, 0.8, WHITE); d.ell(5, 7.3, 0.8, 0.8, RED)
small("yinyang", 10, 10, b_yy)
def b_coin(d):   # 方孔铜钱：与白芯圆形敌弹明显不同
    d.ell(4, 4, 3.6, 3.6, (206, 146, 36)); d.ell(4, 4, 2.9, 2.9, YEL); d.rect(3, 3, 5, 5, (120, 80, 24))
small("coin", 8, 8, b_coin)

# ------------------------------------------------------------------ 敌弹图集（每格 16 单位）
# 行 = 形状：0小圆 1大圆 2米粒 3小刀 4星弹 5蝴蝶 6札弹；列 = 颜色：0红 1蓝 2绿 3粉 4紫 5青 6白
COLS = [(240, 60, 70), (70, 120, 250), (70, 210, 100), (255, 130, 200), (175, 90, 245), (90, 220, 240), (225, 228, 240)]
atlas = Dr(16 * len(COLS), 16 * 7, S)
for i, c in enumerate(COLS):
    ox = i * 16 + 8
    dk = dark(c, 0.5)
    atlas.ell(ox, 8, 4.3, 4.3, dk); atlas.ell(ox, 8, 3.5, 3.5, c); atlas.ell(ox, 8, 2.0, 2.0, WHITE)
    atlas.ell(ox, 24, 7.3, 7.3, dk); atlas.ell(ox, 24, 6.4, 6.4, c); atlas.ell(ox, 24, 4.2, 4.2, WHITE)
    atlas.ell(ox, 40, 2.6, 5.4, dk); atlas.ell(ox, 40, 1.9, 4.6, c); atlas.ell(ox, 40, 0.9, 3.0, WHITE)
    # 小刀（刀尖朝上）
    atlas.poly([(ox, 49.2), (ox + 2.2, 54), (ox + 1.6, 59), (ox - 1.6, 59), (ox - 2.2, 54)], dk)
    atlas.poly([(ox, 50.2), (ox + 1.4, 54), (ox + 0.9, 58.4), (ox - 0.9, 58.4), (ox - 1.4, 54)], WHITE)
    atlas.line([(ox, 51), (ox, 58)], c, 0.5)
    atlas.rect(ox - 2.4, 59, ox + 2.4, 60.4, c); atlas.rect(ox - 0.8, 60.4, ox + 0.8, 63, dk)
    # 星弹
    pts = []
    for k in range(10):
        a2 = -math.pi / 2 + k * math.pi / 5
        rr = 5.2 if k % 2 == 0 else 2.4
        pts.append((ox + math.cos(a2) * rr, 72 + math.sin(a2) * rr))
    atlas.poly(pts, dk)
    pts2 = [(ox + (x - ox) * 0.78, 72 + (y - 72) * 0.78) for x, y in pts]
    atlas.poly(pts2, c); atlas.ell(ox, 72, 1.5, 1.5, WHITE)
    # 蝴蝶
    for m in (1, -1):
        atlas.poly([(ox, 87), (ox + m * 6.6, 82.4), (ox + m * 7.2, 86.6), (ox + m * 3, 89.4)], dk)
        atlas.poly([(ox, 88.6), (ox + m * 5.4, 89.6), (ox + m * 4.4, 93.6), (ox + m * 1.4, 92)], dk)
        atlas.poly([(ox + m * 0.6, 87.2), (ox + m * 5.8, 83.6), (ox + m * 6.2, 86.4), (ox + m * 2.8, 88.6)], c)
        atlas.poly([(ox + m * 0.6, 88.8), (ox + m * 4.6, 89.8), (ox + m * 3.8, 92.6), (ox + m * 1.4, 91.2)], c)
    atlas.ell(ox, 88.5, 0.9, 3.4, WHITE)
    # 札弹
    atlas.rect(ox - 2.6, 98.6, ox + 2.6, 109.4, dk); atlas.rect(ox - 2.0, 99.2, ox + 2.0, 108.8, WHITE)
    atlas.rect(ox - 2.0, 99.2, ox + 2.0, 100.6, c); atlas.rect(ox - 2.0, 107.4, ox + 2.0, 108.8, c); atlas.rect(ox - 0.6, 101.8, ox + 0.6, 106.2, c)
atlas.save("bullets")
# 使魔（护盾型敌人的护卫）
def b_fam(d):
    d.ell(5, 5, 4.6, 4.6, (120, 70, 190)); d.ell(5, 5, 3.4, 3.4, (190, 140, 255)); d.ell(5, 5, 1.6, 2.2, WHITE); d.ell(5, 5, 0.8, 1.6, (40, 20, 70))
small("familiar", 10, 10, b_fam)
spr("n_gap", ["..vvvvv..", ".vKKKKKv.", "vKKRWRKKv", "vKKWWWKKv", "vKKRWRKKv", ".vKKKKKv.", "..vvvvv..", "........."])
# 柔光（加法混合用）
g = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
for y in range(64):
    for x in range(64):
        d = math.hypot(x - 31.5, y - 31.5) / 32.0
        if d < 1:
            g.putpixel((x, y), (255, 255, 255, int(255 * (1 - d) ** 2.2)))
g.save(os.path.join(OUT, "glow.png"))
# 灵点
def b_point(d):
    d.poly([(3, 0), (6, 3.5), (3, 7), (0, 3.5)], (120, 230, 255)); d.poly([(3, 1.6), (4.4, 3.5), (3, 5.4), (1.6, 3.5)], WHITE)
small("point", 6, 7, b_point)

# 图标底板
for name, c in (("tile_0", (70, 76, 110)), ("tile_1", (60, 110, 190)), ("tile_2", (200, 140, 40)), ("tile_w", (120, 60, 110))):
    d = Dr(16, 16, S)
    d.d.rounded_rectangle([0, 0, 16 * S - 1, 16 * S - 1], radius=3 * S, fill=rgba(dark(c, 0.55)))
    d.d.rounded_rectangle([S, S, 15 * S - 1, 15 * S - 1], radius=2 * S, fill=rgba(c))
    d.d.rounded_rectangle([2 * S, 2 * S, 14 * S - 1, 14 * S - 1], radius=2 * S, fill=rgba(dark(c, 0.45)))
    d.save(name)

# ------------------------------------------------------------------ 背景与插画（设计单位作画，自动 2 倍密度）
def grad(d, top, bottom, y0=0, y1=None, bands=10):
    y1 = d.h if y1 is None else y1
    for i in range(bands):
        k = i / (bands - 1)
        c = tuple(int(top[j] + (bottom[j] - top[j]) * k) for j in range(3))
        d.rect(0, y0 + (y1 - y0) * i / bands, d.w, y0 + (y1 - y0) * (i + 1) / bands + 1, c)
def stars(d, n, y1, seed):
    r = random.Random(seed)
    for i in range(n):
        x = r.uniform(0, d.w); y = r.uniform(0, y1); c = r.choice([(255, 255, 230), (160, 170, 220), (110, 110, 170)])
        d.rect(x, y, x + 0.5, y + 0.5, c)
def moon(d, cx, cy, r):
    d.ell(cx, cy, r + 3, r + 3, (58, 56, 108)); d.ell(cx, cy, r + 1.4, r + 1.4, (92, 88, 140)); d.ell(cx, cy, r, r, (252, 246, 204))
    d.ell(cx - r * 0.3, cy - r * 0.2, r * 0.26, r * 0.2, (232, 224, 174)); d.ell(cx + r * 0.35, cy + r * 0.3, r * 0.16, r * 0.13, (232, 224, 174))
def hills(d, y, amp, color, seed):
    r = random.Random(seed); ph = [r.uniform(0, 6.28) for _ in range(2)]
    pts = [(0, d.h)]
    for i in range(0, int(d.w * 2) + 1):
        x = i / 2
        pts.append((x, y + math.sin(x * 0.045 + ph[0]) * amp + math.sin(x * 0.11 + ph[1]) * amp * 0.4))
    pts.append((d.w, d.h))
    d.poly(pts, color)
def trees(d, y, n, color, seed):
    r = random.Random(seed)
    for i in range(n):
        x = r.uniform(0, d.w); hh = r.uniform(10, 22)
        d.poly([(x, y - hh), (x + hh * 0.3, y), (x - hh * 0.3, y)], color)
        d.poly([(x, y - hh * 0.6), (x + hh * 0.36, y + 1), (x - hh * 0.36, y + 1)], color)
        d.rect(x - 0.5, y, x + 0.5, y + 3, dark(color))
def torii(d, cx, base, s=1.0, color=(204, 56, 62)):
    w = 22 * s; h = 30 * s; t = max(2, 3 * s); dk = dark(color)
    d.rect(cx - w, base - h, cx - w + t, base, color); d.rect(cx + w - t, base - h, cx + w, base, color)
    d.rect(cx - w + t * 0.6, base - h, cx - w + t, base, dk); d.rect(cx + w - t * 0.4, base - h, cx + w, base, dk)
    d.poly([(cx - w - 7, base - h - t - 2.5), (cx + w + 7, base - h - t - 2.5), (cx + w + 5, base - h - t), (cx - w - 5, base - h - t)], (60, 44, 60))
    d.rect(cx - w - 5, base - h - t, cx + w + 5, base - h, color)
    d.rect(cx - w, base - h + t * 2, cx + w, base - h + t * 3, color)
    d.rect(cx - 1.2 * s, base - h, cx + 1.2 * s, base - h + t * 2, color)
def framed(d):
    c = (150, 135, 205)
    d.rect(0, 0, d.w, 0.5, c); d.rect(0, d.h - 0.5, d.w, d.h, c); d.rect(0, 0, 0.5, d.h, c); d.rect(d.w - 0.5, 0, d.w, d.h, c)
def put_char(d, name, x, y, k=1.8):
    d.paste(char_img(name, k), x, y)

SW, SH = 184, 64
def scene(name, build):
    d = Dr(SW, SH, S)
    build(d); framed(d); d.save(name)

def sc_shrine(d):
    grad(d, (14, 12, 40), (54, 36, 90)); stars(d, 60, 36, 1); moon(d, 150, 14, 7)
    hills(d, 44, 4, (24, 34, 50), 2); trees(d, 51, 16, (18, 46, 42), 3)
    d.rect(0, 52, SW, SH, (40, 46, 56)); d.poly([(76, 52), (108, 52), (116, SH), (68, SH)], (92, 92, 104))
    d.rect(83, 44, 101, 53, (126, 86, 56)); d.poly([(80, 44.5), (104, 44.5), (99, 39), (85, 39)], (74, 54, 66)); d.rect(88, 49, 96, 53, (64, 44, 34))
    torii(d, 92, 58, 0.95)
def sc_kappa(d):
    grad(d, (24, 50, 70), (70, 124, 120)); hills(d, 40, 5, (34, 78, 76), 5)
    d.rect(0, 50, SW, SH, (76, 108, 76))
    for i in range(8):
        d.rect(30 + i * 10, 14, 40 + i * 10, 21, (96, 176, 116) if i % 2 == 0 else WHITE)
    d.rect(31.5, 21, 33.5, 52, (116, 86, 56)); d.rect(106.5, 21, 108.5, 52, (116, 86, 56))
    d.rect(28, 40, 112, 53, (146, 106, 66)); d.rect(28, 40, 112, 42.5, (176, 131, 86))
    r = random.Random(9)
    for i in range(7):
        x = 34 + i * 11; c = r.choice([(156, 156, 170), (116, 126, 146), (186, 166, 96)])
        d.rect(x, 32, x + 7, 40, c); d.ell(x + 2.4, 35, 1, 1, r.choice([(250, 80, 80), (90, 250, 120), YEL])); d.rect(x + 4, 36.5, x + 6, 38.5, (46, 46, 56))
    put_char(d, "nitori", 120, -11)
def sc_fairies(d):
    grad(d, (24, 56, 66), (96, 156, 116)); trees(d, 53, 28, (28, 74, 60), 11); trees(d, 59, 14, (22, 54, 48), 12)
    d.rect(0, 57, SW, SH, (44, 86, 60))
    for i, n in enumerate(("sunny", "luna", "starf")):
        put_char(d, n, 14 + i * 50, -12 + (i % 2) * 5, 1.75)
    d.paste(Image.open(os.path.join(OUT, "coin.png")).resize((36, 36), Image.NEAREST), 158, 14)
def sc_tea(d):
    grad(d, (30, 30, 72), (124, 114, 156), 0, 36); moon(d, 40, 12, 6)
    grad(d, (54, 74, 116), (24, 36, 72), 36, SH)
    r = random.Random(4)
    for i in range(46):
        x = r.uniform(0, SW); y = r.uniform(38, SH - 2); d.rect(x, y, x + r.uniform(3, 10), y + 0.5, (112, 132, 172))
    d.rect(0, 55, SW, SH, (54, 74, 64))
    d.ell(95, 45, 16, 2.2, WHITE); d.rect(94, 46, 96, 57, (156, 156, 166)); d.ell(95, 57.5, 7, 1.2, (156, 156, 166))
    d.ell(91, 39, 5.5, 4.5, (236, 236, 244)); d.poly([(96, 37), (101, 35.5), (100, 38.5), (96, 40)], (236, 236, 244)); d.ell(91, 34.4, 2.4, 1, (206, 66, 76))
    d.rect(102, 40.4, 107, 43.5, (236, 236, 244))
    for i, (x, y) in enumerate(((104.5, 37), (105.5, 34), (103.6, 31))):
        d.ell(x, y, 0.8, 0.8, (226, 226, 236))
def sc_kedama(d):
    grad(d, (26, 24, 62), (84, 74, 124)); hills(d, 46, 4, (42, 46, 72), 8)
    d.rect(0, 55, SW, SH, (52, 56, 72))
    r = random.Random(6)
    for i in range(36):
        d.paste(kedama(r.choice([1.6, 2, 2, 2.6]), i % 2), r.uniform(-4, SW - 12), r.uniform(0, 44))
def sc_kourin(d):
    grad(d, (64, 46, 42), (100, 74, 58))
    r = random.Random(13)
    for sy in (15, 32):
        d.rect(8, sy, 116, sy + 1.6, (136, 96, 64))
        for i in range(12):
            x = 12 + i * 8.6; h = r.uniform(5, 11)
            d.rect(x, sy - h, x + 5.5, sy, r.choice([(96, 146, 196), (196, 96, 96), (206, 186, 106), (126, 176, 126), (166, 126, 196)]))
            d.rect(x + 4.4, sy - h, x + 5.5, sy, (60, 50, 60))
    d.rect(0, 47, SW, SH, (116, 80, 56)); d.rect(0, 47, SW, 49.4, (156, 110, 74))
    d.ell(58, 39, 10.5, 10.5, (94, 64, 150)); d.ell(58, 39, 7.4, 7.4, (132, 82, 212)); d.ell(55.6, 36.4, 2.8, 2.8, (212, 184, 255))
    put_char(d, "rinnosuke", 122, -12)
def sc_rest(d):
    grad(d, (16, 14, 46), (74, 46, 100)); stars(d, 70, 40, 21); moon(d, 30, 14, 8)
    hills(d, 46, 3, (28, 32, 58), 22); trees(d, 53, 12, (22, 42, 46), 23)
    d.rect(0, 55, SW, SH, (46, 50, 62)); d.poly([(78, 55), (106, 55), (112, SH), (72, SH)], (100, 100, 110))
    torii(d, 92, 59, 1.35)
    for x in (48, 132):
        d.rect(x, 45, x + 4.6, 57, (126, 126, 136)); d.poly([(x - 2, 45), (x + 6.6, 45), (x + 5, 40.6), (x - 0.4, 40.6)], (136, 136, 146)); d.rect(x + 1, 41.6, x + 3.6, 44, (255, 224, 126))
    put_char(d, "reimu", 70, -5, 1.6)
def sc_gap(d):
    grad(d, (30, 14, 48), (60, 26, 86))
    r = random.Random(91)
    for i in range(16):
        x = r.uniform(4, SW - 20); y = r.uniform(4, SH - 10); w = r.uniform(10, 22)
        d.poly([(x, y), (x + w / 2, y - w * 0.28), (x + w, y), (x + w / 2, y + w * 0.28)], (14, 6, 24))
        d.ell(x + w / 2, y, w * 0.13, w * 0.17, (170, 40, 80))
    for k in range(2):
        d.line([(60 + k * 4, 0), (66 + k * 4, SH)], (230, 120, 200), 0.6)
    put_char(d, "ran", 112, -12, 1.75)
def sc_clue(d):
    grad(d, (14, 36, 32), (40, 86, 70))
    r = random.Random(52)
    for i in range(16):
        x = r.uniform(0, SW - 6); w = r.uniform(2.5, 5)
        d.rect(x, 0, x + w, SH, r.choice([(34, 78, 54), (28, 64, 48), (44, 96, 62)]))
    d.rect(0, 54, SW, SH, (30, 60, 46))
    shi = Image.open(os.path.join(OUT, "shiki.png"))
    d.paste(shi.resize((shi.width * 2, shi.height * 2), Image.NEAREST), 84, 12)
scene("ev_gap", sc_gap); scene("ev_clue", sc_clue)
def sc_gap(d):
    grad(d, (20, 8, 36), (60, 24, 84))
    r = random.Random(71)
    d.poly([(30, 32), (92, 10), (154, 32), (92, 54)], (10, 4, 18))
    d.poly([(30, 32), (92, 14), (154, 32), (92, 50)], (36, 10, 50))
    for i in range(9):
        x = r.uniform(48, 136); y = r.uniform(22, 42); w = r.uniform(7, 13)
        d.poly([(x - w, y), (x, y - w * 0.4), (x + w, y), (x, y + w * 0.4)], (240, 236, 220))
        d.ell(x, y, w * 0.3, w * 0.36, (200, 40, 60)); d.ell(x, y, w * 0.1, w * 0.3, (30, 10, 20))
    for sx in (30, 154):
        d.poly([(sx - 5, 26), (sx + 5, 26), (sx + 3, 32), (sx + 5, 38), (sx - 5, 38), (sx - 3, 32)], (220, 60, 80))
def sc_clue(d):
    grad(d, (12, 34, 30), (40, 84, 60))
    r = random.Random(72)
    for i in range(16):
        x = r.uniform(0, SW); w = r.uniform(3, 6); c = r.choice([(34, 78, 54), (28, 64, 48), (44, 96, 62)])
        d.rect(x, 0, x + w, SH, c)
        for yy in range(int(r.uniform(0, 16)), SH, 16):
            d.rect(x - 0.5, yy, x + w + 0.5, yy + 1, dark(c, 0.6))
    d.ell(92, 32, 22, 22, (70, 120, 90))
    d.ell(92, 20, 5, 5, WHITE); d.poly([(80, 26), (104, 26), (102, 32), (97, 31), (99, 48), (85, 48), (87, 31), (82, 32)], WHITE)
    d.line([(92, 29), (92, 42)], RED, 1); d.line([(87, 35), (97, 35)], RED, 1)
def sc_road(d):
    grad(d, (16, 14, 44), (60, 44, 90)); stars(d, 60, 36, 81); moon(d, 26, 13, 6)
    hills(d, 44, 4, (26, 30, 54), 82); trees(d, 51, 12, (20, 40, 44), 83)
    d.rect(0, 52, SW, SH, (50, 46, 52)); d.poly([(60, 52), (124, 52), (150, SH), (34, SH)], (96, 86, 80))
    d.rect(120, 22, 170, 25, (120, 50, 50)); d.rect(123, 25, 125, 54, (90, 66, 50)); d.rect(165, 25, 167, 54, (90, 66, 50))
    d.rect(122, 40, 168, 54, (130, 96, 66)); d.rect(122, 40, 168, 42, (160, 120, 84))
    for x in (130, 145, 160):
        d.ell(x, 30, 3.4, 4.4, (250, 120, 70)); d.ell(x, 30, 1.6, 2.4, (255, 220, 140))
def sc_library(d):
    grad(d, (40, 26, 44), (70, 46, 60))
    r = random.Random(91)
    for sy in (14, 30, 46):
        d.rect(0, sy, SW, sy + 1.6, (110, 76, 56))
        x = 2
        while x < SW - 4:
            w = r.uniform(3, 6); h = r.uniform(8, 13)
            d.rect(x, sy - h, x + w, sy, r.choice([(120, 60, 70), (70, 90, 140), (150, 130, 80), (80, 120, 90), (120, 90, 150)]))
            x += w + 0.6
    d.rect(0, 50, SW, SH, (70, 44, 40))
    d.rect(70, 44, 108, 52, (150, 110, 70)); d.poly([(78, 44), (100, 44), (97, 38), (81, 38)], (240, 230, 210)); d.line([(89, 38), (89, 44)], (150, 140, 120), 0.6)
    d.ell(89, 30, 9, 9, (190, 120, 255, 70))
    put_char(d, "patchouli", 126, -12)
def sc_bamboo(d):
    sc_clue.__wrapped__(d) if hasattr(sc_clue, "__wrapped__") else None
    grad(d, (12, 34, 30), (40, 84, 60))
    r = random.Random(73)
    for i in range(16):
        x = r.uniform(0, SW); w = r.uniform(3, 6); c = r.choice([(34, 78, 54), (28, 64, 48), (44, 96, 62)])
        d.rect(x, 0, x + w, SH, c)
        for yy in range(int(r.uniform(0, 16)), SH, 16):
            d.rect(x - 0.5, yy, x + w + 0.5, yy + 1, dark(c, 0.6))
    d.rect(0, 54, SW, SH, (30, 60, 44))
    put_char(d, "rabbit", 30, -11); put_char(d, "tewi", 110, -11)
scene("ev_gap", sc_gap); scene("ev_clue", sc_clue); scene("ev_road", sc_road); scene("ev_library", sc_library); scene("ev_bamboo", sc_bamboo)
def b_fam(d):
    d.ell(5, 5, 4.6, 4.6, (120, 70, 190)); d.ell(5, 5, 3.2, 3.2, (190, 140, 255)); d.ell(5, 5, 1.4, 2.4, (40, 16, 60)); d.ell(3.8, 3.6, 0.8, 0.8, WHITE)
small("familiar", 10, 10, b_fam)
scene("ev_shrine", sc_shrine); scene("ev_kappa", sc_kappa); scene("ev_fairies", sc_fairies)
scene("ev_tea", sc_tea); scene("ev_kedama", sc_kedama); scene("ev_kourin", sc_kourin); scene("ev_rest", sc_rest)

# 标题画面背景（立绘由游戏叠加）
d = Dr(200, 150, S)
grad(d, (10, 8, 32), (76, 44, 106), bands=14); stars(d, 130, 112, 31); moon(d, 152, 36, 21)
hills(d, 116, 6, (32, 30, 64), 32); hills(d, 130, 4, (22, 20, 46), 33)
torii(d, 100, 150, 1.7, (156, 44, 64))
d.save("title_art")

# 第一章战斗背景：雾之湖（纵向可循环）
d = Dr(200, 256, S)
d.rect(0, 0, 200, 256, (24, 36, 70))
r = random.Random(41)
for i in range(300):
    x = r.uniform(0, 200); y = r.uniform(0, 256); l = r.uniform(4, 18)
    c = r.choice([(34, 52, 94), (30, 46, 86), (44, 66, 112)])
    d.rect(x, y, x + l, y + 0.5, c)
    if x + l > 200:
        d.rect(0, y, x + l - 200, y + 0.5, c)
for i in range(40):
    x = r.uniform(0, 198); y = r.uniform(0, 255)
    d.rect(x, y, x + 0.5, y + 0.5, (156, 186, 226)); d.rect(x + 0.5, y, x + 1.5, y + 0.5, (94, 124, 174))
d.save("bg_lake")
# 第二章：红魔馆的走廊（红地毯）
d = Dr(200, 256, S)
d.rect(0, 0, 200, 256, (44, 26, 30)); d.rect(12, 0, 188, 256, (112, 30, 46))
for x in (16, 181.5):
    d.rect(x, 0, x + 2.5, 256, (206, 160, 70))
for yy in range(0, 256, 64):
    for xx in (60, 100, 140):
        d.poly([(xx, yy + 12), (xx + 14, yy + 32), (xx, yy + 52), (xx - 14, yy + 32)], (96, 24, 40))
        d.poly([(xx, yy + 22), (xx + 7, yy + 32), (xx, yy + 42), (xx - 7, yy + 32)], (128, 40, 56))
    d.rect(22, yy, 178, yy + 1, (96, 24, 40))
d.save("bg_mansion")
# 第三章：迷途竹林
d = Dr(200, 256, S)
d.rect(0, 0, 200, 256, (14, 34, 30))
r2 = random.Random(52)
for i in range(22):
    x = r2.uniform(0, 196); w = r2.uniform(2.5, 6); c = r2.choice([(34, 78, 54), (28, 64, 48), (44, 96, 62)])
    d.rect(x, 0, x + w, 256, c); d.rect(x + w * 0.7, 0, x + w, 256, dark(c, 0.8))
    for yy in range(int(r2.uniform(0, 32)), 256, 32):
        d.rect(x - 0.5, yy, x + w + 0.5, yy + 1, dark(c, 0.6))
for i in range(60):
    x = r2.uniform(0, 200); y = r2.uniform(0, 250); l = r2.uniform(4, 9); a = r2.uniform(-0.6, 0.6)
    d.poly([(x, y), (x + l * math.cos(a), y + l * math.sin(a) + 1.2), (x + l * 0.5, y - 1)], (60, 124, 74))
d.save("bg_bamboo")
# 雾：先画白块再模糊，边缘柔和
m = Image.new("L", (192 * S, 48 * S), 0)
md = ImageDraw.Draw(m)
for i in range(9):
    cx = r.uniform(40, 152) * S; cy = r.uniform(16, 32) * S; rx = r.uniform(18, 40) * S; ry = r.uniform(5, 10) * S
    md.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=70)
m = m.filter(ImageFilter.GaussianBlur(7 * S))
mist = Image.new("RGBA", m.size, (206, 220, 244, 255)); mist.putalpha(m)
mist.save(os.path.join(OUT, "mist.png"))

# 物品卡面背景（行囊与详情页用）：按流派配色，带一个淡淡的纹样
def card_bg(key, c, motif):
    d = Dr(24, 32, S)
    for i in range(16):
        k = i / 15
        d.rect(0, i * 2, 24, i * 2 + 2, tuple(int(c[j] * (0.55 + 0.45 * (1 - k))) for j in range(3)))
    m = light(c, 0.25)
    motif(d, tuple(m[:3]))
    d.rect(0, 0, 24, 1, light(c, 0.5)); d.rect(0, 31, 24, 32, dark(c, 0.5)); d.rect(0, 0, 1, 32, light(c, 0.3)); d.rect(23, 0, 24, 32, dark(c, 0.6))
    d.save("card_" + key)
def m_atk(d, c):
    d.rect(7, 5, 17, 27, c); d.rect(8.5, 6.5, 15.5, 25.5, dark(c, 0.8))
def m_graze(d, c):
    for i in range(5):
        d.line([(2 + i * 5, 30), (10 + i * 5, 2)], c, 0.6)
def m_bomb(d, c):
    d.ell(12, 16, 9, 9, c); d.ell(12, 16, 7.6, 7.6, dark(c, 0.8)); d.ell(12, 12, 2, 2, c); d.ell(12, 20, 2, 2, c)
def m_burst(d, c):
    for i in range(8):
        a = i * math.pi / 4
        d.poly([(12, 16), (12 + math.cos(a - 0.12) * 13, 16 + math.sin(a - 0.12) * 13), (12 + math.cos(a + 0.12) * 13, 16 + math.sin(a + 0.12) * 13)], c)
def m_fam(d, c):
    d.ell(12, 10, 4.5, 4.5, c); d.poly([(12, 13), (19, 27), (5, 27)], c)
def m_slow(d, c):
    d.poly([(2, 16), (12, 9), (22, 16), (12, 23)], c); d.ell(12, 16, 4, 4, dark(c, 0.75))
def m_misc(d, c):
    d.ell(12, 16, 8, 8, c); d.rect(9.5, 13.5, 14.5, 18.5, dark(c, 0.75))
for key, col, mo in (("atk", (120, 70, 150), m_atk), ("graze", (50, 130, 160), m_graze), ("bomb", (160, 60, 80), m_bomb), ("burst", (180, 110, 50), m_burst),
                     ("fam", (170, 90, 150), m_fam), ("slow", (60, 130, 90), m_slow), ("misc", (86, 92, 130), m_misc)):
    card_bg(key, col, mo)

# 应用图标
ic = Dr(192, 192, 1)
grad(ic, (46, 28, 96), (136, 56, 116), bands=24)
ic.ell(96, 96, 80, 80, (252, 242, 218)); ic.ell(96, 96, 72, 72, (66, 40, 106))
ic.paste(char_img("reimu", 3.2).crop((0, 24, 154, 194)), 19, 14)
ic.im.save(os.path.join(ROOT, "assets", "icon.png"))

# 预览图（开发用）
names = ["c_ran", "c_yukari", "eye", "eye_big", "shiki"]
sheet = Image.new("RGBA", (len(names) * 104, 560), (50, 46, 80, 255))
for i, n in enumerate(names):
    im = Image.open(os.path.join(OUT, n + ".png"))
    sheet.alpha_composite(im.resize((im.width * 2, im.height * 2), Image.NEAREST), (i * 104 + 4, 6))
for i, n in enumerate(PORTRAITS[12:]):
    sheet.alpha_composite(Image.open(os.path.join(OUT, "p_%s.png" % n)), (i * 172 + 4, 160))
sheet.alpha_composite(Image.open(os.path.join(OUT, "bullets.png")), (4, 366 + 44))
sheet.save("/tmp/art_chars.png")
sc = Image.new("RGBA", (SW * S * 2 + 6, (SH * S + 4) * 4), (20, 20, 30, 255))
for i, n in enumerate(["ev_shrine", "ev_kappa", "ev_fairies", "ev_tea", "ev_kedama", "ev_kourin", "ev_rest"]):
    sc.alpha_composite(Image.open(os.path.join(OUT, n + ".png")), ((i % 2) * (SW * S + 6), (i // 2) * (SH * S + 4)))
sc.alpha_composite(Image.open(os.path.join(ROOT, "assets", "icon.png")).resize((128, 128)), (SW * S + 100, 3 * (SH * S + 4)))
sc.save("/tmp/art_scenes.png")
print("ok")
