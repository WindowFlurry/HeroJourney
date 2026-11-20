from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_MAP = ROOT / "docs" / "灰杉村地图方案_v2.png"
OUT_CLEAN = ROOT / "docs" / "灰杉村地图方案_v2_无标注.png"
OUT_SCENES = ROOT / "docs" / "灰杉村场景布局_v1.png"

W, H = 480, 620
SCALE = 3


def load(path: str) -> Image.Image:
    return Image.open(ROOT / path).convert("RGBA")


def mask() -> Image.Image:
    return Image.new("L", (W, H), 0)


def polygon(points: list[tuple[int, int]]) -> Image.Image:
    image = mask()
    ImageDraw.Draw(image).polygon(points, fill=255)
    return image


def ellipse(box: tuple[int, int, int, int]) -> Image.Image:
    image = mask()
    ImageDraw.Draw(image).ellipse(box, fill=255)
    return image


def rectangle(box: tuple[int, int, int, int], radius: int = 0) -> Image.Image:
    image = mask()
    draw = ImageDraw.Draw(image)
    if radius:
        draw.rounded_rectangle(box, radius=radius, fill=255)
    else:
        draw.rectangle(box, fill=255)
    return image


def union(*images: Image.Image) -> Image.Image:
    result = images[0].copy()
    for image in images[1:]:
        result = ImageChops.lighter(result, image)
    return result


def subtract(a: Image.Image, b: Image.Image) -> Image.Image:
    return ImageChops.subtract(a, b)


def grow(image: Image.Image, radius: int) -> Image.Image:
    return image.filter(ImageFilter.MaxFilter(radius * 2 + 1))


def shrink(image: Image.Image, radius: int) -> Image.Image:
    return image.filter(ImageFilter.MinFilter(radius * 2 + 1))


def crop_tile(atlas: Image.Image, col: int, row: int, size: int = 16) -> Image.Image:
    return atlas.crop((col * size, row * size, (col + 1) * size, (row + 1) * size))


def apply_texture(
    layer: Image.Image,
    texture: Image.Image,
    area: Image.Image,
    tiles: list[tuple[int, int]],
    seed: int,
) -> None:
    rng = random.Random(seed)
    choices = [crop_tile(texture, x, y) for x, y in tiles]
    working = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    for y in range(0, H, 16):
        for x in range(0, W, 16):
            if area.getpixel((min(x + 8, W - 1), min(y + 8, H - 1))) > 120:
                working.alpha_composite(rng.choice(choices), (x, y))
    working.putalpha(ImageChops.multiply(working.getchannel("A"), area))
    layer.alpha_composite(working)


def tint(layer: Image.Image, area: Image.Image, color: tuple[int, int, int, int]) -> None:
    overlay = Image.new("RGBA", layer.size, color)
    overlay.putalpha(ImageChops.multiply(area, Image.new("L", layer.size, color[3])))
    layer.alpha_composite(overlay)


def road(points: list[tuple[int, int]], width: int) -> Image.Image:
    image = mask()
    draw = ImageDraw.Draw(image)
    draw.line(points, fill=255, width=width, joint="curve")
    for x, y in points:
        radius = width // 2
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)
    return image


def paste(
    layer: Image.Image,
    sprite: Image.Image,
    center: tuple[int, int],
    scale: float = 1.0,
    flip: bool = False,
    alpha: int = 255,
    bright: float = 1.0,
) -> None:
    image = sprite
    if bright != 1.0:
        image = ImageEnhance.Brightness(image).enhance(bright)
    if flip:
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


