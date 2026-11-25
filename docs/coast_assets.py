from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "graphics" / "coast"
OUT.mkdir(parents=True, exist_ok=True)

TILE = 16
TILE_COLS = 8


def sheet(name: str, painter) -> None:
    image = Image.new("RGBA", (TILE * TILE_COLS, TILE), (0, 0, 0, 0))
    for i in range(TILE_COLS):
        tile = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
        painter(tile, random.Random(1000 + i * 97 + len(name)))
        image.alpha_composite(tile, (i * TILE, 0))
    image.save(OUT / name)


def sand(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(38, 33, 29, 255))
    for _ in range(26):
        x, y = rng.randrange(16), rng.randrange(16)
        color = rng.choice([(51, 44, 37), (30, 26, 23), (63, 53, 43), (45, 39, 33)])
        d.point((x, y), fill=color + (255,))
    for _ in range(3):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=(125, 52, 25, 255))
    if rng.random() < 0.45:
        x, y = rng.randrange(15), rng.randrange(15)
        d.line((x, y, x + 2, y + 1), fill=(72, 60, 47, 255))


def basalt(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(40, 40, 47, 255))
    for _ in range(10):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(52, 52, 60), (34, 34, 40), (60, 60, 68)]) + (255,))
    for _ in range(2):
        x, y = rng.randrange(13), rng.randrange(13)
        d.line((x, y, x + rng.randrange(2, 5), y + rng.randrange(1, 4)), fill=(20, 20, 25, 255))
    if rng.random() < 0.35:
        d.line((0, rng.randrange(16), 15, rng.randrange(16)), fill=(27, 27, 32, 255))


def lava(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(120, 36, 14, 255))
    for _ in range(5):
        x, y = rng.randrange(16), rng.randrange(16)
        r = rng.randrange(2, 6)
        d.ellipse((x - r, y - r, x + r, y + r), fill=rng.choice([(220, 72, 18), (250, 118, 32), (255, 164, 58)]) + (255,))
    for _ in range(8):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=(255, 214, 120, 255))
    for _ in range(4):
        x, y = rng.randrange(16), rng.randrange(16)
        d.rectangle((x, y, x + 2, y + 1), fill=(54, 24, 15, 255))


def sea(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(14, 32, 40, 255))
    for _ in range(3):
        y = rng.randrange(3, 15)
        d.line((0, y, 15, y + rng.choice([-1, 0, 1])), fill=(27, 58, 68, 255))
    for _ in range(4):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=(126, 158, 158, 255))
    if rng.random() < 0.4:
        x = rng.randrange(16)
        d.line((x, 0, x + 1, 15), fill=(9, 20, 26, 255))


def wood(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(53, 38, 27, 255))
    for y in (3, 7, 11, 15):
        d.line((0, y, 15, y), fill=(29, 20, 14, 255))
    for _ in range(12):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(72, 52, 35), (42, 30, 21), (88, 64, 42)]) + (255,))
    if rng.random() < 0.4:
        x, y = rng.randrange(13), rng.randrange(13)
        d.ellipse((x, y, x + 3, y + 2), outline=(32, 22, 15, 255))


def bone_floor(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(39, 35, 30, 255))
    for _ in range(8):
        x, y = rng.randrange(15), rng.randrange(15)
        if rng.random() < 0.5:
            d.line((x, y, x + 3, y + 1), fill=(92, 84, 68, 255))
        else:
            d.point((x, y), fill=(151, 140, 116, 255))
    for _ in range(3):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=(26, 23, 19, 255))


# ---- 地形 ----
sheet("sand.png", sand)
sheet("basalt.png", basalt)
sheet("lava.png", lava)
sheet("sea.png", sea)
sheet("wood.png", wood)
sheet("bone_floor.png", bone_floor)


def save_prop(name: str, size: tuple[int, int], painter) -> None:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    painter(image, ImageDraw.Draw(image))
    image.save(OUT / name)


