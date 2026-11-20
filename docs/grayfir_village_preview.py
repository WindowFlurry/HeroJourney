from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "灰杉村地图概念预览_v1.png"
OUTPUT_CLEAN = ROOT / "docs" / "灰杉村地图概念预览_v1_无标注.png"

MAP_W, MAP_H = 640, 300
SCALE = 3
FOOTER = 60


def load(path: str) -> Image.Image:
    return Image.open(ROOT / path).convert("RGBA")


def full_mask() -> Image.Image:
    return Image.new("L", (MAP_W, MAP_H), 0)


def rect_mask(box: tuple[int, int, int, int], radius: int = 0) -> Image.Image:
    mask = full_mask()
    draw = ImageDraw.Draw(mask)
    if radius:
        draw.rounded_rectangle(box, radius=radius, fill=255)
    else:
        draw.rectangle(box, fill=255)
    return mask


def ellipse_mask(box: tuple[int, int, int, int]) -> Image.Image:
    mask = full_mask()
    ImageDraw.Draw(mask).ellipse(box, fill=255)
    return mask


def polygon_mask(points: list[tuple[int, int]]) -> Image.Image:
    mask = full_mask()
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def union(*masks: Image.Image) -> Image.Image:
    result = masks[0].copy()
    for mask in masks[1:]:
        result = ImageChops.lighter(result, mask)
    return result


def expand(mask: Image.Image, radius: int) -> Image.Image:
    return mask.filter(ImageFilter.MaxFilter(radius * 2 + 1))


def contract(mask: Image.Image, radius: int) -> Image.Image:
    return mask.filter(ImageFilter.MinFilter(radius * 2 + 1))


def tile(source: Image.Image, col: int, row: int, size: int = 16) -> Image.Image:
    return source.crop((col * size, row * size, (col + 1) * size, (row + 1) * size))


def texture_on_mask(
    layer: Image.Image,
    texture: Image.Image,
    mask: Image.Image,
    choices: list[tuple[int, int]],
    seed: int,
) -> None:
    rng = random.Random(seed)
    cells = [tile(texture, col, row) for col, row in choices]
    working = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    for y in range(0, MAP_H, 16):
        for x in range(0, MAP_W, 16):
            if mask.getpixel((min(x + 8, MAP_W - 1), min(y + 8, MAP_H - 1))) > 120:
                working.alpha_composite(rng.choice(cells), (x, y))
    clipped = working.copy()
    clipped.putalpha(ImageChops.multiply(working.getchannel("A"), mask))
    layer.alpha_composite(clipped)


def color_on_mask(layer: Image.Image, mask: Image.Image, color: tuple[int, int, int, int]) -> None:
    overlay = Image.new("RGBA", layer.size, color)
    overlay.putalpha(ImageChops.multiply(mask, Image.new("L", layer.size, color[3])))
    layer.alpha_composite(overlay)


def path_mask(points: list[tuple[int, int]], width: int) -> Image.Image:
    mask = full_mask()
    draw = ImageDraw.Draw(mask)
    draw.line(points, fill=255, width=width, joint="curve")
    radius = width // 2
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)
    return mask