def building(
    canvas: Image.Image,
    wood: Image.Image,
    fence: Image.Image,
    door: Image.Image,
    box: tuple[int, int, int, int],
    seed: int,
) -> None:
    x1, y1, x2, y2 = box
    body = rectangle(box, 2)
    apply_texture(canvas, wood, body, [(0, 0), (1, 0), (2, 0), (3, 0)], seed)
    roof = polygon([(x1 - 4, y1 + 4), ((x1 + x2) // 2, y1 - 15), (x2 + 4, y1 + 4)])
    apply_texture(canvas, wood, roof, [(0, 0), (1, 0), (2, 0), (3, 0)], seed + 1)
    tint(canvas, roof, (31, 17, 8, 130))
    border = subtract(body, shrink(body, 2))
    tint(canvas, border, (44, 24, 11, 130))
    for x in range(x1 + 4, x2 - 2, 12):
        paste(canvas, fence, (x, y2 - 2), 0.65, alpha=190)
    paste(canvas, door, ((x1 + x2) // 2, y2 - 4), 0.85)


def draw_map() -> Image.Image:
    grass = load("graphics/tilesets/grass.png")
    soil = load("graphics/tilesets/soil.png")
    trees = load("graphics/tilesets/trees.png")
    hills = load("graphics/tilesets/hills_wood.png")
    mountain = load("graphics/tilesets/mountain.png")
    wood = load("graphics/camp/camp_floor.png")
    fence = load("graphics/camp/camp_fence.png")
    door = load("graphics/camp/gate_open.png").crop((0, 0, 32, 24))
    gate = load("graphics/camp/gate_closed.png")
    fire = load("graphics/camp/campfire.png").crop((0, 0, 32, 32))
    table = load("graphics/camp/diary_table.png")
    log = load("graphics/camp/camp_log.png")
    player_sheet = load("graphics/characters/player_animations.png")
    player = player_sheet.crop((0, 0, 48, 48))

    canvas = Image.new("RGBA", (W, H), (13, 48, 54, 255))
    north = polygon(
        [
            (42, 112), (58, 70), (96, 37), (156, 20), (231, 17),
            (305, 28), (369, 32), (421, 62), (433, 117), (412, 164),
            (384, 199), (334, 219), (292, 252), (244, 268), (191, 257),
            (145, 276), (101, 262), (67, 230), (42, 190), (34, 151),
        ]
    )
    central = polygon(
        [
            (62, 216), (137, 222), (197, 249), (258, 270), (325, 250),
            (386, 216), (427, 246), (436, 301), (421, 350), (432, 400),
            (405, 447), (378, 474), (360, 529), (331, 556), (293, 548),
            (252, 535), (210, 548), (171, 523), (132, 522), (95, 484),
            (70, 442), (58, 389), (68, 347), (50, 296), (54, 250),
        ]
    )
    south = polygon(
        [
            (218, 510), (270, 507), (316, 523), (354, 551), (364, 603),
            (350, 620), (210, 620), (186, 556), (196, 531),
        ]
    )
    west = ellipse((37, 299, 114, 520))
    east = ellipse((371, 173, 449, 378))
    land = union(north, central, south, west, east)
    west_pond = ellipse((74, 382, 164, 466))
    east_lake = ellipse((333, 301, 419, 377))
    central_pool = ellipse((304, 421, 371, 475))
    water = union(west_pond, east_lake, central_pool)
    land = subtract(land, water)

    # 原地图轮廓不变，只将全部陆地替换为项目原生草地。
    apply_texture(canvas, grass, land, [(1, 1)], 71)
    tint(canvas, shrink(land, 8), (112, 148, 64, 12))
    shoreline = subtract(grow(land, 2), land).filter(ImageFilter.GaussianBlur(0.8))
    tint(canvas, shoreline, (137, 174, 126, 120))
    for pond in [west_pond, east_lake, central_pool]:
        tint(canvas, pond, (16, 76, 91, 255))
        rim = subtract(grow(pond, 2), pond)
        tint(canvas, rim, (101, 158, 134, 150))

    paste(canvas, mountain, (244, 107), 0.65, alpha=190)

    main_road = road(
        [
            (246, 247), (228, 276), (198, 299), (161, 318), (128, 344),
            (120, 374), (143, 405), (178, 421), (217, 437), (250, 467),
            (284, 486), (312, 514), (310, 550), (283, 575), (247, 605),
        ],
        22,
    )
    main_road = ImageChops.multiply(main_road, land)
    apply_texture(canvas, soil, main_road, [(1, 1)], 81)
    plaza_road = road([(244, 247), (247, 305), (268, 358), (310, 384)], 12)
    plaza_road = ImageChops.multiply(plaza_road, land)
    apply_texture(canvas, soil, plaza_road, [(1, 1)], 82)

    # 五处独立场景入口。
    building(canvas, wood, fence, door, (73, 232, 137, 270), 101)
    building(canvas, wood, fence, door, (343, 224, 407, 261), 111)
    building(canvas, wood, fence, door, (86, 436, 146, 471), 121)
    plaza = ellipse((204, 275, 305, 370))
    apply_texture(canvas, soil, plaza, [(1, 1), (2, 1)], 131)
    tint(canvas, plaza, (130, 94, 45, 42))
    paste(canvas, fire, (252, 311), 1.25)
    for x, y in [(220, 337), (251, 351), (285, 334)]:
        paste(canvas, hills, (x, y), 1.0)

    # 东门位于地图中部右侧，门后通向后续区域。
    gate_mask = rectangle((385, 337, 430, 350), 2)
    apply_texture(canvas, wood, gate_mask, [(0, 0), (1, 0)], 141)
    paste(canvas, gate, (408, 344), 1.0)

    # 铁匠铺的炉火与工作台。
    paste(canvas, fire, (120, 421), 0.9)
    paste(canvas, log, (159, 446), 0.85)
    paste(canvas, table, (322, 254), 0.9)
    paste(canvas, log, (211, 286), 0.75)

    # 玩家、加雷斯与村民仅作为比例参考。
    paste(canvas, player, (105, 287), 0.9)
    paste(canvas, player, (375, 279), 0.9, bright=1.25)
    paste(canvas, player, (260, 337), 0.9, bright=1.08)

    # 森林边缘与岩石，继续完全使用原素材。
    for x, y, frame, flip in [
        (75, 106, 0, False), (94, 75, 32, True), (120, 57, 0, False),
        (156, 43, 32, True), (204, 43, 0, False), (253, 47, 32, False),
        (303, 54, 0, True), (350, 76, 32, False), (388, 105, 0, False),
        (60, 171, 32, True), (55, 229, 0, False), (49, 288, 32, False),
        (410, 194, 0, True), (424, 260, 32, False), (402, 392, 0, True),
        (80, 511, 32, False), (118, 538, 0, True), (166, 557, 32, False),
        (351, 590, 0, True), (382, 626, 32, False),
    ]:
        source = trees.crop((frame, 0, frame + 32, 32))
        paste(canvas, source, (x, y), 1.02, flip=flip)
    for x, y in [(171, 224), (390, 302), (167, 411), (343, 466), (213, 522)]:
        paste(canvas, crop_tile(hills, 3, 0), (x, y), 1.0, alpha=210)

    return canvas


def map_preview(world: Image.Image, labels: bool) -> Image.Image:
    if not labels:
        return world.resize((W * SCALE, H * SCALE), Image.Resampling.NEAREST)
    image = Image.new("RGBA", (W * SCALE, (H + 40) * SCALE), (18, 27, 26, 255))
    image.alpha_composite(world.resize((W * SCALE, H * SCALE), Image.Resampling.NEAREST))
    draw = ImageDraw.Draw(image)
    draw.rectangle((8, 8, image.width - 8, H * SCALE - 8), outline=(220, 197, 145, 220), width=3)
    draw.rectangle((0, H * SCALE, image.width, image.height), fill=(20, 29, 27, 255))
    font_path = Path("C:/Windows/Fonts/msyh.ttc")
    title_font = ImageFont.truetype(str(font_path), 32)
    body_font = ImageFont.truetype(str(font_path), 19)
    small_font = ImageFont.truetype(str(font_path), 16)
    draw.text((26, H * SCALE + 13), "灰杉村地图方案 v2", font=title_font, fill=(242, 224, 180))
    draw.text((26, H * SCALE + 57), "保留原地图轮廓与主路 · 全地面替换为原生草地 · 五个独立场景入口", font=body_font, fill=(178, 188, 173))
    draw.text((26, H * SCALE + 89), "玩家住宅   加雷斯屋子   中央广场/转职   铁匠铺   东门", font=small_font, fill=(142, 159, 141))

    pins = [
        ("玩家住宅", (105, 252), (40, 205), (197, 159, 91)),
        ("加雷斯屋子", (375, 245), (330, 182), (184, 174, 104)),
        ("中央广场 / 转职", (252, 325), (180, 395), (218, 167, 77)),
        ("铁匠铺", (116, 453), (37, 486), (188, 128, 68)),
        ("东门", (408, 344), (347, 320), (165, 144, 91)),
    ]
    for title, anchor, pos, color in pins:
        box = draw.textbbox((0, 0), title, font=small_font)
        bw = box[2] - box[0] + 20
        bh = box[3] - box[1] + 14
        x, y = pos[0] * SCALE, pos[1] * SCALE
        draw.rounded_rectangle((x, y, x + bw, y + bh), radius=8, fill=(17, 24, 22, 230), outline=color + (240,), width=2)
        draw.text((x + 10, y + 6), title, font=small_font, fill=(240, 234, 213))
        ax, ay = anchor[0] * SCALE, anchor[1] * SCALE
        draw.line((x + bw // 2, y + bh // 2, ax, ay), fill=color + (240,), width=2)
        draw.ellipse((ax - 5, ay - 5, ax + 5, ay + 5), fill=color + (255,), outline=(240, 232, 209, 255))
    return image


def scene_panel(
    size: tuple[int, int],
    title: str,
    subtitle: str,
    draw_scene,
) -> Image.Image:
    panel = Image.new("RGBA", size, (18, 27, 25, 255))
    draw = ImageDraw.Draw(panel)
    draw.rounded_rectangle((2, 2, size[0] - 3, size[1] - 3), radius=14, fill=(23, 34, 30, 255), outline=(105, 89, 53, 255), width=2)
    font_path = Path("C:/Windows/Fonts/msyh.ttc")
    title_font = ImageFont.truetype(str(font_path), 24)
    small_font = ImageFont.truetype(str(font_path), 15)
    draw.text((18, 10), title, font=title_font, fill=(241, 218, 164))
    draw.text((18, 39), subtitle, font=small_font, fill=(157, 169, 151))
    scene = Image.new("RGBA", (size[0] - 32, size[1] - 76), (12, 22, 19, 255))
    draw_scene(scene)
    panel.alpha_composite(scene, (16, 64))
    return panel


def scene_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (1920, 1080), (12, 20, 18, 255))
    draw = ImageDraw.Draw(sheet)
    font_path = Path("C:/Windows/Fonts/msyh.ttc")
    title_font = ImageFont.truetype(str(font_path), 32)
    draw.text((38, 22), "灰杉村 · 五个场景布局", font=title_font, fill=(241, 222, 177))

    grass = load("graphics/tilesets/grass.png")
    wood = load("graphics/camp/camp_floor.png")
    fence = load("graphics/camp/camp_fence.png")
    fire = load("graphics/camp/campfire.png").crop((0, 0, 32, 32))
    table = load("graphics/camp/diary_table.png")
    log = load("graphics/camp/camp_log.png")
    door = load("graphics/camp/gate_closed.png")
    hills = load("graphics/tilesets/hills_wood.png")
    sword = load("graphics/objects/waste_sword.png")
    herb = load("graphics/items/herb.png")
    player = load("graphics/characters/player_animations.png").crop((0, 0, 48, 48))

    def local_texture(scene: Image.Image, texture: Image.Image, area: Image.Image, seed: int) -> None:
        rng = random.Random(seed)
        cell = crop_tile(texture, 1, 1)
        working = Image.new("RGBA", scene.size, (0, 0, 0, 0))
        for y in range(0, scene.height, 16):
            for x in range(0, scene.width, 16):
                if area.getpixel((min(x + 8, scene.width - 1), min(y + 8, scene.height - 1))) > 100:
                    working.alpha_composite(cell, (x, y))
        working.putalpha(ImageChops.multiply(working.getchannel("A"), area))
        scene.alpha_composite(working)

    def room(scene: Image.Image, palette: tuple[int, int, int]) -> None:
        local_w, local_h = scene.size
        floor = Image.new("L", scene.size, 0)
        ImageDraw.Draw(floor).rounded_rectangle((18, 16, local_w - 18, local_h - 16), radius=8, fill=255)
        rng = random.Random(21)
        cells = [crop_tile(wood, i, 0) for i in range(4)]
        for y in range(0, local_h, 16):
            for x in range(0, local_w, 16):
                if floor.getpixel((min(x + 8, local_w - 1), min(y + 8, local_h - 1))) > 100:
                    scene.alpha_composite(rng.choice(cells), (x, y))
        border = subtract(floor, shrink_for(scene.size, floor, 3))
        overlay = Image.new("RGBA", scene.size, palette + (90,))
        overlay.putalpha(border)
        scene.alpha_composite(overlay)

    def draw_player_house(scene: Image.Image) -> None:
        room(scene, (48, 25, 13))
        paste(scene, table, (110, 95), 1.2)
        paste(scene, log, (315, 94), 1.1)
        paste(scene, player, (225, 150), 1.2)
        paste(scene, door, (225, 238), 1.25)
        paste(scene, herb, (140, 190), 1.3)

    def draw_gareth_house(scene: Image.Image) -> None:
        room(scene, (48, 25, 13))
        paste(scene, table, (118, 112), 1.25)
        paste(scene, log, (348, 98), 1.1)
        paste(scene, fire, (310, 200), 1.1)
        paste(scene, player, (235, 157), 1.2, bright=1.2)
        paste(scene, door, (235, 242), 1.25)

    def draw_plaza(scene: Image.Image) -> None:
        local_w, local_h = scene.size
        area = Image.new("L", scene.size, 0)
        ImageDraw.Draw(area).ellipse((18, 12, local_w - 18, local_h - 12), fill=255)
        local_texture(scene, grass, area, 9)
        inner = Image.new("L", scene.size, 0)
        ImageDraw.Draw(inner).ellipse((55, 35, local_w - 55, local_h - 35), fill=255)
        local_texture(scene, load("graphics/tilesets/soil.png"), inner, 4)
        paste(scene, fire, (local_w // 2, local_h // 2), 1.3)
        for x, y in [(110, 75), (410, 75), (260, 225)]:
            paste(scene, crop_tile(hills, 3, 0), (x, y), 1.4)

    def draw_blacksmith(scene: Image.Image) -> None:
        room(scene, (59, 31, 14))
        paste(scene, fire, (120, 170), 1.2)
        paste(scene, table, (290, 120), 1.25)
        paste(scene, log, (350, 190), 1.2)
        paste(scene, sword, (235, 105), 1.2)
        paste(scene, sword, (270, 105), 1.2)
        paste(scene, player, (245, 190), 1.1, bright=1.1)
        paste(scene, door, (245, 250), 1.2)

    def draw_east_gate(scene: Image.Image) -> None:
        local_w, local_h = scene.size
        local_texture(scene, grass, Image.new("L", scene.size, 255), 12)
        path_area = Image.new("L", scene.size, 0)
        ImageDraw.Draw(path_area).rectangle((local_w // 2 - 45, 0, local_w // 2 + 45, local_h), fill=255)
        local_texture(scene, load("graphics/tilesets/soil.png"), path_area, 22)
        paste(scene, door, (local_w // 2, 95), 1.8)
        paste(scene, fence, (local_w // 2 - 180, 92), 1.5)
        paste(scene, fence, (local_w // 2 + 180, 92), 1.5)
        paste(scene, table, (local_w - 90, 67), 1.0)
        paste(scene, player, (local_w // 2, 215), 1.2)

    panels = [
        scene_panel((604, 470), "01  玩家屋内", "起床 · 初始交互 · 前往广场", draw_player_house),
        scene_panel((604, 470), "02  加雷斯屋子", "剧情对话 · 银誓背景 · 任务引导", draw_gareth_house),
        scene_panel((604, 470), "03  中央广场", "职业石碑 · 三职业选择 · 训练入口", draw_plaza),
        scene_panel((920, 470), "04  铁匠铺", "武器展示 · 装备教学 · 补给宝箱", draw_blacksmith),
        scene_panel((920, 470), "05  东门", "村庄出口 · 遇袭触发 · 前往战场", draw_east_gate),
    ]
    sheet.alpha_composite(panels[0], (38, 74))
    sheet.alpha_composite(panels[1], (658, 74))
    sheet.alpha_composite(panels[2], (1278, 74))
    sheet.alpha_composite(panels[3], (38, 566))
    sheet.alpha_composite(panels[4], (970, 566))
    return sheet


def shrink_for(size: tuple[int, int], image: Image.Image, radius: int) -> Image.Image:
    return image.filter(ImageFilter.MinFilter(radius * 2 + 1))


def main() -> None:
    world = draw_map()
    OUT_CLEAN.parent.mkdir(parents=True, exist_ok=True)
    OUT_CLEAN.unlink(missing_ok=True)
    map_preview(world, False).save(OUT_CLEAN, optimize=True)
    map_preview(world, True).save(OUT_MAP, optimize=True)
    scene_sheet().save(OUT_SCENES, optimize=True)
    print(OUT_MAP)
    print(OUT_CLEAN)
    print(OUT_SCENES)


if __name__ == "__main__":
    main()
