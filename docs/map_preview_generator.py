from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "新地图概念预览_v1.png"
OUTPUT_CLEAN = ROOT / "docs" / "新地图概念预览_v1_无标注.png"

TILE = 16
MAP_W = 480
MAP_H = 880
SCALE = 3


def load(path: str) -> Image.Image:
    return Image.open(ROOT / path).convert("RGBA")


def tile(texture: Image.Image, col: int, row: int, frame: int = 0) -> Image.Image:
    return texture.crop(
        (col * TILE + frame * TILE, row * TILE, col * TILE + TILE + frame * TILE, row * TILE + TILE)
    )


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


def subtract(mask: Image.Image, cutout: Image.Image) -> Image.Image:
    return ImageChops.subtract(mask, cutout)


def expand(mask: Image.Image, radius: int) -> Image.Image:
    return mask.filter(ImageFilter.MaxFilter(radius * 2 + 1))


def contract(mask: Image.Image, radius: int) -> Image.Image:
    return mask.filter(ImageFilter.MinFilter(radius * 2 + 1))


def paste_texture(layer: Image.Image, source: Image.Image, mask: Image.Image | None = None) -> None:
    if mask is None:
        layer.alpha_composite(source)
    else:
        clipped = source.copy()
        clipped.putalpha(ImageChops.multiply(source.getchannel("A"), mask))
        layer.alpha_composite(clipped)


