from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "graphics" / "coast"
FRONT = ROOT / "front_view_chibi"
OUT.mkdir(parents=True, exist_ok=True)

TILE = 16


def sheet(name: str, painter) -> None:
    image = Image.new("RGBA", (TILE * 8, TILE), (0, 0, 0, 0))
    for i in range(8):
        tile = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
        painter(tile, random.Random(7700 + i * 131 + len(name)))
        image.alpha_composite(tile, (i * TILE, 0))
    image.save(OUT / name)


def ash(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(52, 51, 55, 255))
    for _ in range(24):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(68, 66, 70), (42, 41, 45), (82, 80, 84)]) + (255,))
    if rng.random() < 0.4:
        x, y = rng.randrange(15), rng.randrange(15)
        d.line((x, y, x + 2, y + 1), fill=(33, 32, 36, 255))


def wet_sand(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(39, 42, 42, 255))
    for _ in range(18):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(51, 55, 54), (31, 34, 35), (64, 67, 65)]) + (255,))
    if rng.random() < 0.55:
        y = rng.randrange(16)
        d.line((0, y, 15, y + rng.choice([-1, 0, 1])), fill=(26, 31, 33, 255))
    if rng.random() < 0.3:
        d.point((rng.randrange(16), rng.randrange(16)), fill=(154, 170, 166, 255))


def charred(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(32, 27, 24, 255))
    for _ in range(10):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(43, 36, 31), (24, 20, 18)]) + (255,))
    if rng.random() < 0.7:
        x, y = rng.randrange(10, 15), rng.randrange(3, 12)
        d.line((x, y, x - rng.randrange(4, 9), y + rng.randrange(-3, 4)), fill=(183, 61, 22, 255))
        d.line((x - 2, y + 1, x - 5, y + 2), fill=(255, 139, 42, 255))


def seaweed_ground(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(35, 48, 37, 255))
    for _ in range(12):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(48, 68, 50), (27, 38, 30), (62, 78, 52)]) + (255,))
    if rng.random() < 0.6:
        x, y = rng.randrange(16), rng.randrange(16)
        d.line((x, y, x + rng.randrange(-3, 4), y - rng.randrange(2, 5)), fill=(31, 63, 44, 255))


def stone_path(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(79, 73, 63, 255))
    for _ in range(10):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(96, 89, 76), (64, 59, 52)]) + (255,))
    if rng.random() < 0.5:
        x, y = rng.randrange(14), rng.randrange(14)
        d.line((x, y, x + rng.randrange(2, 5), y + rng.randrange(1, 4)), fill=(53, 49, 43, 255))


sheet("ash.png", ash)
sheet("wet_sand.png", wet_sand)
sheet("charred.png", charred)
sheet("seaweed_ground.png", seaweed_ground)
sheet("stone_path.png", stone_path)


def save_prop(name: str, size: tuple[int, int], painter) -> None:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    painter(image, ImageDraw.Draw(image))
    image.save(OUT / name)