def p_shipwreck(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    # 断裂的船体，内部会单独铺地板
    d.polygon([(8, 62), (10, 30), (26, 20), (132, 20), (150, 44), (144, 76), (116, 90), (40, 88), (22, 76)],
              fill=(43, 31, 22, 255))
    d.polygon([(16, 62), (22, 32), (40, 26), (124, 26), (138, 46), (132, 68), (108, 78), (44, 76)],
              fill=(64, 45, 30, 255))
    for x in range(20, 140, 12):
        d.line((x, 24, x + 2, 82), fill=(34, 24, 17, 255), width=2)
    # 破洞与肋骨
    d.polygon([(60, 34), (88, 28), (98, 50), (70, 62)], fill=(20, 22, 25, 255))
    for x in (44, 118):
        d.line((x, 18, x + 4, 88), fill=(82, 60, 40, 255), width=3)
        d.line((x + 8, 20, x + 6, 84), fill=(28, 20, 14, 255), width=2)
    # 桅杆残段
    d.rectangle((76, 0, 82, 28), fill=(48, 34, 23, 255))
    d.line((78, 4, 78, 26), fill=(87, 64, 42, 255))
    # 海藻和余烬
    for (x, y, c) in [(28, 84, (42, 72, 48)), (54, 82, (32, 58, 42)), (126, 84, (44, 76, 50))]:
        d.line((x, y, x + 8, y - 6), fill=c + (255,), width=2)
    for (x, y) in [(36, 54), (102, 40), (90, 72)]:
        d.ellipse((x, y, x + 2, y + 2), fill=(220, 90, 30, 255))


def p_lighthouse(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    # 塔身
    d.polygon([(23, 156), (27, 38), (37, 38), (41, 156)], fill=(55, 54, 60, 255))
    d.polygon([(27, 156), (30, 42), (34, 42), (37, 156)], fill=(73, 72, 80, 255))
    for y in (56, 82, 108, 134):
        d.line((27, y, 38, y), fill=(43, 42, 48, 255), width=2)
    # 灯室
    d.rectangle((18, 24, 46, 40), fill=(37, 37, 43, 255))
    d.rectangle((22, 28, 42, 37), fill=(255, 176, 72, 255))
    d.rectangle((24, 30, 40, 34), fill=(255, 226, 150, 255))
    d.polygon([(14, 24), (32, 8), (50, 24)], fill=(49, 43, 40, 255))
    d.line((32, 8, 32, 2), fill=(37, 32, 29, 255), width=2)
    # 门与窗
    d.rectangle((28, 138, 36, 156), fill=(31, 24, 19, 255))
    for y in (70, 98, 122):
        d.rectangle((30, y, 35, y + 8), fill=(28, 30, 34, 255))
        d.point((32, y + 2), fill=(255, 180, 84, 255))
    # 底部岩石
    d.ellipse((10, 148, 54, 164), fill=(42, 42, 48, 255))
    d.ellipse((16, 152, 48, 164), fill=(54, 53, 60, 255))


def p_coast_gate(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((5, 8, 43, 62), fill=(28, 24, 25, 255))
    d.ellipse((10, 14, 38, 58), fill=(47, 36, 31, 255))
    d.ellipse((14, 18, 34, 54), fill=(255, 112, 36, 255))
    d.ellipse((18, 22, 30, 50), fill=(255, 190, 88, 255))
    for (x, y) in [(12, 20), (38, 26), (10, 44), (40, 48)]:
        d.rectangle((x - 1, y - 1, x + 2, y + 2), fill=(64, 46, 36, 255))
    d.arc((5, 8, 43, 62), 0, 360, fill=(94, 67, 48, 255), width=2)


def p_tide_gate(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((2, 8, 46, 62), fill=(39, 38, 44, 255))
    d.rectangle((7, 14, 41, 62), fill=(24, 23, 28, 255))
    for x in (13, 23, 33):
        d.rectangle((x, 14, x + 4, 62), fill=(62, 61, 70, 255))
        d.line((x + 1, 18, x + 1, 58), fill=(84, 82, 92, 255))
    d.line((7, 30, 41, 30), fill=(72, 70, 80, 255), width=2)
    d.ellipse((20, 30, 28, 38), fill=(255, 116, 32, 255))
    d.ellipse((22, 32, 26, 36), fill=(255, 210, 120, 255))


def p_dragonbone(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((8, 40, 88, 92), outline=(173, 161, 136, 255), width=7)
    d.ellipse((18, 48, 78, 84), outline=(118, 108, 90, 255), width=3)
    for x in (24, 40, 56, 72):
        d.line((x, 44, x + 2, 88), fill=(151, 140, 118, 255), width=4)
        d.point((x + 1, 46), fill=(210, 198, 170, 255))
    d.rectangle((44, 20, 52, 46), fill=(161, 150, 126, 255))
    d.rectangle((42, 18, 54, 23), fill=(193, 181, 154, 255))


def p_bone_pile(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    for (x1, y1, x2, y2) in [(3, 18, 28, 8), (6, 22, 30, 15), (2, 12, 18, 21)]:
        d.line((x1, y1, x2, y2), fill=(172, 161, 137, 255), width=3)
        d.ellipse((x1 - 2, y1 - 2, x1 + 3, y1 + 3), fill=(195, 184, 158, 255))
        d.ellipse((x2 - 2, y2 - 2, x2 + 3, y2 + 3), fill=(195, 184, 158, 255))
    d.ellipse((12, 5, 20, 13), fill=(196, 185, 158, 255))
    d.point((14, 7), fill=(52, 46, 37, 255))
    d.point((18, 7), fill=(52, 46, 37, 255))


def p_driftwood(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(2, 12), (8, 6), (36, 9), (38, 13), (10, 15)], fill=(59, 46, 34, 255))
    d.line((7, 11, 34, 11), fill=(87, 68, 48, 255))
    d.line((12, 8, 14, 15), fill=(37, 28, 20, 255))
    d.line((28, 8, 30, 14), fill=(37, 28, 20, 255))
    for (x, y) in [(16, 13), (24, 10)]:
        d.point((x, y), fill=(224, 104, 38, 255))


def p_lava_vent(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((2, 8, 30, 24), fill=(34, 27, 25, 255))
    d.ellipse((7, 11, 25, 21), fill=(77, 31, 19, 255))
    d.ellipse((11, 13, 21, 19), fill=(235, 78, 20, 255))
    d.ellipse((14, 14, 18, 17), fill=(255, 190, 80, 255))
    for (x, y) in [(6, 10), (25, 12), (20, 22)]:
        d.point((x, y), fill=(255, 142, 48, 255))
    d.line((4, 9, 8, 4), fill=(24, 20, 18, 255))
    d.line((26, 10, 30, 5), fill=(24, 20, 18, 255))


def p_lens(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((1, 1, 14, 14), fill=(35, 58, 66, 255))
    d.ellipse((3, 3, 12, 12), fill=(109, 214, 226, 255))
    d.ellipse((5, 5, 10, 10), fill=(224, 252, 250, 255))
    d.line((8, 0, 8, 2), fill=(123, 196, 208, 255))
    d.line((8, 13, 8, 15), fill=(123, 196, 208, 255))


def p_altar(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((4, 12, 28, 22), fill=(58, 51, 43, 255))
    d.rectangle((8, 8, 24, 14), fill=(91, 81, 67, 255))
    d.rectangle((10, 5, 22, 9), fill=(132, 120, 98, 255))
    d.ellipse((12, 1, 20, 9), fill=(255, 142, 40, 255))
    d.ellipse((14, 2, 18, 7), fill=(255, 226, 142, 255))
    d.point((15, 14), fill=(255, 112, 36, 255))


def p_chest(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((2, 8, 22, 19), fill=(63, 43, 28, 255))
    d.polygon([(2, 8), (5, 4), (20, 4), (22, 8)], fill=(83, 58, 37, 255))
    d.rectangle((2, 10, 22, 12), fill=(42, 34, 25, 255))
    d.rectangle((10, 8, 14, 19), fill=(108, 88, 52, 255))
    d.rectangle((11, 13, 13, 16), fill=(226, 186, 92, 255))


def p_sea_rock(image: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(2, 22), (7, 8), (16, 4), (28, 10), (30, 22)], fill=(41, 41, 47, 255))
    d.polygon([(7, 22), (11, 11), (19, 8), (25, 14), (26, 22)], fill=(57, 56, 63, 255))
    d.line((12, 18, 20, 14), fill=(30, 30, 35, 255))
    d.line((8, 22, 28, 22), fill=(24, 25, 29, 255))


save_prop("shipwreck.png", (160, 96), p_shipwreck)
save_prop("lighthouse.png", (64, 160), p_lighthouse)
save_prop("coast_gate.png", (48, 64), p_coast_gate)
save_prop("tide_gate.png", (48, 64), p_tide_gate)
save_prop("dragonbone.png", (96, 96), p_dragonbone)
save_prop("bone_pile.png", (32, 24), p_bone_pile)
save_prop("driftwood.png", (40, 16), p_driftwood)
save_prop("lava_vent.png", (32, 24), p_lava_vent)
save_prop("wreck_lens.png", (16, 16), p_lens)
save_prop("altar.png", (32, 24), p_altar)
save_prop("chest.png", (24, 20), p_chest)
save_prop("sea_rock.png", (32, 24), p_sea_rock)


# 预览图
PREVIEW = OUT / "preview_coast_assets.png"
files = [
    "sand.png", "basalt.png", "lava.png", "sea.png", "wood.png", "bone_floor.png",
    "shipwreck.png", "lighthouse.png", "coast_gate.png", "tide_gate.png",
    "dragonbone.png", "bone_pile.png", "driftwood.png", "lava_vent.png",
    "wreck_lens.png", "altar.png", "chest.png", "sea_rock.png",
]
cell = 190
preview = Image.new("RGBA", (cell * 4, cell * 5), (24, 26, 30, 255))
pd = ImageDraw.Draw(preview)
for i, name in enumerate(files):
    im = Image.open(OUT / name).convert("RGBA")
    if name.endswith(("sand.png", "basalt.png", "lava.png", "sea.png", "wood.png", "bone_floor.png")):
        im = im.crop((0, 0, 64, 16)).resize((160, 40), Image.NEAREST)
    else:
        im.thumbnail((cell - 24, cell - 30), Image.LANCZOS)
    x = (i % 4) * cell
    y = (i // 4) * cell
    for yy in range(0, cell, 20):
        for xx in range(0, cell, 20):
            if (xx // 20 + yy // 20) % 2 == 0:
                pd.rectangle((x + xx, y + yy, x + xx + 19, y + yy + 19), fill=(40, 42, 47, 255))
    preview.alpha_composite(im, (x + (cell - im.width) // 2, y + (cell - im.height) // 2))
    pd.text((x + 8, y + cell - 20), name.replace(".png", ""), fill=(238, 232, 216, 255))
preview.convert("RGB").save(PREVIEW)
print("coast assets written to", OUT)
