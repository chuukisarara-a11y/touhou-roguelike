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