def p_shipwreck_main(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    # 大型搁浅帆船：左高艉楼、右尖艏、破口肋骨、断桅
    d.polygon([(6, 88), (22, 58), (54, 46), (250, 46), (296, 72), (314, 100), (296, 150), (252, 166), (62, 166), (24, 150), (10, 118)],
              fill=(35, 25, 18, 255))
    d.polygon([(18, 92), (32, 66), (60, 56), (244, 56), (286, 80), (300, 102), (284, 142), (246, 154), (68, 154), (34, 140), (22, 116)],
              fill=(66, 47, 31, 255))
    # 船板
    for y in range(64, 154, 10):
        d.line((30, y, 290, y - 2), fill=(43, 31, 21, 255), width=1)
    # 艉楼窗
    for x in (44, 64, 84):
        d.rectangle((x, 72, x + 8, 84), fill=(26, 20, 16, 255))
        d.rectangle((x + 2, 75, x + 6, 81), fill=(186, 116, 48, 255))
    # 中段破口和肋骨
    d.polygon([(122, 60), (210, 58), (224, 94), (210, 148), (126, 150), (110, 112), (108, 82)], fill=(20, 22, 24, 255))
    for x in (126, 146, 166, 186, 206):
        d.line((x, 62, x + 2, 150), fill=(101, 75, 49, 255), width=3)
        d.line((x + 5, 64, x + 4, 148), fill=(43, 31, 21, 255), width=1)
    d.line((122, 96, 214, 94), fill=(57, 41, 29, 255), width=3)
    # 艏部
    d.polygon([(286, 80), (312, 92), (304, 104), (286, 100)], fill=(52, 37, 25, 255))
    d.line((300, 88, 320, 58), fill=(52, 37, 25, 255), width=4)
    d.line((300, 88, 320, 58), fill=(92, 68, 44, 255), width=1)
    # 破洞里的微光
    d.ellipse((166, 118, 186, 134), fill=(28, 60, 67, 255))
    d.ellipse((170, 121, 182, 131), fill=(119, 206, 214, 255))
    d.ellipse((174, 124, 178, 128), fill=(236, 250, 246, 255))
    # 海藻、锈迹和藤壶
    for (x, y) in [(40, 150), (70, 158), (240, 154), (278, 142)]:
        d.line((x, y, x + 12, y - 8), fill=(38, 70, 48, 255), width=2)
        d.line((x + 4, y, x + 10, y + 5), fill=(30, 57, 41, 255), width=1)
    for _ in range(14):
        x = 30 + (_ * 19) % 270
        y = 56 + (_ * 23) % 96
        d.point((x, y), fill=(142, 91, 46, 255))


def p_shipwreck_small(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(8, 58), (24, 34), (166, 34), (184, 58), (168, 104), (40, 104), (16, 90)],
              fill=(36, 26, 19, 255))
    d.polygon([(18, 60), (30, 42), (160, 42), (174, 60), (160, 96), (44, 96), (26, 84)],
              fill=(67, 48, 32, 255))
    for y in range(48, 96, 9):
        d.line((30, y, 162, y), fill=(43, 31, 21, 255))
    d.polygon([(68, 42), (126, 42), (134, 63), (120, 96), (74, 96), (62, 70)], fill=(20, 22, 24, 255))
    for x in (72, 90, 108, 124):
        d.line((x, 44, x + 2, 96), fill=(98, 73, 47, 255), width=2)
    d.line((30, 68, 160, 66), fill=(51, 37, 26, 255), width=2)
    for (x, y) in [(32, 92), (150, 92)]:
        d.line((x, y, x + 10, y - 6), fill=(38, 70, 48, 255), width=2)
    d.rectangle((18, 20, 24, 44), fill=(45, 33, 23, 255))
    d.line((20, 22, 20, 42), fill=(87, 65, 44, 255))


def p_ship_rib(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.arc((2, 4, 22, 54), 190, 350, fill=(91, 67, 44, 255), width=4)
    d.arc((4, 7, 19, 50), 190, 350, fill=(48, 35, 24, 255), width=2)
    d.line((4, 50, 20, 50), fill=(55, 40, 28, 255), width=3)


def p_broken_mast(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(8, 136), (11, 10), (16, 10), (19, 136)], fill=(55, 39, 26, 255))
    d.line((13, 14, 13, 132), fill=(101, 76, 50, 255), width=2)
    d.line((2, 34, 24, 30), fill=(72, 52, 35, 255), width=3)
    d.line((2, 34, 24, 30), fill=(109, 82, 54, 255), width=1)
    d.line((4, 122, 22, 118), fill=(48, 34, 23, 255), width=2)


def p_torn_sail(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(8, 4), (72, 10), (66, 38), (58, 52), (62, 72), (44, 64), (34, 88), (24, 66), (10, 74), (16, 46), (4, 36)],
              fill=(128, 119, 98, 235))
    for x in range(12, 70, 10):
        d.line((x, 8, x - 2, 70), fill=(96, 88, 72, 210))
    d.polygon([(18, 36), (46, 42), (38, 58), (22, 52)], fill=(78, 72, 61, 220))


