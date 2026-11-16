#!/usr/bin/env python3
"""生成全部像素美术：角色、敌人、子弹、图标、背景、事件插画、应用图标。
用法: python3 tools/gen_art.py   （输出到 assets/sprites/ 与 assets/icon.png）"""
import os, random, math
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
os.makedirs(OUT, exist_ok=True)
K = (30, 20, 44, 255)          # 描边色
SKIN = (252, 222, 196, 255)
SKIN_D = (226, 170, 150, 255)

def rgba(c, a=255):
    return (c[0], c[1], c[2], a if len(c) < 4 else c[3])
def dark(c, k=0.68):
    return (int(c[0] * k), int(c[1] * k), int(c[2] * k), 255)
def light(c, k=0.35):
    return (int(c[0] + (255 - c[0]) * k), int(c[1] + (255 - c[1]) * k), int(c[2] + (255 - c[2]) * k), 255)

class Cv:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    def px(s, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < s.w and 0 <= y < s.h:
            s.im.putpixel((x, y), rgba(c))
    def rect(s, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                s.px(x, y, c)
    def ell(s, cx, cy, rx, ry, c):
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    s.px(x, y, c)
    def get(s, x, y):
        if 0 <= x < s.w and 0 <= y < s.h:
            return s.im.getpixel((x, y))
        return (0, 0, 0, 0)
    def outline(s, c=K):
        src = s.im.copy()
        for y in range(s.h):
            for x in range(s.w):
                if src.getpixel((x, y))[3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < s.w and 0 <= ny < s.h and src.getpixel((nx, ny))[3] > 200:
                            s.im.putpixel((x, y), c); break
    def paste(s, im, x, y, scale=1):
        if scale != 1:
            im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        s.im.alpha_composite(im, (int(x), int(y)))
    def save(s, name):
        s.im.save(os.path.join(OUT, name + ".png"))
        return s.im

def ascii_img(rows, pal, outline=True):
    h, w = len(rows), max(len(r) for r in rows)
    pad = 1 if outline else 0
    cv = Cv(w + pad * 2, h + pad * 2)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                cv.px(x + pad, y + pad, pal[ch])
    if outline:
        cv.outline()
    return cv

# ---------------------------------------------------------------- Q版角色模板
CW, CH = 22, 28   # 画布（含描边与饰品余量）；身体中心 x=10.5

def chibi(hair, dress, eye=(90, 60, 50), top=None, sleeve=None, trim=(250, 248, 240), long_hair=False,
          arms_out=False, robe=False, shoe=(110, 50, 50), frame=0, extra=None, back=None, bangs=1):
    cv = Cv(CW, CH)
    ox, oy = 1, 2
    top = top or dress
    sleeve = sleeve or top
    def P(x, y, c): cv.px(x + ox, y + oy, c)
    def R(x0, y0, x1, y1, c): cv.rect(x0 + ox, y0 + oy, x1 + ox, y1 + oy, c)
    if back:
        back(cv, ox, oy, frame)
    if long_hair:
        R(3, 9, 4, 17, hair); R(15, 9, 16, 17, hair)
        R(3, 16, 4, 17, dark(hair)); R(15, 16, 16, 17, dark(hair))
    # 腿与鞋
    if not robe:
        R(7, 22, 8, 23, SKIN); R(11, 22, 12, 23, SKIN)
        R(6, 24, 8, 24, shoe); R(11, 24, 13, 24, shoe)
    else:
        R(6, 24, 8, 24, shoe); R(11, 24, 13, 24, shoe)
    # 裙/袍
    if robe:
        R(6, 17, 13, 23, dress); R(12, 17, 13, 23, dark(dress))
    else:
        R(6, 17, 13, 17, dress); R(5, 18, 14, 18, dress); R(4, 19, 15, 21, dress)
        R(13, 18, 14, 18, dark(dress)); R(14, 19, 15, 20, dark(dress))
        R(4, 21, 15, 21, trim)
    # 上身
    R(6, 14, 13, 16, top); R(12, 14, 13, 16, dark(top))
    R(9, 14, 10, 14, SKIN)
    # 手臂
    if arms_out:
        R(1, 14, 5, 15, sleeve); R(14, 14, 18, 15, sleeve)
        P(0, 14, SKIN); P(0, 15, SKIN); P(19, 14, SKIN); P(19, 15, SKIN)
    else:
        R(4, 14, 5, 17, sleeve); R(14, 14, 15, 17, sleeve)
        R(4, 18, 5, 18, SKIN); R(14, 18, 15, 18, SKIN)
    # 头
    cv.ell(9.5 + ox, 8.2 + oy, 6.3, 5.7, hair)
    cv.ell(9.5 + ox, 9.8 + oy, 4.9, 3.9, SKIN)
    R(5, 6, 14, 6, hair)
    if bangs == 1:
        for x in (5, 6, 9, 10, 13, 14): P(x, 7, hair)
    elif bangs == 2:
        for x in (5, 7, 8, 11, 12, 14): P(x, 7, hair)
    R(6, 3, 9, 3, light(hair)); P(5, 4, light(hair))
    # 脸
    for ex in (6, 12):
        R(ex, 9, ex + 1, 9, K); R(ex, 10, ex + 1, 11, eye); P(ex, 10, (255, 255, 255))
    P(5, 12, (250, 170, 170)); P(14, 12, (250, 170, 170))
    P(9, 12, SKIN_D); P(10, 12, SKIN_D)
    if extra:
        extra(cv, ox, oy, frame)
    cv.outline()
    return cv

def wings(color=(190, 235, 255), big=False):
    def f(cv, ox, oy, frame):
        d = frame
        rx = 4.2 if big else 3.4
        for sx in (-1, 1):
            cx = 9.5 + ox + sx * (9.0 if big else 8.2)
            cv.ell(cx, 12 + oy + d, rx, 3.6 - d * 0.8, color)
            cv.ell(cx - sx * 0.5, 17 + oy - d * 0.5, rx - 1.2, 2.4, dark(color, 0.85))
    return f

def bow(color, y=0):
    def f(cv, ox, oy, frame):
        d = dark(color)
        cv.rect(4 + ox, y + oy - 1, 8 + ox, y + oy + 2, color); cv.rect(11 + ox, y + oy - 1, 15 + ox, y + oy + 2, color)
        cv.px(4 + ox, y + oy - 1, (0, 0, 0, 0)); cv.px(15 + ox, y + oy - 1, (0, 0, 0, 0))
        cv.rect(5 + ox, y + oy + 1, 7 + ox, y + oy + 2, d); cv.rect(12 + ox, y + oy + 1, 14 + ox, y + oy + 2, d)
        cv.rect(9 + ox, y + oy, 10 + ox, y + oy + 2, color)
    return f

def chain(*fs):
    def f(cv, ox, oy, frame):
        for g in fs:
            g(cv, ox, oy, frame)
    return f

RED = (220, 52, 60); WHITE = (250, 248, 240); BLUE = (70, 120, 230); YEL = (250, 210, 70)

def reimu_extra(cv, ox, oy, frame):
    bow(RED, 0)(cv, ox, oy, frame)
    for sx in (3, 15):
        cv.rect(sx + ox, 9 + oy, sx + 1 + ox, 13 + oy, RED)
        cv.rect(sx + ox, 10 + oy, sx + 1 + ox, 10 + oy, WHITE); cv.rect(sx + ox, 12 + oy, sx + 1 + ox, 12 + oy, WHITE)
    cv.rect(9 + ox, 15 + oy, 10 + ox, 16 + oy, YEL)
    cv.rect(4 + ox, 17 + oy, 5 + ox, 17 + oy, RED); cv.rect(14 + ox, 17 + oy, 15 + ox, 17 + oy, RED)

def tie(color):
    def f(cv, ox, oy, frame):
        cv.rect(7 + ox, 14 + oy, 12 + ox, 14 + oy, WHITE)
        cv.rect(9 + ox, 15 + oy, 10 + ox, 16 + oy, color)
    return f

def side_ribbon(color):
    def f(cv, ox, oy, frame):
        cv.rect(13 + ox, 2 + oy, 16 + ox, 4 + oy, color); cv.px(14 + ox, 3 + oy, dark(color))
    return f

def ponytail(hair, ribbon):
    def f(cv, ox, oy, frame):
        cv.ell(2.5 + ox, 6 + oy, 2.2, 3.2, hair); cv.rect(3 + ox, 4 + oy, 4 + ox, 5 + oy, ribbon)
    return f

def ice_wings(cv, ox, oy, frame):
    c = (170, 235, 255); w = (240, 252, 255)
    for sx in (-1, 1):
        for i, (dx, dy) in enumerate(((9, 10), (11, 14), (9, 18))):
            x = 9.5 + ox + sx * dx; y = dy + oy + (frame if i == 1 else 0)
            for k in range(-2, 3):
                ww = 2 - abs(k)
                cv.rect(x - ww * 0.6, y + k, x + ww * 0.6, y + k, c)
            cv.px(x, y, w)

def cap(color):
    def f(cv, ox, oy, frame):
        cv.rect(4 + ox, 1 + oy, 15 + ox, 4 + oy, color); cv.rect(5 + ox, 0 + oy, 14 + ox, 0 + oy, color)
        cv.rect(3 + ox, 5 + oy, 16 + ox, 5 + oy, dark(color))
    return f

def twintails(hair):
    def f(cv, ox, oy, frame):
        cv.ell(2.5 + ox, 11 + oy, 1.8, 2.6, hair); cv.ell(16.5 + ox, 11 + oy, 1.8, 2.6, hair)
    return f

def glasses(cv, ox, oy, frame):
    cv.rect(5 + ox, 9 + oy, 14 + ox, 9 + oy, (60, 60, 80))
    cv.px(8 + ox, 10 + oy, (60, 60, 80)); cv.px(11 + ox, 10 + oy, (60, 60, 80))

def flower(cv, ox, oy, frame):
    cv.ell(9.5 + ox, 1 + oy, 4.2, 2.6, YEL); cv.ell(9.5 + ox, 1 + oy, 1.8, 1.2, (150, 90, 40))

CHARS = {}
def char(name, frames=1, **kw):
    for f in range(frames):
        cv = chibi(frame=f, **kw)
        cv.save(name if frames == 1 else "%s_%d" % (name, f))
        if f == 0:
            CHARS[name] = cv.im

char("reimu", hair=(78, 48, 46), dress=RED, sleeve=WHITE, long_hair=True, extra=reimu_extra, eye=(120, 60, 50))
char("fairy", 2, hair=(250, 215, 90), dress=BLUE, back=wings(), extra=tie(YEL), eye=(60, 90, 160))
char("fairy_red", 2, hair=(250, 150, 70), dress=RED, back=wings((255, 220, 200)), extra=tie(WHITE), eye=(150, 50, 50))
char("bigfairy", 2, hair=(110, 200, 110), dress=(250, 200, 60), back=wings((255, 245, 190), True), extra=chain(flower, tie(RED)), eye=(60, 120, 60), long_hair=True)
char("rumia", hair=(250, 215, 90), dress=(56, 48, 70), arms_out=True, sleeve=WHITE, extra=chain(tie(RED), side_ribbon(RED)), eye=(220, 50, 60), shoe=(150, 40, 50))
char("daiyousei", 2, hair=(90, 200, 120), dress=BLUE, back=wings((225, 250, 235), True), extra=chain(ponytail((90, 200, 120), YEL), tie(YEL)), eye=(50, 120, 80))
char("cirno", 2, hair=(125, 195, 250), dress=BLUE, sleeve=WHITE, back=ice_wings, extra=chain(bow((40, 90, 190), 0), tie(RED)), eye=(60, 110, 220), shoe=(60, 80, 160))
char("nitori", hair=(90, 160, 230), dress=(90, 170, 220), extra=chain(twintails((90, 160, 230)), cap((90, 170, 110)), tie(YEL)), eye=(60, 110, 200), shoe=(60, 90, 120))
char("rinnosuke", hair=(215, 215, 225), dress=(60, 80, 150), top=(40, 50, 70), robe=True, extra=glasses, eye=(190, 160, 70), shoe=(50, 40, 40), bangs=2)
char("sunny", hair=(250, 190, 90), dress=RED, back=wings((255, 240, 200)), extra=chain(twintails((250, 190, 90)), tie(WHITE)), eye=(60, 120, 200))
char("luna", hair=(250, 235, 150), dress=WHITE, back=wings((230, 230, 255)), extra=chain(bow((50, 45, 60), 0), tie((50, 45, 60))), eye=(190, 60, 60), long_hair=True)
char("starf", hair=(60, 50, 80), dress=BLUE, back=wings((210, 225, 255)), extra=chain(bow(BLUE, 0), tie(WHITE)), eye=(110, 80, 60), long_hair=True)

# 毛玉（两帧）
for f in range(2):
    cv = Cv(16, 16)
    rnd = random.Random(3 + f)
    cv.ell(7.5, 7.5, 5.2, 5.2, WHITE)
    for i in range(14):
        a = i / 14 * math.tau + f * 0.22
        cv.px(7.5 + math.cos(a) * 6.2, 7.5 + math.sin(a) * 6.2, WHITE)
        cv.px(7.5 + math.cos(a) * 5.4, 7.5 + math.sin(a) * 5.4, WHITE)
    cv.ell(8.5, 9.5, 3.5, 3.0, (215, 220, 235))
    cv.rect(5, 6, 5, 8, K); cv.rect(9, 6, 9, 8, K)
    cv.rect(6, 10, 8, 10, (220, 80, 90))
    cv.outline()
    cv.save("kedama_%d" % f)
    if f == 0: CHARS["kedama"] = cv.im

# ---------------------------------------------------------------- 自机弹 / 道具
P = {"R": RED, "r": (150, 30, 48), "W": WHITE, "w": (200, 204, 220), "Y": YEL, "B": BLUE, "b": (40, 80, 170),
     "c": (170, 230, 250), "O": (250, 150, 50), "K": K, "S": SKIN, "V": (170, 100, 240), "v": (110, 60, 180), "G": (90, 200, 110),
     "o": (200, 140, 30), "D": (120, 80, 20)}
def spr(name, rows, outline=False):
    cv = ascii_img(rows, P, outline)
    cv.save(name)
    return cv.im
spr("amulet", ["RRRR", "RWWR", "RWWR", "RRRR", "RWWR", "RWWR", "RRRR"])
spr("needle", ["W", "W", "c", "c", "c", "c", "c", "B", "B"])
spr("orb", ["..RRRR..", ".RWWWWR.", "RWWWWWWR", "RWWWWWWR", "RWWWWWWR", "RWWWWWWR", ".RWWWWR.", "..RRRR.."])
spr("gapshot", [".VV.", "VWWV", "VWWV", "VWWV", "VWWV", ".VV."])
spr("gap", ["....vvvvvv....", "..vvKKKKKKvv..", "vvKKKRWWRKKKvv", "..vvKKKKKKvv..", "....vvvvvv...."])
spr("hitbox", [".RRR.", "RWWWR", "RWWWR", "RWWWR", ".RRR."])
spr("heart", [".RR.RR.", "RRRRRRR", "RWRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."], True)
spr("heart_empty", [".ww.ww.", "w..w..w", "w.....w", "w.....w", ".w...w.", "..w.w..", "...w..."])
spr("star", ["...Y...", "...Y...", "YYYYYYY", ".YYWYY.", "..YYY..", ".YY.YY.", ".Y...Y."])
spr("knife", [".W.", "WWW", "WWW", "WwW", "WwW", "WWW", "KKK", ".b.", ".b."])
spr("bat", ["R.......R", "RR.R.R.RR", "RRRRRRRRR", ".RRrRrRR.", "..RR.RR.."])
spr("fire", ["..O..", ".OYO.", ".OYO.", "OYYYO", "OOYOO", ".ROR.", "..R.."])
spr("ice", ["..W..", ".WcW.", ".ccc.", "ccccc", ".ccB.", ".cB..", "..B.."])
spr("moon", ["..YYY..", ".YYY...", "YYY....", "YYY....", "YYY....", ".YYY...", "..YYY.."])
spr("doll", ["..YYYY..", ".YYYYYY.", ".YSSSSY.", ".YSKKSY.", "..SSSS..", ".BBWWBB.", ".BBBBBB.", "BBBBBBBB", ".WWWWWW.", "..S..S.."], True)
spr("yinyang", ["..WWWRR..", ".WWWWRRR.", "WWWRWRRRR", "WWWWWRRRR", "WWWWRRRRR", "WWWWRRRRR", "WWWWRWRRR", ".WWWRRRR.", "..WWRRR.."], True)
# 钱：带方孔的铜钱，深色描边，和敌弹（白芯圆弹）明显区分
spr("coin", [".ooooo.", "oYYYYYo", "oYDDDYo", "oYD.DYo", "oYDDDYo", "oYYYYYo", ".ooooo."], True)
# 图标专用
spr("ic_laser", ["...cc...", "...WW...", "...WW...", "...WW...", "...WW...", "...WW...", "..BWWB..", ".BBBBBB."])
spr("ic_pillar", ["OOOOOOOO", ".oYYYYo.", ".oYYYYo.", ".oYYYYo.", ".oYYYYo.", ".oYYYYo.", ".oYYYYo.", "OOOOOOOO"])
spr("ic_starmap", ["Y......c", "..c.....", "....Y...", ".Y......", "......c.", "...c....", "Y.....Y.", "....c..."])
# 地图节点图标
spr("n_battle", ["......WW.", ".....WWW.", "....WWW..", "...WWW...", "o.WWW....", ".oWW.....", "DDo......", "DD.o....."])
spr("n_elite", [".R.....R.", ".RR...RR.", ".RRRRRRR.", "RRWRRRWRR", "RRKRRRKRR", "RRRRRRRRR", ".RWRWRWR.", "..RRRRR.."])
spr("n_event", ["..GGGG...", ".GG..GG..", ".....GG..", "....GG...", "...GG....", "...GG....", ".........", "...GG...."])
spr("n_shop", ["..oooo...", "...oo....", "..YYYY...", ".YYYYYY..", "YYYDDYYY.", "YYYDDYYY.", ".YYYYYY..", "..YYYY..."])
spr("n_rest", ["RRRRRRRRR", ".RRRRRRR.", "..R...R..", ".RRRRRRR.", "..R...R..", "..R...R..", "..R...R..", "..R...R.."])
spr("n_boss", ["Y...Y...Y", "YY.YYY.YY", "YYYYYYYYY", "YYRYYYRYY", "YYYYYYYYY", ".YYYYYYY.", ".ooooooo.", "........."])

# ---------------------------------------------------------------- 敌弹图集
# 16x16 一格；行=形状(小圆/大圆/米粒)，列=颜色。刻意不用黄色，避免和钱混淆。
COLS = [(240, 60, 70), (70, 120, 250), (70, 210, 100), (255, 130, 200), (175, 90, 245), (90, 220, 240), (225, 228, 240)]
atlas = Image.new("RGBA", (16 * len(COLS), 48), (0, 0, 0, 0))
def disk(im, cx, cy, r, col):
    for y in range(16):
        for x in range(16):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                im.putpixel((x, y), col)
for i, c in enumerate(COLS):
    dk = dark(c, 0.5); col = rgba(c)
    cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    disk(cell, 8, 8, 4.2, dk); disk(cell, 8, 8, 3.2, col); disk(cell, 8, 8, 1.8, (255, 255, 255, 255))
    atlas.paste(cell, (i * 16, 0))
    cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    disk(cell, 8, 8, 7.2, dk); disk(cell, 8, 8, 6.2, col); disk(cell, 8, 8, 4.0, (255, 255, 255, 255))
    atlas.paste(cell, (i * 16, 16))
    cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(3, 13):
        for x in range(6, 10):
            if y in (3, 12) and x in (6, 9):
                continue
            edge = y in (3, 12) or x in (6, 9)
            cell.putpixel((x, y), dk if edge else ((255, 255, 255, 255) if 6 <= y <= 9 else col))
    atlas.paste(cell, (i * 16, 32))
atlas.save(os.path.join(OUT, "bullets.png"))

# ---------------------------------------------------------------- 图标底板（按稀有度）
for name, c in (("tile_0", (70, 76, 110)), ("tile_1", (60, 110, 190)), ("tile_2", (200, 140, 40)), ("tile_w", (120, 60, 110))):
    cv = Cv(16, 16)
    cv.rect(1, 0, 14, 15, dark(c, 0.55)); cv.rect(0, 1, 15, 14, dark(c, 0.55))
    cv.rect(1, 1, 14, 14, c); cv.rect(2, 2, 13, 13, dark(c, 0.45))
    cv.rect(2, 2, 13, 2, dark(c, 0.8))
    cv.save(name)

# ---------------------------------------------------------------- 背景与插画
def grad(cv, top, bottom, y0=0, y1=None):
    y1 = cv.h if y1 is None else y1
    for y in range(y0, y1):
        k = (y - y0) / max(1, y1 - y0 - 1)
        k = round(k * 7) / 7   # 色带感
        c = tuple(int(top[i] + (bottom[i] - top[i]) * k) for i in range(3))
        cv.rect(0, y, cv.w - 1, y, c)

def stars(cv, n, y1, seed):
    r = random.Random(seed)
    for i in range(n):
        cv.px(r.randrange(cv.w), r.randrange(y1), r.choice([(255, 255, 230), (160, 170, 220), (110, 110, 170)]))

def moon(cv, cx, cy, r):
    cv.ell(cx, cy, r + 3, r + 3, (60, 60, 110)); cv.ell(cx, cy, r, r, (250, 245, 200)); cv.ell(cx - r * 0.3, cy - r * 0.2, r * 0.25, r * 0.2, (230, 222, 170))

def hills(cv, y, amp, color, seed):
    r = random.Random(seed)
    ph = [r.uniform(0, 6.28) for _ in range(3)]
    for x in range(cv.w):
        h = y + math.sin(x * 0.045 + ph[0]) * amp + math.sin(x * 0.11 + ph[1]) * amp * 0.4
        cv.rect(x, int(h), x, cv.h - 1, color)

def trees(cv, y, n, color, seed):
    r = random.Random(seed)
    for i in range(n):
        x = r.randrange(cv.w); hh = r.randrange(10, 22)
        for k in range(hh):
            ww = (k * 5) // hh
            cv.rect(x - ww, y - hh + k, x + ww, y - hh + k, color)
        cv.rect(x, y, x, y + 2, dark(color))

def torii(cv, cx, base, s=1.0, color=(200, 50, 55)):
    w = int(22 * s); h = int(30 * s); t = max(2, int(3 * s))
    d = dark(color)
    cv.rect(cx - w, base - h, cx - w + t, base, color); cv.rect(cx + w - t, base - h, cx + w, base, color)
    cv.rect(cx - w - 5, base - h - t, cx + w + 5, base - h, color)
    cv.rect(cx - w - 7, base - h - t - 2, cx + w + 7, base - h - t, d)
    cv.rect(cx - w, base - h + t * 2, cx + w, base - h + t * 3 - 1, color)
    cv.rect(cx - w, base - 3, cx - w + t, base, d); cv.rect(cx + w - t, base - 3, cx + w, base, d)

SW, SH = 184, 64
def scene(name, build):
    cv = Cv(SW, SH)
    build(cv)
    # 边框
    for x in range(SW):
        cv.px(x, 0, (150, 135, 205)); cv.px(x, SH - 1, (150, 135, 205))
    for y in range(SH):
        cv.px(0, y, (150, 135, 205)); cv.px(SW - 1, y, (150, 135, 205))
    cv.save(name)

def sc_shrine(cv):
    grad(cv, (14, 12, 40), (50, 34, 86)); stars(cv, 40, 36, 1); moon(cv, 150, 14, 7)
    hills(cv, 44, 4, (24, 34, 50), 2); trees(cv, 50, 14, (18, 44, 40), 3)
    cv.rect(0, 52, SW - 1, SH - 1, (40, 46, 56)); cv.rect(70, 52, 114, SH - 1, (86, 86, 96))
    torii(cv, 92, 54, 0.8)
    cv.rect(84, 44, 100, 53, (120, 80, 50)); cv.rect(82, 41, 102, 44, (70, 50, 60)); cv.rect(88, 49, 96, 53, (60, 40, 30))
def sc_kappa(cv):
    grad(cv, (20, 40, 60), (60, 110, 110)); hills(cv, 40, 5, (30, 70, 70), 5)
    cv.rect(0, 50, SW - 1, SH - 1, (70, 100, 70))
    for i in range(8):
        cv.rect(36 + i * 10, 18, 45 + i * 10, 24, (90, 170, 110) if i % 2 == 0 else WHITE)
    cv.rect(38, 24, 39, 52, (110, 80, 50)); cv.rect(112, 24, 113, 52, (110, 80, 50))
    cv.rect(34, 40, 118, 52, (140, 100, 60)); cv.rect(34, 40, 118, 42, (170, 125, 80))
    r = random.Random(9)
    for i in range(7):
        x = 40 + i * 11; c = r.choice([(150, 150, 165), (110, 120, 140), (180, 160, 90)])
        cv.rect(x, 33, x + 6, 39, c); cv.px(x + 2, 35, r.choice([(250, 80, 80), (90, 250, 120), YEL])); cv.px(x + 4, 37, (40, 40, 50))
    cv.paste(CHARS["nitori"], 128, 6, 2)
def sc_fairies(cv):
    grad(cv, (20, 50, 60), (90, 150, 110)); trees(cv, 52, 26, (26, 70, 56), 11); trees(cv, 58, 14, (20, 50, 44), 12)
    cv.rect(0, 56, SW - 1, SH - 1, (40, 80, 56))
    for i, n in enumerate(("sunny", "luna", "starf")):
        cv.paste(CHARS[n], 26 + i * 48, 4 + (i % 2) * 4, 2)
    cv.paste(Image.open(os.path.join(OUT, "coin.png")), 150, 20, 2)
def sc_tea(cv):
    grad(cv, (30, 30, 70), (120, 110, 150), 0, 36); moon(cv, 40, 12, 6)
    grad(cv, (50, 70, 110), (24, 36, 70), 36, SH)
    r = random.Random(4)
    for i in range(40):
        x = r.randrange(SW); y = r.randrange(38, SH - 2); cv.rect(x, y, x + r.randrange(3, 10), y, (110, 130, 170))
    for i in range(6):
        x = r.randrange(SW); y = r.randrange(26, 44); cv.ell(x, y, 18, 3, (170, 170, 200, 90))
    cv.rect(0, 54, SW - 1, SH - 1, (50, 70, 60))
    cv.rect(80, 44, 110, 46, WHITE); cv.rect(94, 46, 96, 56, (150, 150, 160)); cv.rect(88, 56, 102, 57, (150, 150, 160))
    cv.ell(92, 39, 5, 4, (230, 230, 240)); cv.rect(97, 38, 100, 39, (230, 230, 240)); cv.rect(90, 34, 94, 35, (200, 60, 70))
    cv.rect(102, 41, 106, 43, (230, 230, 240)); cv.px(104, 38, (220, 220, 230)); cv.px(105, 36, (220, 220, 230)); cv.px(103, 34, (200, 200, 215))
def sc_kedama(cv):
    grad(cv, (26, 24, 60), (80, 70, 120)); hills(cv, 46, 4, (40, 44, 70), 8)
    cv.rect(0, 54, SW - 1, SH - 1, (50, 54, 70))
    r = random.Random(6)
    for i in range(34):
        cv.paste(CHARS["kedama"], r.randrange(-4, SW - 12), r.randrange(2, 46), 1)
def sc_kourin(cv):
    grad(cv, (60, 44, 40), (96, 70, 56))
    r = random.Random(13)
    for sy in (14, 30):
        cv.rect(8, sy, 120, sy + 1, (130, 90, 60))
        for i in range(12):
            x = 12 + i * 9; h = r.randrange(4, 10)
            cv.rect(x, sy - h, x + 5, sy - 1, r.choice([(90, 140, 190), (190, 90, 90), (200, 180, 100), (120, 170, 120), (160, 120, 190)]))
    cv.rect(0, 46, SW - 1, SH - 1, (110, 76, 52)); cv.rect(0, 46, SW - 1, 48, (150, 106, 70))
    cv.ell(60, 40, 7, 7, (120, 70, 200)); cv.ell(58, 38, 3, 3, (200, 170, 255)); cv.ell(60, 40, 10, 10, (160, 120, 255, 60))
    cv.paste(CHARS["rinnosuke"], 130, 4, 2)
def sc_rest(cv):
    grad(cv, (16, 14, 44), (70, 44, 96)); stars(cv, 50, 40, 21); moon(cv, 30, 14, 8)
    hills(cv, 46, 3, (26, 30, 56), 22); trees(cv, 52, 10, (20, 40, 44), 23)
    cv.rect(0, 54, SW - 1, SH - 1, (44, 48, 60)); cv.rect(74, 54, 110, SH - 1, (96, 96, 106))
    torii(cv, 92, 56, 1.25)
    for x in (52, 132):
        cv.rect(x, 44, x + 4, 55, (120, 120, 130)); cv.rect(x - 1, 40, x + 5, 44, (130, 130, 140)); cv.rect(x + 1, 41, x + 3, 43, (255, 220, 120))
    cv.paste(CHARS["reimu"], 81, 4, 2)

scene("ev_shrine", sc_shrine); scene("ev_kappa", sc_kappa); scene("ev_fairies", sc_fairies)
scene("ev_tea", sc_tea); scene("ev_kedama", sc_kedama); scene("ev_kourin", sc_kourin); scene("ev_rest", sc_rest)

# 标题画面
cv = Cv(200, 150)
grad(cv, (10, 8, 30), (70, 40, 100)); stars(cv, 90, 110, 31); moon(cv, 150, 34, 20)
hills(cv, 118, 6, (30, 28, 60), 32); hills(cv, 130, 4, (20, 18, 44), 33)
torii(cv, 100, 140, 1.5, (150, 40, 60))
cv.paste(CHARS["reimu"], 78, 52, 2)
cv.save("title_art")

# 第一章战斗背景：雾之湖（纵向可循环的水面）
cv = Cv(200, 256)
cv.rect(0, 0, 199, 255, (22, 34, 66))
r = random.Random(41)
for i in range(240):
    x = r.randrange(200); y = r.randrange(256); l = r.randrange(4, 16)
    c = r.choice([(34, 52, 92), (30, 46, 84), (44, 66, 110)])
    for k in range(l):
        cv.px((x + k) % 200, y, c)
for i in range(26):
    x = r.randrange(200); y = r.randrange(256)
    cv.px(x, y, (150, 180, 220)); cv.px((x + 1) % 200, y, (90, 120, 170))
cv.save("bg_lake")
# 雾
cv = Cv(96, 24)
for i in range(7):
    cv.ell(r.randrange(14, 82), r.randrange(8, 16), r.randrange(12, 30), r.randrange(4, 8), (200, 215, 240, 26))
cv.save("mist")

# 应用图标
ic = Cv(192, 192)
grad(ic, (40, 24, 90), (130, 50, 110))
ic.ell(96, 96, 78, 78, (250, 240, 215)); ic.ell(96, 96, 70, 70, (60, 36, 100))
ic.paste(CHARS["reimu"], 96 - 11 * 5, 96 - 14 * 5 + 4, 5)
ic.im.save(os.path.join(ROOT, "assets", "icon.png"))

# 预览图（开发用）
names = ["reimu", "fairy_0", "fairy_1", "fairy_red_0", "bigfairy_0", "kedama_0", "rumia", "daiyousei_0", "cirno_0", "cirno_1", "nitori", "rinnosuke", "sunny", "luna", "starf"]
sheet = Image.new("RGBA", (len(names) * 26 * 3, 34 * 3), (50, 46, 80, 255))
for i, n in enumerate(names):
    im = Image.open(os.path.join(OUT, n + ".png"))
    sheet.alpha_composite(im.resize((im.width * 3, im.height * 3), Image.NEAREST), (i * 78 + 4, 6))
sheet.save("/tmp/art_chars.png")
sc = Image.new("RGBA", (SW * 2 + 6, SH * 4 + 12 + 150), (20, 20, 30, 255))
for i, n in enumerate(["ev_shrine", "ev_kappa", "ev_fairies", "ev_tea", "ev_kedama", "ev_kourin", "ev_rest"]):
    sc.alpha_composite(Image.open(os.path.join(OUT, n + ".png")), ((i % 2) * (SW + 6), (i // 2) * (SH + 4)))
sc.alpha_composite(Image.open(os.path.join(OUT, "title_art.png")), (SW + 6 - 16, 3 * (SH + 4)))
sc.alpha_composite(Image.open(os.path.join(ROOT, "assets", "icon.png")).resize((96, 96), Image.NEAREST), (10, 4 * (SH + 4) + 20))
sc.alpha_composite(Image.open(os.path.join(OUT, "bullets.png")).resize((224, 96), Image.NEAREST), (120, 3 * (SH + 4) + 70 + 80)) if False else None
sc.save("/tmp/art_scenes.png")
print("ok")