def place(
    layer: Image.Image,
    source: Image.Image,
    center: tuple[int, int],
    scale: float = 1.0,
    flip_x: bool = False,
    alpha: int = 255,
    brightness: float = 1.0,
) -> None:
    image = source
    if brightness != 1.0:
        image = ImageEnhance.Brightness(image).enhance(brightness)
    if flip_x:
        image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if scale != 1.0:
        image = image.resize(
            (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
            Image.Resampling.NEAREST,
        )
    if alpha != 255:
        image = image.copy()
        image.putalpha(image.getchannel("A").point(lambda value: value * alpha // 255))
    layer.alpha_composite(image, (round(center[0] - image.width / 2), round(center[1] - image.height / 2)))


def wood_building(
    layer: Image.Image,
    wood: Image.Image,
    fence: Image.Image,
    door: Image.Image,
    box: tuple[int, int, int, int],
    seed: int,
) -> None:
    x1, y1, x2, y2 = box
    roof = polygon_mask([(x1 - 6, y1 + 3), ((x1 + x2) // 2, y1 - 22), (x2 + 6, y1 + 3)])
    texture_on_mask(layer, wood, roof, [(0, 0), (1, 0), (2, 0), (3, 0)], seed)
    color_on_mask(layer, roof, (35, 18, 10, 90))
    walls = rect_mask((x1, y1, x2, y2), 2)
    texture_on_mask(layer, wood, walls, [(0, 0), (1, 0), (2, 0), (3, 0)], seed + 1)
    color_on_mask(layer, walls, (55, 27, 13, 45))
    for y in range(y1 + 2, y2, 10):
        place(layer, fence, (x1 + 2, y), 0.7, alpha=170)
        place(layer, fence, (x2 - 2, y), 0.7, alpha=170)
    for x in range(x1 + 6, x2 - 5, 12):
        place(layer, fence, (x, y2 - 2), 0.7, alpha=170)
    place(layer, door, ((x1 + x2) // 2, y2 - 5), 0.8)


def draw_world() -> Image.Image:
    grass = load("graphics/tilesets/grass.png")
    soil = load("graphics/tilesets/soil.png")
    trees = load("graphics/tilesets/trees.png")
    hills = load("graphics/tilesets/hills.png")
    hills_wood = load("graphics/tilesets/hills_wood.png")
    mountain = load("graphics/tilesets/mountain.png")
    camp_floor = load("graphics/camp/camp_floor.png")
    camp_fence = load("graphics/camp/camp_fence.png")
    campfire = load("graphics/camp/campfire.png").crop((0, 0, 32, 32))
    camp_log = load("graphics/camp/camp_log.png")
    gate = load("graphics/camp/gate_closed.png")
    door = load("graphics/camp/gate_open.png").crop((0, 0, 32, 24))
    player_sheet = load("graphics/characters/player_animations.png")
    melee_sheet = load("graphics/enemies/enemy_melee.png")
    ranged_sheet = load("graphics/enemies/enemy_ranged.png")
    elite_sheet = load("graphics/enemies/enemy_elite.png")
    boss_sheet = load("graphics/boss/boss_sheet.png")
    glow = load("graphics/fx/glow_white.png")
    arena_glow = load("graphics/boss/orb_burst.png")

    canvas = Image.new("RGBA", (MAP_W, MAP_H), (12, 43, 43, 255))
    terrain = polygon_mask(
        [
            (28, 91), (44, 58), (83, 36), (142, 25), (221, 22), (282, 28),
            (350, 24), (414, 33), (477, 34), (536, 51), (578, 79), (608, 118),
            (620, 166), (610, 217), (580, 249), (530, 265), (470, 268),
            (408, 278), (337, 274), (267, 282), (198, 272), (133, 262),
            (77, 240), (42, 209), (28, 166),
        ]
    )
    texture_on_mask(canvas, grass, terrain, [(1, 1), (2, 1), (1, 2)], 17)
    color_on_mask(canvas, contract(terrain, 7), (92, 127, 51, 18))
    edge = ImageChops.subtract(expand(terrain, 2), terrain).filter(ImageFilter.GaussianBlur(0.7))
    color_on_mask(canvas, edge, (141, 167, 92, 120))

    place(canvas, mountain, (321, 75), 0.58, alpha=220)

    main_road = path_mask(
        [
            (20, 158), (75, 158), (122, 171), (171, 164), (218, 166),
            (268, 174), (316, 160), (368, 171), (420, 160), (473, 165),
            (524, 157), (575, 164), (628, 157),
        ],
        20,
    )
    main_road = ImageChops.multiply(main_road, terrain)
    road_edge = ImageChops.subtract(expand(main_road, 2), main_road)
    color_on_mask(canvas, road_edge, (57, 72, 40, 105))
    texture_on_mask(canvas, soil, main_road, [(1, 1), (2, 1)], 21)

    branch_masks = [
        path_mask([(93, 158), (94, 126), (97, 103)], 12),
        path_mask([(218, 166), (218, 126), (219, 105)], 12),
        path_mask([(317, 168), (317, 127), (319, 111)], 11),
        path_mask([(420, 160), (420, 136), (424, 121)], 11),
    ]
    for index, branch in enumerate(branch_masks):
        branch = ImageChops.multiply(branch, terrain)
        texture_on_mask(canvas, soil, branch, [(1, 1)], 31 + index)

    plaza = ellipse_mask((169, 126, 269, 205))
    texture_on_mask(canvas, soil, plaza, [(1, 1), (2, 1)], 45)
    color_on_mask(canvas, plaza, (130, 94, 47, 45))

    training = rect_mask((267, 111, 365, 208), 12)
    texture_on_mask(canvas, soil, training, [(1, 1)], 48)
    training_border = ImageChops.subtract(training, contract(training, 2))
    color_on_mask(canvas, training_border, (91, 64, 34, 120))

    attack_zone = ellipse_mask((492, 91, 626, 230))
    texture_on_mask(canvas, soil, attack_zone, [(1, 1), (2, 1)], 51)
    color_on_mask(canvas, attack_zone, (110, 39, 16, 90))
    for box in [(505, 102, 545, 136), (553, 167, 607, 211), (577, 105, 619, 142)]:
        color_on_mask(canvas, ellipse_mask(box), (41, 21, 14, 110))

    wood_building(canvas, camp_floor, camp_fence, door, (53, 78, 132, 130), 61)
    wood_building(canvas, camp_floor, camp_fence, door, (171, 68, 242, 113), 72)
    wood_building(canvas, camp_floor, camp_fence, door, (391, 72, 461, 121), 83)

    # Central square and village landmarks.
    place(canvas, campfire, (219, 155), 1.25)
    place(canvas, camp_log, (187, 182), 0.9)
    place(canvas, camp_log, (252, 189), 0.85, flip_x=True)
    place(canvas, gate, (482, 159), 1.0)

    # Training yard.
    for x, y, flip in [(296, 151, False), (337, 180, True)]:
        place(canvas, camp_log, (x, y), 1.15, flip_x=flip)
    for x, y, col, row in [(279, 195, 3, 0), (316, 199, 4, 1), (354, 194, 3, 1)]:
        place(canvas, tile(hills_wood, col, row), (x, y), 1.0)

    # Supply chest built from existing wood/light assets.
    chest_mask = rect_mask((423, 168, 443, 181), 2)
    texture_on_mask(canvas, camp_floor, chest_mask, [(1, 0)], 94)
    color_on_mask(canvas, chest_mask, (130, 85, 22, 70))
    place(canvas, glow, (433, 174), 0.65, alpha=115)

    player = player_sheet.crop((0, 0, 48, 48))
    npc = player.copy()
    place(canvas, player, (91, 151), 1.05)
    place(canvas, npc, (214, 174), 1.0, brightness=1.15)
    place(canvas, npc, (422, 142), 1.0, brightness=1.1)

    # Village tree line and scenery.
    tree_positions = [
        (35, 95, 0, False), (49, 72, 32, True), (72, 51, 0, False),
        (105, 38, 32, True), (149, 31, 0, False), (195, 30, 32, False),
        (260, 33, 0, True), (307, 35, 32, False), (356, 30, 0, True),
        (409, 35, 32, False), (458, 43, 0, True), (510, 51, 32, False),
        (556, 69, 0, True), (589, 101, 32, False), (606, 139, 0, True),
        (603, 193, 32, False), (579, 230, 0, True), (538, 251, 32, False),
        (491, 258, 0, True), (431, 264, 32, False), (374, 260, 0, True),
        (313, 269, 32, False), (249, 271, 0, True), (190, 263, 32, False),
        (131, 253, 0, True), (85, 231, 32, False), (51, 207, 0, True),
        (34, 171, 32, False), (27, 132, 0, True),
    ]
    for x, y, frame, flip in tree_positions:
        source = trees.crop((frame, 0, frame + 32, 32))
        place(canvas, source, (x, y), 1.15, flip_x=flip)

    for x, y, col, row, flip in [
        (146, 139, 3, 0, False), (157, 181, 4, 1, True),
        (253, 105, 3, 1, False), (381, 130, 4, 0, True),
        (469, 133, 3, 0, False), (511, 84, 4, 1, True),
        (617, 121, 3, 1, False), (530, 226, 4, 0, True),
    ]:
        source = tile(hills if flip else hills_wood, col, row)
        place(canvas, source, (x, y), 1.25, flip_x=flip)

    # Winged-lizard attack field and final boss silhouette.
    melee = melee_sheet.crop((0, 0, 48, 48))
    ranged = ranged_sheet.crop((0, 0, 48, 48))
    elite = elite_sheet.crop((0, 0, 48, 48))
    place(canvas, melee, (524, 121), 0.9, brightness=0.95)
    place(canvas, ranged, (550, 192), 0.9, flip_x=True, brightness=0.95)
    place(canvas, elite, (570, 124), 0.95, brightness=0.9)
    place(canvas, arena_glow, (588, 172), 1.05, alpha=75)
    boss = boss_sheet.crop((0, 0, 160, 192))
    place(canvas, boss, (591, 168), 0.46, alpha=235)

    # Small ground details keep the broad grass areas from feeling empty.
    for x, y, col, row in [
        (153, 218, 3, 2), (239, 233, 4, 2), (284, 93, 3, 0),
        (371, 222, 4, 1), (455, 207, 3, 2), (128, 103, 4, 0),
    ]:
        place(canvas, tile(hills_wood, col, row), (x, y), 0.75, alpha=150)
    for x, y in [(113, 199), (178, 94), (258, 130), (365, 96), (451, 190), (486, 214)]:
        place(canvas, glow, (x, y), 0.32, alpha=35)

    return canvas


def add_labels(map_image: Image.Image) -> Image.Image:
    width = MAP_W * SCALE
    height = (MAP_H + FOOTER) * SCALE
    canvas = Image.new("RGBA", (width, height), (18, 28, 27, 255))
    scaled = map_image.resize((MAP_W * SCALE, MAP_H * SCALE), Image.Resampling.NEAREST)
    canvas.alpha_composite(scaled, (0, 0))

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((10, 10, width - 10, MAP_H * SCALE - 10), outline=(218, 194, 139, 215), width=3)
    draw.rectangle((0, MAP_H * SCALE, width, height), fill=(20, 29, 27, 255))

    font_path = Path("C:/Windows/Fonts/msyh.ttc")
    title_font = ImageFont.truetype(str(font_path), 32) if font_path.exists() else ImageFont.load_default()
    body_font = ImageFont.truetype(str(font_path), 20) if font_path.exists() else ImageFont.load_default()
    small_font = ImageFont.truetype(str(font_path), 16) if font_path.exists() else ImageFont.load_default()

    draw.text((28, MAP_H * SCALE + 12), "灰杉村地图概念预览", font=title_font, fill=(242, 224, 178))
    draw.text(
        (28, MAP_H * SCALE + 55),
        "主线动线：住宅 → 中央广场 → 职业训练场 → 铁匠铺/补给 → 东门 → 龙焰战场",
        font=body_font,
        fill=(182, 191, 176),
    )
    draw.text(
        (28, MAP_H * SCALE + 91),
        "绿色：安全村庄   棕色：主路径   橙红：龙焰威胁   龙头：裂翼兽区域",
        font=small_font,
        fill=(139, 159, 143),
    )

    labels = [
        ("主角住宅", (91, 117), (54, 39), (189, 158, 92)),
        ("中央广场 / 加雷斯", (218, 157), (153, 232), (202, 170, 82)),
        ("训练场 / 职业石碑", (317, 157), (280, 244), (173, 187, 96)),
        ("铁匠铺 / 补给", (425, 106), (390, 42), (190, 136, 75)),
        ("东门", (482, 159), (463, 234), (168, 139, 83)),
        ("翼蜥袭击区", (545, 157), (529, 61), (196, 86, 54)),
        ("裂翼兽战场", (590, 167), (537, 228), (197, 65, 42)),
    ]
    for title, anchor, label_pos, accent in labels:
        text_bbox = draw.textbbox((0, 0), title, font=small_font)
        text_w = text_bbox[2] - text_bbox[0]
        text_h = text_bbox[3] - text_bbox[1]
        bx = label_pos[0] * SCALE
        by = label_pos[1] * SCALE
        bw = text_w + 22
        bh = text_h + 14
        draw.rounded_rectangle(
            (bx, by, bx + bw, by + bh),
            radius=8,
            fill=(16, 24, 22, 225),
            outline=accent + (235,),
            width=2,
        )
        draw.text((bx + 11, by + 6), title, font=small_font, fill=(240, 234, 213))
        ax, ay = anchor[0] * SCALE, anchor[1] * SCALE
        tx, ty = bx + bw // 2, by + bh // 2
        draw.line((tx, ty, ax, ay), fill=accent + (235,), width=2)
        draw.ellipse((ax - 5, ay - 5, ax + 5, ay + 5), fill=accent + (255,), outline=(238, 230, 206, 255))
    return canvas


def main() -> None:
    world = draw_world()
    OUTPUT_CLEAN.parent.mkdir(parents=True, exist_ok=True)
    world.resize((MAP_W * SCALE, MAP_H * SCALE), Image.Resampling.NEAREST).save(OUTPUT_CLEAN, optimize=True)
    add_labels(world).save(OUTPUT, optimize=True)
    print(OUTPUT_CLEAN)
    print(OUTPUT)


if __name__ == "__main__":
    main()