def p_pier(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((0, 14, 160, 24), fill=(64, 46, 30, 255))
    for x in range(0, 160, 16):
        d.line((x, 14, x, 24), fill=(41, 29, 19, 255))
    for x in (10, 46, 82, 118, 154):
        d.rectangle((x, 24, x + 4, 48), fill=(50, 36, 24, 255))
    d.polygon([(118, 14), (144, 14), (150, 8), (124, 8)], fill=(70, 51, 34, 255))
    for (x, y) in [(20, 18), (88, 20), (132, 16)]:
        d.point((x, y), fill=(190, 130, 62, 255))


def p_rowboat(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(3, 12), (12, 6), (52, 7), (61, 14), (50, 27), (14, 27), (5, 20)], fill=(56, 41, 27, 255))
    d.polygon([(8, 13), (16, 9), (48, 10), (56, 16), (46, 23), (18, 23), (10, 19)], fill=(79, 58, 38, 255))
    d.line((18, 12, 18, 21), fill=(40, 29, 19, 255))
    d.line((38, 12, 38, 21), fill=(40, 29, 19, 255))
    d.line((52, 16, 62, 5), fill=(74, 55, 36, 255), width=2)


def p_tent(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(4, 52), (36, 8), (68, 52)], fill=(82, 66, 49, 255))
    d.polygon([(10, 52), (36, 14), (36, 52)], fill=(112, 92, 68, 255))
    d.polygon([(36, 52), (36, 14), (62, 52)], fill=(92, 76, 56, 255))
    d.line((36, 8, 36, 56), fill=(52, 40, 28, 255), width=2)
    d.polygon([(26, 52), (36, 32), (46, 52)], fill=(37, 30, 23, 255))
    for y in (26, 38, 48):
        d.line((8, y, 26, y + 4), fill=(63, 49, 36, 255))
        d.line((46, y + 4, 64, y), fill=(63, 49, 36, 255))


