#!/usr/bin/env python3
"""生成占位像素图（第7步会替换为正式美术）。用法: python3 tools/gen_sprites.py"""
import os
from PIL import Image
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
PAL = {
    ".": (0, 0, 0, 0), "K": (34, 22, 44, 255), "R": (220, 52, 60, 255), "r": (150, 30, 48, 255),
    "W": (250, 248, 240, 255), "w": (200, 204, 220, 255), "S": (250, 218, 186, 255),
    "H": (74, 46, 44, 255), "Y": (250, 210, 70, 255), "B": (70, 130, 230, 255),
    "b": (40, 80, 170, 255), "c": (170, 230, 250, 255), "G": (90, 200, 110, 255),
    "P": (240, 130, 190, 255), "O": (250, 150, 50, 255), "V": (160, 100, 230, 255),
}
def make(name, rows, outline=True):
    h, w = len(rows), max(len(r) for r in rows)
    pad = 1 if outline else 0
    im = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            im.putpixel((x + pad, y + pad), PAL[ch])
    if outline:
        src = im.copy()
        for y in range(im.height):
            for x in range(im.width):
                if src.getpixel((x, y))[3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < im.width and 0 <= ny < im.height and src.getpixel((nx, ny))[3] > 0:
                            im.putpixel((x, y), PAL["K"]); break
    im.save(os.path.join(OUT, name + ".png"))

make("reimu", [
    "....RR....RR....",
    "...RRRR..RRRR...",
    "...RrRRRRRRrR...",
    "....RRHHHHRR....",
    "....HHHHHHHH....",
    "...HHHHHHHHHH...",
    "...HSHSSSSHSH...",
    "...HSKSSSSKSH...",
    "...HSSSSSSSSH...",
    "...WHSSSSSSHW...",
    "..WW.RRYYRR.WW..",
    "..WWRRRRRRRRWW..",
    "..WWRRRRRRRRWW..",
    "...S.RRRRRR.S...",
    "....RRRRRRRR....",
    "...RRRRRRRRRR...",
    "...RrRRRRRRrR...",
    "..WWWWWWWWWWWW..",
    ".....SS..SS.....",
    ".....KK..KK.....",
])
make("fairy", [
    ".....YYYYYY.....",
    "....YYYYYYYY....",
    "....YSSSSSSY....",
    ".cc.YSKSSKSY.cc.",
    "cccc.SSSSSS.cccc",
    "cccccBBBBBBccccc",
    ".cccBBBBBBBBccc.",
    "..ccBbBBBBbBcc..",
    "....BBBBBBBB....",
    "...BBBBBBBBBB...",
    "...WWWWWWWWWW...",
    ".....SS..SS.....",
])
make("amulet", ["RRRR", "RWWR", "RWWR", "RRRR", "RWWR", "RWWR", "RRRR"], outline=False)
make("needle", ["W", "W", "c", "c", "c", "c", "c", "B", "B"], outline=False)
make("orb", [
    "..RRRR..", ".RWWWWR.", "RWWWWWWR", "RWWWWWWR", "RWWWWWWR", "RWWWWWWR", ".RWWWWR.", "..RRRR..",
], outline=False)
make("hitbox", [".RRR.", "RWWWR", "RWWWR", "RWWWR", ".RRR."], outline=False)
make("heart", [".RR.RR.", "RRRRRRR", "RWRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."])
make("heart_empty", [".ww.ww.", "w..w..w", "w.....w", "w.....w", ".w...w.", "..w.w..", "...w..."], outline=False)
print("ok")

# ---------- 第4~6步追加 ----------
PAL.update({"A": (120, 190, 250, 255), "D": (60, 52, 76, 255), "g": (50, 140, 70, 255)})

def recolor(rows, mp):
    return ["".join(mp.get(ch, ch) for ch in r) for r in rows]

def scale2(rows):
    out = []
    for r in rows:
        rr = "".join(ch * 2 for ch in r)
        out += [rr, rr]
    return out

FAIRY = [
    ".....YYYYYY.....", "....YYYYYYYY....", "....YSSSSSSY....", ".cc.YSKSSKSY.cc.",
    "cccc.SSSSSS.cccc", "cccccBBBBBBccccc", ".cccBBBBBBBBccc.", "..ccBbBBBBbBcc..",
    "....BBBBBBBB....", "...BBBBBBBBBB...", "...WWWWWWWWWW...", ".....SS..SS.....",
]
make("fairy_red", recolor(FAIRY, {"B": "R", "b": "r", "Y": "O"}))
make("bigfairy", scale2(recolor(FAIRY, {"B": "Y", "b": "O", "Y": "G"})))
make("kedama", [
    "..W.W..W.W..", ".WWWWWWWWWW.", "WWWWWWWWWWWW", ".WWKWWWWKWW.", "WWWKWWWWKWWW",
    ".WWWWWWWWWW.", "WWWWWRRWWWWW", ".WWWWWWWWWW.", "..W.WW.WW.W.",
])
make("rumia", [
    ".....YYYYYY.RR..", "....YYYYYYYYRR..", "...YYYYYYYYYY...", "...YYSSSSSSYY...",
    "...YSRSSSSRSY...", "...YSSSSSSSSY...", "....YSSSSSSY....", ".....WWRRWW.....",
    "SSDDDDDRRDDDDDSS", "SSDDDDDDDDDDDDSS", "....DDDDDDDD....", "....DDDDDDDD....",
    "...DDDDDDDDDD...", "...DDDDDDDDDD...", "..DDDDDDDDDDDD..", "..WWWWWWWWWWWW..",
    ".....SS..SS.....", ".....RR..RR.....",
])
make("daiyousei", [
    "....GGGGGG.GG...", "...GGGGGGGGYGG..", "...GGGGGGGGGG.G.", "...GGSSSSSSG....",
    "...GSKSSSSKS....", "cc.GSSSSSSSS.cc.", "ccc.SSSSSSS.ccc.", "cccc.WWYWW.cccc.",
    ".cccBBBBBBBccc..", "..ccBBBBBBBcc...", "....BBBBBBB.....", "...BBBBBBBBB....",
    "...BBBBBBBBB....", "..BBBBBBBBBBB...", "..WWWWWWWWWWW...", ".....SS.SS......",
])
make("cirno", [
    ".....bb..bb.....", "....bbbbbbbb....", "....AAAAAAAA....", "...AAAAAAAAAA...",
    "...AASSSSSSAA...", "c..ASBSSSSBSA..c", "cc.ASSSSSSSSA.cc", ".cc.SSSSSSSS.cc.",
    "c.c..WWRRWW..c.c", "cc..BBBBBBBB..cc", ".c..BBBBBBBB..c.", "....BBBBBBBB....",
    "...BBBBBBBBBB...", "...BWBWBWBWBB...", "..BBBBBBBBBBBB..", "..WWWWWWWWWWWW..",
    ".....SS..SS.....",
])
make("star", ["...Y...", "...Y...", "YYYYYYY", ".YYWYY.", "..YYY..", ".YY.YY.", ".Y...Y."], outline=False)
make("knife", [".W.", "WWW", "WWW", "WwW", "WwW", "WWW", "KKK", ".b.", ".b."], outline=False)
make("bat", ["R.......R", "RR.R.R.RR", "RRRRRRRRR", ".RRrRrRR.", "..RR.RR.."], outline=False)
make("fire", ["..O..", ".OYO.", ".OYO.", "OYYYO", "OOYOO", ".ROR.", "..R.."], outline=False)
make("ice", ["..W..", ".WcW.", ".ccc.", "ccccc", ".ccB.", ".cB..", "..B.."], outline=False)
make("moon", ["..YYY..", ".YYY...", "YYY....", "YYY....", "YYY....", ".YYY...", "..YYY.."], outline=False)
make("doll", ["..YYYY..", ".YYYYYY.", ".YSSSSY.", ".YSKKSY.", "..SSSS..", ".BBWWBB.", ".BBBBBB.", "BBBBBBBB", ".WWWWWW.", "..S..S.."])
make("yinyang", ["..WWWRR..", ".WWWWRRR.", "WWWRWRRRR", "WWWWWRRRR", "WWWWRRRRR", "WWWWRRRRR", "WWWWRWRRR", ".WWWRRRR.", "..WWRRR.."])
make("coin", [".YYY.", "YYWYY", "YWYYY", "YYYYO", ".YOO."], outline=False)

# 敌弹图集：16x16 一格；行=形状(小圆/大圆/米粒)，列=颜色
COLS = [(240, 60, 70), (70, 120, 250), (70, 210, 100), (250, 210, 60), (190, 90, 240), (90, 220, 240), (230, 230, 240)]
atlas = Image.new("RGBA", (16 * len(COLS), 48), (0, 0, 0, 0))
def disk(im, cx, cy, r, col):
    for y in range(16):
        for x in range(16):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                im.putpixel((int(x), int(y)), col)
for i, c in enumerate(COLS):
    dark = tuple(int(v * 0.55) for v in c) + (255,)
    col = c + (255,)
    cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    disk(cell, 8, 8, 4.2, dark); disk(cell, 8, 8, 3.2, col); disk(cell, 8, 8, 1.8, (255, 255, 255, 255))
    atlas.paste(cell, (i * 16, 0))
    cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    disk(cell, 8, 8, 7.2, dark); disk(cell, 8, 8, 6.2, col); disk(cell, 8, 8, 4.0, (255, 255, 255, 255))
    atlas.paste(cell, (i * 16, 16))
    cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(3, 13):
        for x in range(6, 10):
            edge = y in (3, 12) or x in (6, 9)
            if (y in (3, 12)) and x in (6, 9):
                continue
            cell.putpixel((x, y), dark if edge else ((255, 255, 255, 255) if 5 <= y <= 10 and x in (7, 8) and y != 5 and y != 10 else col))
    atlas.paste(cell, (i * 16, 32))
atlas.save(os.path.join(OUT, "bullets.png"))
print("ok2")