def tile_mask(
    layer: Image.Image,
    texture: Image.Image,
    mask: Image.Image,
    coords: list[tuple[int, int]],
    seed: int = 1,
) -> None:
    rng = random.Random(seed)
    cells: dict[tuple[int, int], Image.Image] = {}
    for coord in coords:
        cells[coord] = tile(texture, coord[0], coord[1])
    working = Image.new("RGBA", (MAP_W, MAP_H), (0, 0, 0, 0))
    for y in range(0, MAP_H, TILE):
        for x in range(0, MAP_W, TILE):
            if mask.getpixel((min(x + TILE // 2, MAP_W - 1), min(y + TILE // 2, MAP_H - 1))) < 128:
                continue
            coord = rng.choice(coords)
            working.alpha_composite(cells[coord], (x, y))
    paste_texture(layer, working, mask)


def rounded_path_mask(
    points: list[tuple[int, int]],
    width: int,
) -> Image.Image:
    mask = full_mask()
    draw = ImageDraw.Draw(mask)
    draw.line(points, fill=255, width=width, joint="curve")
    radius = width // 2
    for point in points:
        draw.ellipse(
            (point[0] - radius, point[1] - radius, point[0] + radius, point[1] + radius),
            fill=255,
        )
    return mask.filter(ImageFilter.GaussianBlur(0.6))


def place(
    layer: Image.Image,
    source: Image.Image,
    center: tuple[int, int],
    scale: float = 1.0,
    flip_x: bool = False,
    alpha: int = 255,
) -> None:
    image = source
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


def add_soft_shadow(layer: Image.Image, mask: Image.Image, color: tuple[int, int, int, int]) -> None:
    shadow_mask = expand(mask, 5).filter(ImageFilter.GaussianBlur(5))
    shadow = Image.new("RGBA", (MAP_W, MAP_H), color)
    paste_texture(layer, shadow, shadow_mask)


def draw_world() -> Image.Image:
    grass = load("graphics/tilesets/grass.png")
    soil = load("graphics/tilesets/soil.png")
    water = load("graphics/tilesets/water.png")
    mutated = load("graphics/tilesets/mutated_ground.png")
    camp_floor = load("graphics/camp/camp_floor.png")
    fence = load("graphics/camp/camp_fence.png")
    mountain = load("graphics/tilesets/mountain.png")
    trees = load("graphics/tilesets/trees.png")
    hills = load("graphics/tilesets/hills.png")
    hills_wood = load("graphics/tilesets/hills_wood.png")
    campfire = load("graphics/camp/campfire.png").crop((0, 0, 32, 32))
    camp_log = load("graphics/camp/camp_log.png")
    table = load("graphics/camp/diary_table.png")
    diary = load("graphics/camp/despair_diary.png")
    gate = load("graphics/camp/gate_closed.png")
    bridge = load("graphics/objects/bridge_broken.png")
    fence_prop = load("graphics/objects/waste_fence.png")
    bones = load("graphics/objects/waste_bones.png")
    skull = load("graphics/objects/waste_skull.png")
    sword = load("graphics/objects/waste_sword.png")
    vine = load("graphics/objects/mutant_vine.png")
    plank = load("graphics/objects/plank_debris.png")
    metal = load("graphics/objects/rust_metal.png")
    root_spike = load("graphics/boss/root_spike.png")
    fog = load("graphics/fx/fog_wisp.png")
    player_sheet = load("graphics/characters/player_animations.png")
    boss_sheet = load("graphics/boss/boss_sheet.png")
    player = player_sheet.crop((0, 0, 48, 48))
    boss = boss_sheet.crop((0, 0, 80, 192))
    tomato = load("graphics/plants/tomatoes.png").crop((32, 0, 48, 32))
    corn = load("graphics/plants/corn.png").crop((32, 0, 48, 32))
    pumpkin = load("graphics/plants/pumpkin.png").crop((32, 0, 48, 32))

    canvas = Image.new("RGBA", (MAP_W, MAP_H), (16, 65, 77, 255))
    tile_mask(canvas, water, full_mask(), [(0, 0)], seed=11)

    # Keep the world compact and readable: a single long island with two ponds
    # and a separate boss island, instead of the current very large open sea.
    north = polygon_mask(
        [
            (42, 112), (58, 70), (96, 37), (156, 20), (231, 17),
            (305, 28), (369, 32), (421, 62), (433, 117), (412, 164),
            (384, 199), (334, 219), (292, 252), (244, 268), (191, 257),
            (145, 276), (101, 262), (67, 230), (42, 190), (34, 151),
        ]
    )
    central = polygon_mask(
        [
            (62, 216), (137, 222), (197, 249), (258, 270), (325, 250),
            (386, 216), (427, 246), (436, 301), (421, 350), (432, 400),
            (405, 447), (378, 474), (360, 529), (331, 556), (293, 548),
            (252, 535), (210, 548), (171, 523), (132, 522), (95, 484),
            (70, 442), (58, 389), (68, 347), (50, 296), (54, 250),
        ]
    )
    south = polygon_mask(
        [
            (218, 510), (270, 507), (316, 523), (354, 551), (364, 603),
            (343, 646), (306, 671), (257, 664), (217, 640), (188, 602),
            (186, 556), (196, 531),
        ]
    )
    west_ridge = ellipse_mask((37, 299, 114, 520))
    east_ridge = ellipse_mask((371, 173, 449, 378))
    land = union(north, central, south, west_ridge, east_ridge)

    west_pond = ellipse_mask((74, 382, 164, 466))
    east_lake = ellipse_mask((333, 301, 419, 377))
    central_hollow = ellipse_mask((304, 421, 371, 475))
    land = subtract(land, union(west_pond, east_lake, central_hollow))
    land = subtract(land, rounded_path_mask([(40, 298), (78, 302), (118, 326)], 8))

    add_soft_shadow(canvas, land, (3, 26, 32, 145))

    fog_layer = fog.resize((230, 115), Image.Resampling.BILINEAR)
    place(canvas, fog_layer, (119, 424), 1.0, alpha=42)
    place(canvas, fog_layer, (374, 339), 0.75, alpha=24)

    shoreline = expand(land, 3).filter(ImageFilter.GaussianBlur(1.2))
    shoreline = subtract(shoreline, land)
    shoreline_color = Image.new("RGBA", (MAP_W, MAP_H), (100, 155, 145, 120))
    paste_texture(canvas, shoreline_color, shoreline)

    # Grass uses the atlas's full interior tile, with a restrained mix so the
    # original pixel texture remains visible rather than becoming wallpaper.
    grass_layer = Image.new("RGBA", (MAP_W, MAP_H), (0, 0, 0, 0))
    tile_mask(grass_layer, grass, land, [(1, 1)], seed=47)
    paste_texture(canvas, grass_layer, land)

    # Large darker patches give the terrain a sense of elevation.
    patch_mask = union(
        ellipse_mask((78, 243, 230, 349)),
        ellipse_mask((265, 469, 393, 540)),
        ellipse_mask((342, 184, 439, 285)),
    )
    patch_mask = ImageChops.multiply(patch_mask, contract(land, 2))
    shade = Image.new("RGBA", (MAP_W, MAP_H), (38, 66, 40, 45))
    paste_texture(canvas, shade, patch_mask)

    # Mountain skyline, placed behind the safe camp.
    place(canvas, mountain, (244, 122), 0.92, alpha=238)

    # A compact wooden camp with a moat and a single southern gate.
    moat = subtract(rect_mask((145, 101, 351, 239), 22), rect_mask((155, 111, 341, 229), 16))
    tile_mask(canvas, water, moat, [(0, 0)], seed=102)
    camp = rect_mask((157, 113, 339, 227), 12)
    tile_mask(canvas, camp_floor, camp, [(0, 0), (1, 0), (2, 0), (3, 0)], seed=55)
    camp_edge = subtract(camp, contract(camp, 2))
    camp_edge_color = Image.new("RGBA", (MAP_W, MAP_H), (84, 44, 25, 120))
    paste_texture(canvas, camp_edge_color, camp_edge)

    # Main road snakes through the map and intentionally forms a visible S-curve.
    road_points = [
        (249, 226), (246, 252), (228, 278), (199, 300), (162, 318),
        (128, 344), (120, 374), (142, 405), (177, 421), (217, 437),
        (250, 467), (284, 486), (312, 514), (310, 550), (283, 575),
        (246, 592), (233, 624), (254, 651), (293, 664), (309, 684),
    ]
    road = rounded_path_mask(road_points, 22)
    road = ImageChops.multiply(road, land)
    road_shadow = expand(road, 2)
    road_shadow = subtract(road_shadow, road)
    road_shadow_color = Image.new("RGBA", (MAP_W, MAP_H), (47, 73, 43, 95))
    paste_texture(canvas, road_shadow_color, road_shadow)
    tile_mask(canvas, soil, road, [(1, 1)], seed=81)

    branch_east = rounded_path_mask(
        [(254, 470), (285, 451), (320, 439), (355, 441)], 14
    )
    branch_east = ImageChops.multiply(branch_east, land)
    tile_mask(canvas, soil, branch_east, [(1, 1)], seed=82)

    branch_west = rounded_path_mask(
        [(181, 422), (155, 435), (126, 445), (100, 443)], 14
    )
    branch_west = ImageChops.multiply(branch_west, land)
    tile_mask(canvas, soil, branch_west, [(1, 1)], seed=84)

    # Old farm plots in the quiet western branch.
    plots = union(
        rect_mask((84, 456, 142, 492), 3),
        rect_mask((152, 458, 208, 494), 3),
    )
    tile_mask(canvas, soil, plots, [(1, 1)], seed=91)
    plot_border = subtract(plots, contract(plots, 1))
    plot_border_color = Image.new("RGBA", (MAP_W, MAP_H), (104, 77, 44, 90))
    paste_texture(canvas, plot_border_color, plot_border)

    # Broken causeway leading to a dark, visually distinct arena.
    boss_land = polygon_mask(
        [
            (224, 710), (262, 690), (317, 692), (369, 721), (393, 771),
            (386, 828), (347, 857), (290, 862), (235, 842), (205, 802),
            (203, 757),
        ]
    )
    add_soft_shadow(canvas, boss_land, (2, 8, 13, 165))
    tile_mask(canvas, mutated, boss_land, [(1, 1)], seed=111)
    boss_ring = subtract(expand(boss_land, 3), boss_land)
    boss_ring = ImageChops.multiply(boss_ring, full_mask())
    boss_ring_color = Image.new("RGBA", (MAP_W, MAP_H), (67, 36, 68, 145))
    paste_texture(canvas, boss_ring_color, boss_ring)

    place(canvas, bridge, (308, 690), 1.0)

    # Camp landmarks.
    for x in range(166, 336, 16):
        place(canvas, fence, (x + 8, 115), 1.0)
    for y in range(123, 224, 16):
        place(canvas, fence, (160, y), 1.0)
        place(canvas, fence, (336, y), 1.0)
    place(canvas, gate, (248, 229), 1.1)
    place(canvas, campfire, (239, 146), 1.35)
    place(canvas, camp_log, (203, 171), 1.0)
    place(canvas, table, (299, 163), 1.0)
    place(canvas, diary, (286, 199), 1.0)
    place(canvas, player, (247, 192), 1.15)

    # Soft glow around the safe camp.
    glow = Image.new("RGBA", (MAP_W, MAP_H), (255, 212, 125, 0))
    glow_mask = ellipse_mask((195, 126, 285, 207)).filter(ImageFilter.GaussianBlur(14))
    glow.putalpha(glow_mask.point(lambda value: value * 40 // 255))
    canvas.alpha_composite(glow)
    place(canvas, campfire, (239, 146), 1.35)

    # Tree line: dense at the north and western edge, sparse around the arena.
    tree_positions = [
        (74, 112, 2, False), (92, 78, 21, True), (120, 58, 2, False),
        (156, 43, 21, True), (205, 44, 2, False), (255, 48, 21, False),
        (303, 55, 2, True), (350, 76, 21, False), (388, 105, 2, False),
        (61, 171, 21, True), (56, 230, 2, False), (50, 289, 21, False),
        (410, 194, 2, True), (424, 260, 21, False), (402, 392, 2, True),
        (80, 511, 21, False), (118, 538, 2, True), (167, 557, 21, False),
        (350, 591, 2, True), (382, 625, 21, False), (211, 664, 2, False),
        (371, 742, 21, True), (389, 804, 2, False), (227, 826, 21, False),
    ]
    for x, y, frame, flip_x in tree_positions:
        source = trees.crop((frame, 0, frame + 32, 32))
        place(canvas, source, (x, y), 1.15, flip_x=flip_x)

    # Rocks define choke points and keep the paths from feeling like open fields.
    for x, y, col, row, flip in [
        (107, 292, 3, 0, False), (383, 296, 4, 0, True), (191, 257, 3, 0, False),
        (331, 234, 4, 0, True), (71, 342, 4, 1, False), (399, 458, 3, 1, True),
        (170, 512, 3, 0, False), (330, 536, 4, 1, True), (186, 621, 3, 0, False),
        (363, 674, 4, 0, True), (212, 714, 4, 1, False), (388, 784, 3, 1, True),
    ]:
        source = tile(hills if flip else hills_wood, col, row)
        place(canvas, source, (x, y), 1.35, flip_x=flip)

    # Crops in the old field and ruins in the monster route.
    for x, y, crop in [
        (96, 468, tomato), (117, 468, corn), (137, 468, pumpkin),
        (165, 471, tomato), (186, 470, corn), (202, 472, pumpkin),
    ]:
        place(canvas, crop, (x, y), 0.9)
    for x, y, source in [
        (109, 522, fence_prop), (196, 532, sword), (220, 561, bones),
        (351, 451, fence_prop), (369, 472, skull), (290, 544, bones),
        (283, 621, sword), (261, 636, skull), (174, 594, fence_prop),
    ]:
        place(canvas, source, (x, y), 1.05)

    # Boss arena: keep the original creature and hazard art, but arrange it as
    # a readable silhouette rather than a dense pile of effects.
    fog_layer = fog.resize((300, 150), Image.Resampling.BILINEAR)
    place(canvas, fog_layer, (302, 775), 1.0, alpha=42)
    place(canvas, boss, (302, 788), 0.48, alpha=240)
    for x, y, flip in [
        (254, 826, False), (274, 831, True), (332, 836, False),
        (357, 818, True), (231, 786, True), (375, 785, False),
    ]:
        place(canvas, vine, (x, y), 0.9, flip_x=flip)
    for x, y, flip in [(250, 746, False), (347, 748, True), (285, 845, False)]:
        place(canvas, plank, (x, y), 0.9, flip_x=flip)
    for x, y in [(238, 767), (355, 753), (318, 839)]:
        place(canvas, metal, (x, y), 0.9)
    for x, y, flip in [(247, 803, False), (338, 791, True), (298, 826, False)]:
        place(canvas, root_spike, (x, y), 0.9, flip_x=flip)

    # Small grass/stone overlays keep the middle from looking too orderly.
    detail_points = [
        (114, 214), (307, 211), (153, 369), (319, 413), (206, 482),
        (352, 493), (155, 601), (324, 604), (232, 682), (367, 704),
    ]
    rock_details = [(3, 0), (4, 0), (3, 1), (4, 1), (3, 2), (4, 2)]
    for index, (x, y) in enumerate(detail_points):
        source = tile(hills_wood, *rock_details[index % len(rock_details)])
        place(canvas, source, (x, y), 0.8, alpha=150)

    return canvas


def add_labels(map_image: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", (MAP_W * SCALE, (MAP_H + 52) * SCALE), (22, 27, 27, 255))
    map_scaled = map_image.resize((MAP_W * SCALE, MAP_H * SCALE), Image.Resampling.NEAREST)
    canvas.alpha_composite(map_scaled, (0, 0))

    # Clean pixel-edge frame and a restrained title strip.
    frame = ImageDraw.Draw(canvas)
    frame.rectangle((10, 10, canvas.width - 10, MAP_H * SCALE - 10), outline=(222, 202, 154, 210), width=3)
    frame.rectangle((0, MAP_H * SCALE, canvas.width, canvas.height), fill=(24, 29, 27, 255))

    font_path = Path("C:/Windows/Fonts/msyh.ttc")
    title_font = ImageFont.truetype(str(font_path), 34) if font_path.exists() else ImageFont.load_default()
    body_font = ImageFont.truetype(str(font_path), 22) if font_path.exists() else ImageFont.load_default()
    small_font = ImageFont.truetype(str(font_path), 17) if font_path.exists() else ImageFont.load_default()

    frame.text((28, MAP_H * SCALE + 16), "新地图概念预览  ·  沿用现有美术素材", font=title_font, fill=(240, 226, 185))
    frame.text(
        (28, MAP_H * SCALE + 59),
        "纵向主线：安全营地 → 旧农田岔路 → 雾沼/林地 → 断桥 → 变异巢穴",
        font=body_font,
        fill=(181, 191, 176),
    )
    frame.text(
        (28, MAP_H * SCALE + 91),
        "★ 安全区    ◆ 可探索岔路    ━ 主线路径    ▲ 首领区域",
        font=small_font,
        fill=(139, 159, 143),
    )

    labels = [
        ("安全营地", (251, 140), (343, 66), (104, 154, 104)),
        ("旧农田", (128, 470), (29, 438), (169, 137, 79)),
        ("雾沼", (118, 423), (45, 348), (80, 145, 153)),
        ("断桥", (308, 682), (355, 634), (163, 113, 71)),
        ("变异巢穴", (307, 785), (361, 739), (150, 102, 171)),
    ]
    for title, anchor, label_pos, accent in labels:
        text_bbox = frame.textbbox((0, 0), title, font=small_font)
        text_w = text_bbox[2] - text_bbox[0]
        text_h = text_bbox[3] - text_bbox[1]
        bx = label_pos[0] * SCALE
        by = label_pos[1] * SCALE
        bw = text_w + 22
        bh = text_h + 14
        frame.rounded_rectangle((bx, by, bx + bw, by + bh), radius=8, fill=(20, 26, 24, 218), outline=accent + (230,), width=2)
        frame.text((bx + 11, by + 6), title, font=small_font, fill=(239, 234, 213))
        ax, ay = anchor[0] * SCALE, anchor[1] * SCALE
        tx, ty = bx + bw // 2, by + bh // 2
        frame.line((tx, ty, ax, ay), fill=accent + (235,), width=2)
        frame.ellipse((ax - 5, ay - 5, ax + 5, ay + 5), fill=accent + (255,), outline=(238, 230, 206, 255))
    return canvas


def main() -> None:
    map_image = draw_world()
    map_image.save(OUTPUT_CLEAN, optimize=True)
    final = add_labels(map_image)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    final.save(OUTPUT, optimize=True)
    print(OUTPUT_CLEAN)
    print(OUTPUT)
    print(f"{final.width}x{final.height}")


if __name__ == "__main__":
    main()