def p_campfire(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((2, 16, 22, 24), fill=(38, 31, 25, 255))
    for (x1, y1, x2, y2) in [(5, 18, 19, 20), (8, 20, 16, 16)]:
        d.line((x1, y1, x2, y2), fill=(82, 55, 34, 255), width=3)
    d.polygon([(7, 18), (12, 6), (16, 13), (19, 7), (19, 19), (12, 21)], fill=(231, 78, 24, 255))
    d.polygon([(10, 18), (13, 10), (16, 18)], fill=(255, 206, 100, 255))


def p_signpost(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((14, 8, 20, 48), fill=(58, 42, 28, 255))
    d.line((16, 10, 16, 46), fill=(91, 67, 44, 255))
    d.polygon([(2, 12), (30, 12), (30, 20), (2, 20), (0, 16)], fill=(72, 53, 35, 255))
    d.polygon([(10, 25), (30, 25), (30, 33), (10, 33), (7, 29)], fill=(72, 53, 35, 255))
    d.line((6, 16, 24, 16), fill=(135, 104, 66, 255))
    d.line((13, 29, 25, 29), fill=(135, 104, 66, 255))


def p_cargo(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((2, 12, 22, 30), fill=(72, 53, 35, 255))
    d.rectangle((26, 8, 46, 30), fill=(64, 47, 31, 255))
    d.rectangle((2, 12, 22, 15), fill=(45, 33, 22, 255))
    d.rectangle((26, 8, 46, 11), fill=(45, 33, 22, 255))
    d.line((8, 12, 8, 30), fill=(38, 27, 18, 255))
    d.line((16, 12, 16, 30), fill=(38, 27, 18, 255))
    d.line((32, 8, 32, 30), fill=(38, 27, 18, 255))
    d.line((40, 8, 40, 30), fill=(38, 27, 18, 255))
    d.ellipse((5, 17, 19, 27), outline=(155, 116, 61, 255), width=1)


def p_barrel(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((2, 4, 14, 18), fill=(66, 47, 31, 255))
    d.ellipse((2, 2, 14, 7), fill=(83, 60, 39, 255))
    d.line((2, 7, 14, 7), fill=(37, 26, 17, 255), width=2)
    d.line((2, 13, 14, 13), fill=(37, 26, 17, 255), width=2)
    d.line((7, 6, 7, 17), fill=(91, 68, 45, 255))


def p_crate(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((2, 4, 18, 18), fill=(68, 50, 33, 255))
    d.line((2, 4, 18, 18), fill=(39, 28, 19, 255), width=2)
    d.line((18, 4, 2, 18), fill=(39, 28, 19, 255), width=2)
    d.rectangle((2, 4, 18, 18), outline=(97, 72, 48, 255))


def p_planks(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(1, 8), (20, 3), (47, 6), (45, 12), (17, 15), (2, 13)], fill=(64, 47, 31, 255))
    for x in (10, 24, 38):
        d.line((x, 5, x + 2, 13), fill=(38, 27, 18, 255))
    d.line((7, 9, 34, 7), fill=(93, 69, 46, 255))


def p_seaweed(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    for (x, h, c) in [(6, 18, (39, 78, 50)), (12, 23, (32, 66, 45)), (19, 16, (46, 88, 55)), (25, 21, (35, 70, 46))]:
        d.line((x, 23, x + 2, 23 - h), fill=c + (255,), width=2)
        d.line((x + 2, 23 - h + 4, x + 6, 23 - h + 1), fill=c + (255,), width=1)


def p_tide_pool(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((2, 5, 46, 23), fill=(27, 50, 56, 255))
    d.ellipse((5, 7, 43, 21), fill=(42, 78, 83, 255))
    d.arc((8, 9, 30, 19), 190, 330, fill=(135, 169, 166, 255), width=1)
    d.point((36, 12), fill=(189, 206, 200, 255))
    d.point((20, 17), fill=(72, 121, 118, 255))


def p_basalt_column(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(4, 70), (7, 10), (11, 4), (22, 4), (26, 10), (29, 70)], fill=(42, 42, 49, 255))
    d.polygon([(7, 68), (10, 12), (23, 12), (26, 68)], fill=(56, 56, 64, 255))
    for y in (24, 38, 52):
        d.line((8, y, 25, y), fill=(34, 34, 40, 255))
    d.line((13, 12, 13, 66), fill=(68, 68, 76, 255))
    d.line((20, 14, 20, 66), fill=(38, 38, 44, 255))


def p_cave_mouth(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(2, 94), (8, 36), (28, 10), (58, 2), (94, 8), (118, 30), (126, 94)], fill=(31, 31, 36, 255))
    d.polygon([(14, 94), (20, 42), (36, 20), (58, 14), (86, 20), (106, 42), (114, 94)], fill=(16, 17, 20, 255))
    d.ellipse((26, 30, 54, 48), fill=(37, 48, 44, 200))
    d.ellipse((78, 28, 102, 44), fill=(37, 48, 44, 200))
    for (x, y) in [(40, 40), (88, 36)]:
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(126, 210, 190, 255))
    for x in (12, 24, 42, 76, 96, 116):
        d.polygon([(x, 94), (x + 3, 84), (x + 7, 94)], fill=(39, 39, 45, 255))


def p_crystal(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(4, 30), (8, 4), (12, 30)], fill=(58, 128, 128, 255))
    d.polygon([(11, 30), (16, 10), (20, 30)], fill=(78, 164, 156, 255))
    d.polygon([(7, 29), (9, 9), (11, 29)], fill=(176, 235, 218, 255))
    d.line((16, 29, 18, 14), fill=(213, 249, 235, 255))
    d.ellipse((4, 26, 22, 32), fill=(39, 85, 85, 120))


def p_dragon_skull(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((24, 18, 136, 96), fill=(173, 161, 137, 255))
    d.polygon([(34, 58), (2, 40), (10, 78), (46, 82)], fill=(147, 136, 114, 255))
    d.polygon([(126, 58), (158, 40), (150, 78), (114, 82)], fill=(147, 136, 114, 255))
    d.polygon([(54, 30), (62, 2), (76, 28)], fill=(193, 181, 153, 255))
    d.polygon([(86, 28), (100, 4), (106, 32)], fill=(193, 181, 153, 255))
    d.ellipse((46, 42, 70, 60), fill=(26, 23, 20, 255))
    d.ellipse((92, 42, 116, 60), fill=(26, 23, 20, 255))
    d.ellipse((54, 48, 62, 55), fill=(255, 112, 28, 255))
    d.ellipse((100, 48, 108, 55), fill=(255, 112, 28, 255))
    d.polygon([(58, 74), (72, 90), (80, 74), (88, 90), (102, 74)], fill=(40, 34, 28, 255))
    for x in (44, 62, 82, 100, 118):
        d.line((x, 88, x + 2, 104), fill=(139, 128, 106, 255), width=3)
    d.line((70, 22, 84, 30), fill=(202, 190, 162, 255), width=2)


def p_ribcage(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.line((6, 88, 154, 88), fill=(137, 127, 106, 255), width=6)
    for x in (18, 40, 62, 84, 106, 128, 148):
        h = 54 + (x % 24)
        d.arc((x - 12, 88 - h, x + 12, 98), 190, 350, fill=(173, 161, 137, 255), width=5)
        d.arc((x - 12, 88 - h, x + 12, 98), 190, 350, fill=(204, 192, 164, 255), width=1)


def p_brazier(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.polygon([(4, 30), (8, 16), (20, 16), (24, 30)], fill=(52, 47, 42, 255))
    d.ellipse((3, 12, 25, 20), fill=(37, 33, 30, 255))
    d.polygon([(7, 14), (12, 2), (17, 10), (21, 4), (20, 15)], fill=(231, 84, 24, 255))
    d.polygon([(10, 14), (13, 7), (17, 14)], fill=(255, 213, 110, 255))


def p_lantern_post(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((7, 12, 10, 48), fill=(49, 36, 24, 255))
    d.rectangle((2, 6, 14, 16), fill=(43, 39, 34, 255))
    d.rectangle((5, 9, 11, 14), fill=(255, 176, 70, 255))
    d.rectangle((6, 10, 10, 13), fill=(255, 232, 148, 255))
    d.line((2, 4, 14, 4), fill=(64, 58, 50, 255))


def p_keeper_hut(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((10, 34, 86, 78), fill=(67, 63, 58, 255))
    d.rectangle((10, 34, 86, 40), fill=(49, 45, 42, 255))
    d.polygon([(2, 38), (48, 4), (94, 38)], fill=(43, 35, 31, 255))
    d.polygon([(8, 36), (48, 10), (88, 36)], fill=(67, 52, 41, 255))
    d.rectangle((38, 56, 58, 78), fill=(38, 28, 21, 255))
    d.rectangle((18, 48, 30, 60), fill=(30, 31, 35, 255))
    d.rectangle((20, 50, 28, 58), fill=(176, 118, 52, 255))
    d.rectangle((68, 48, 80, 60), fill=(30, 31, 35, 255))
    d.point((72, 52), fill=(255, 190, 82, 255))
    d.line((48, 4, 48, 0), fill=(37, 31, 28, 255), width=2)


def p_whale_bones(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.line((4, 40, 124, 40), fill=(151, 140, 118, 255), width=6)
    for x in (14, 34, 54, 74, 94, 114):
        d.arc((x - 16, 4, x + 16, 48), 190, 350, fill=(190, 178, 150, 255), width=5)
    d.ellipse((2, 34, 20, 48), fill=(171, 159, 134, 255))
    d.ellipse((110, 34, 128, 48), fill=(171, 159, 134, 255))
    d.point((10, 40), fill=(45, 40, 32, 255))
    d.point((118, 40), fill=(45, 40, 32, 255))


def p_gull(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.line((2, 8, 8, 4), fill=(202, 202, 194, 255), width=2)
    d.line((8, 4, 14, 8), fill=(202, 202, 194, 255), width=2)
    d.ellipse((6, 5, 11, 10), fill=(226, 225, 216, 255))
    d.point((11, 6), fill=(229, 174, 63, 255))


def p_crab(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((4, 4, 12, 10), fill=(172, 58, 32, 255))
    for (x, y) in [(2, 6), (0, 10), (14, 6), (15, 10)]:
        d.line((8, 8, x, y), fill=(123, 40, 24, 255))
    d.point((6, 6), fill=(247, 198, 110, 255))
    d.point((10, 6), fill=(247, 198, 110, 255))


def p_shells(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.arc((2, 2, 8, 8), 190, 350, fill=(213, 191, 164, 255), width=2)
    d.arc((8, 3, 14, 8), 190, 350, fill=(186, 160, 138, 255), width=2)
    d.point((5, 5), fill=(239, 220, 190, 255))



def p_door_wood(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((2, 2, 22, 42), fill=(38, 27, 19, 255))
    d.rectangle((4, 4, 20, 40), fill=(69, 48, 31, 255))
    for x in (8, 12, 16):
        d.line((x, 4, x, 40), fill=(45, 31, 21, 255))
    d.rectangle((4, 12, 20, 16), fill=(48, 44, 40, 255))
    d.rectangle((4, 28, 20, 32), fill=(48, 44, 40, 255))
    d.rectangle((15, 21, 18, 25), fill=(214, 174, 84, 255))
    d.line((4, 4, 20, 4), fill=(100, 72, 46, 255))
    d.line((4, 40, 20, 40), fill=(30, 21, 15, 255))



def p_gate_bars(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rectangle((2, 2, 46, 46), fill=(35, 32, 29, 255))
    d.rectangle((5, 5, 43, 43), fill=(21, 24, 27, 255))
    for x in (10, 18, 26, 34, 42):
        d.rectangle((x, 5, x + 4, 43), fill=(62, 61, 66, 255))
        d.line((x + 1, 7, x + 1, 41), fill=(95, 92, 96, 255))
    d.rectangle((5, 15, 43, 19), fill=(57, 56, 62, 255))
    d.rectangle((5, 31, 43, 35), fill=(57, 56, 62, 255))
    d.rectangle((22, 22, 26, 28), fill=(199, 156, 72, 255))
    d.point((24, 25), fill=(255, 228, 140, 255))
    for x in (12, 20, 28, 36, 44):
        d.point((x, 43), fill=(108, 104, 98, 255))


def p_tide_key(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((2, 4, 14, 16), outline=(218, 174, 74, 255), width=3)
    d.ellipse((4, 6, 10, 12), outline=(255, 226, 132, 255), width=1)
    d.rectangle((12, 8, 22, 11), fill=(218, 174, 74, 255))
    d.rectangle((20, 11, 23, 16), fill=(218, 174, 74, 255))
    d.rectangle((16, 11, 19, 14), fill=(218, 174, 74, 255))
    d.point((13, 9), fill=(255, 240, 170, 255))


def p_lighthouse_short(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.ellipse((2, 92, 94, 110), fill=(43, 43, 49, 255))
    d.ellipse((8, 96, 88, 110), fill=(56, 55, 62, 255))
    d.polygon([(26, 98), (31, 34), (65, 34), (70, 98)], fill=(53, 52, 59, 255))
    d.polygon([(33, 98), (37, 38), (59, 38), (63, 98)], fill=(76, 75, 83, 255))
    for y in (52, 74, 88):
        d.rectangle((31, y, 65, y + 5), fill=(132, 118, 95, 255))
        d.line((31, y + 5, 65, y + 5), fill=(57, 51, 44, 255))
    d.rectangle((22, 18, 74, 36), fill=(38, 38, 44, 255))
    d.rectangle((28, 22, 68, 33), fill=(255, 168, 62, 255))
    d.rectangle((32, 24, 64, 30), fill=(255, 224, 138, 255))
    for x in (30, 42, 54, 66):
        d.line((x, 18, x, 36), fill=(58, 57, 66, 255))
    d.polygon([(16, 18), (48, 2), (80, 18)], fill=(67, 40, 33, 255))
    d.line((48, 2, 48, 0), fill=(37, 31, 27, 255), width=2)
    d.rectangle((42, 78, 54, 98), fill=(32, 25, 20, 255))
    d.rectangle((44, 82, 52, 86), fill=(150, 92, 40, 255))
    d.rectangle((39, 60, 47, 68), fill=(31, 31, 36, 255))
    d.point((43, 63), fill=(255, 186, 78, 255))
    d.rectangle((50, 60, 58, 68), fill=(31, 31, 36, 255))
    d.point((54, 63), fill=(255, 186, 78, 255))
    for (x, y) in [(18, 100), (78, 100), (14, 104), (82, 104)]:
        d.ellipse((x - 4, y - 3, x + 4, y + 3), fill=(50, 49, 56, 255))


def p_anchor(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.line((12, 2, 12, 21), fill=(67, 65, 62, 255), width=3)
    d.arc((2, 8, 22, 22), 0, 180, fill=(67, 65, 62, 255), width=3)
    d.line((6, 10, 18, 10), fill=(82, 80, 75, 255), width=2)
    d.ellipse((8, 0, 16, 6), outline=(82, 80, 75, 255), width=2)


def p_pilgrim(im: Image.Image, d: ImageDraw.ImageDraw) -> None:
    # 占位，下面会用 frontview 原图覆盖
    pass


save_prop("shipwreck_main.png", (320, 176), p_shipwreck_main)
save_prop("shipwreck_small.png", (192, 128), p_shipwreck_small)
save_prop("ship_rib.png", (24, 56), p_ship_rib)
save_prop("broken_mast.png", (24, 140), p_broken_mast)
save_prop("torn_sail.png", (80, 100), p_torn_sail)
save_prop("pier.png", (160, 48), p_pier)
save_prop("rowboat.png", (64, 32), p_rowboat)
save_prop("tent.png", (72, 56), p_tent)
save_prop("campfire.png", (24, 24), p_campfire)
save_prop("signpost.png", (32, 48), p_signpost)
save_prop("cargo.png", (48, 32), p_cargo)
save_prop("barrel.png", (16, 20), p_barrel)
save_prop("crate.png", (20, 18), p_crate)
save_prop("planks.png", (48, 16), p_planks)
save_prop("seaweed.png", (32, 24), p_seaweed)
save_prop("tide_pool.png", (48, 24), p_tide_pool)
save_prop("basalt_column.png", (32, 72), p_basalt_column)
save_prop("cave_mouth.png", (128, 96), p_cave_mouth)
save_prop("crystal.png", (24, 32), p_crystal)
save_prop("dragon_skull.png", (160, 112), p_dragon_skull)
save_prop("ribcage.png", (160, 96), p_ribcage)
save_prop("brazier.png", (24, 32), p_brazier)
save_prop("lantern_post.png", (16, 48), p_lantern_post)
save_prop("keeper_hut.png", (96, 80), p_keeper_hut)
save_prop("lighthouse_short.png", (96, 112), p_lighthouse_short)
save_prop("door_wood.png", (24, 44), p_door_wood)
save_prop("gate_bars.png", (48, 48), p_gate_bars)
save_prop("tide_key.png", (24, 18), p_tide_key)
save_prop("whale_bones.png", (128, 48), p_whale_bones)
save_prop("gull.png", (16, 12), p_gull)
save_prop("crab.png", (16, 12), p_crab)
save_prop("shells.png", (16, 8), p_shells)
save_prop("anchor.png", (24, 24), p_anchor)

# 朝圣者：直接取 front_view 原图
pilgrim = Image.open(FRONT / "lost_pilgrim.png").convert("RGBA")
bbox = pilgrim.getbbox()
if bbox:
    pilgrim = pilgrim.crop(bbox)
pilgrim.thumbnail((60, 60), Image.LANCZOS)
canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
canvas.alpha_composite(pilgrim, ((64 - pilgrim.width) // 2, 64 - pilgrim.height - 2))
canvas.save(OUT / "pilgrim.png")



def cliff_wall(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(44, 43, 50, 255))
    d.rectangle((0, 0, 15, 3), fill=(68, 66, 74, 255))
    d.rectangle((0, 14, 15, 15), fill=(22, 21, 26, 255))
    for x in range(0, 16, 4):
        d.line((x, 4, x + rng.randrange(-1, 2), 13), fill=(31, 30, 36, 255))
    for _ in range(3):
        x, y = rng.randrange(16), rng.randrange(5, 14)
        d.point((x, y), fill=(78, 75, 82, 255))


def ship_wall(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(45, 31, 22, 255))
    for x in (3, 7, 11, 15):
        d.line((x, 0, x, 15), fill=(26, 18, 13, 255), width=1)
    d.rectangle((0, 2, 15, 4), fill=(57, 42, 29, 255))
    d.rectangle((0, 11, 15, 13), fill=(57, 42, 29, 255))
    for _ in range(4):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(89, 63, 41), (66, 47, 31), (32, 23, 16)]) + (255,))
    d.point((rng.randrange(16), rng.randrange(16)), fill=(116, 104, 82, 255))


def stone_wall(tile: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, 15, 15), fill=(74, 69, 60, 255))
    d.line((0, 5, 15, 5), fill=(45, 41, 36, 255), width=2)
    d.line((0, 11, 15, 11), fill=(45, 41, 36, 255), width=2)
    offset = 0 if rng.random() < 0.5 else 4
    for x in (offset, offset + 8):
        d.line((x, 0, x, 5), fill=(45, 41, 36, 255))
        d.line((x + 4, 5, x + 4, 11), fill=(45, 41, 36, 255))
    for _ in range(5):
        x, y = rng.randrange(16), rng.randrange(16)
        d.point((x, y), fill=rng.choice([(97, 91, 80), (58, 54, 47)]) + (255,))


sheet("cliff_wall.png", cliff_wall)
sheet("ship_wall.png", ship_wall)
sheet("stone_wall.png", stone_wall)


# 预览新道具
files = [
    "shipwreck_main.png", "shipwreck_small.png", "ship_rib.png", "broken_mast.png", "torn_sail.png",
    "pier.png", "rowboat.png", "tent.png", "campfire.png", "signpost.png",
    "cargo.png", "barrel.png", "crate.png", "planks.png", "seaweed.png",
    "tide_pool.png", "basalt_column.png", "cave_mouth.png", "crystal.png", "dragon_skull.png",
    "ribcage.png", "brazier.png", "lantern_post.png", "keeper_hut.png", "lighthouse_short.png", "whale_bones.png",
    "gull.png", "crab.png", "shells.png", "anchor.png", "pilgrim.png", "door_wood.png", "gate_bars.png", "tide_key.png",
]
cell = 240
cols = 5
rows = math.ceil(len(files) / cols)
preview = Image.new("RGBA", (cols * cell, rows * (cell + 20)), (23, 25, 29, 255))
pd = ImageDraw.Draw(preview)
for i, name in enumerate(files):
    im = Image.open(OUT / name).convert("RGBA")
    im.thumbnail((cell - 20, cell - 26), Image.LANCZOS)
    x = (i % cols) * cell
    y = (i // cols) * (cell + 20)
    for yy in range(0, cell, 20):
        for xx in range(0, cell, 20):
            if (xx // 20 + yy // 20) % 2 == 0:
                pd.rectangle((x + xx, y + yy, x + xx + 19, y + yy + 19), fill=(38, 40, 45, 255))
    preview.alpha_composite(im, (x + (cell - im.width) // 2, y + (cell - 20 - im.height) // 2))
    pd.text((x + 8, y + cell - 18), name.replace(".png", ""), fill=(238, 232, 216, 255))
preview.convert("RGB").save(OUT / "preview_coast_details.png")
print("detail assets written")
