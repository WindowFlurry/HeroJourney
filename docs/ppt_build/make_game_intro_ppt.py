from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Inches, Pt
from pptx.oxml.ns import qn


ROOT = Path(r"C:\Users\26601\Desktop\11.finish")
DOCS = ROOT / "docs"
BUILD = DOCS / "ppt_build"
ASSETS = BUILD / "assets"
OUT = DOCS / "勇者之旅_玩法与剧情介绍.pptx"

ASSETS.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Palette and typography
# ---------------------------------------------------------------------------

BG = (19, 17, 14)
BG_SOFT = (28, 25, 20)
PANEL = (35, 29, 22)
PANEL_LIGHT = (52, 42, 30)
PARCHMENT = (220, 198, 153)
TEXT = (236, 226, 204)
TEXT_MUTED = (174, 160, 136)
GOLD = (201, 155, 78)
GOLD_LIGHT = (238, 202, 122)
GOLD_DARK = (116, 83, 40)
EMBER = (228, 104, 43)
RED = (173, 63, 48)
TEAL = (75, 154, 166)
GREEN = (93, 145, 86)
PURPLE = (131, 91, 171)
BLUE = (92, 139, 191)

FONT_TITLE = "KaiTi"
FONT_BODY = "Microsoft YaHei"


def rgb(value: tuple[int, int, int]) -> RGBColor:
    return RGBColor(*value)


def px(value: float):
    return Pt(value)


def hex_color(value: tuple[int, int, int]) -> str:
    return "#{:02X}{:02X}{:02X}".format(*value)


def _set_run_font(run, name: str) -> None:
    run.font.name = name
    rpr = run._r.get_or_add_rPr()
    ea = rpr.find(qn("a:ea"))
    if ea is None:
        ea = rpr.makeelement(qn("a:ea"), {})
        rpr.append(ea)
    ea.set("typeface", name)


def add_text(
    slide,
    text: str,
    x: float,
    y: float,
    w: float,
    h: float,
    *,
    size: int = 16,
    color: tuple[int, int, int] = TEXT,
    font: str = FONT_BODY,
    bold: bool = False,
    align=PP_ALIGN.LEFT,
    valign=MSO_ANCHOR.TOP,
    margin: float = 0.04,
    line_spacing: float = 1.08,
    italic: bool = False,
):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.clear()
    tf.word_wrap = True
    tf.margin_left = Inches(margin)
    tf.margin_right = Inches(margin)
    tf.margin_top = Inches(margin)
    tf.margin_bottom = Inches(margin)
    tf.vertical_anchor = valign
    p = tf.paragraphs[0]
    p.alignment = align
    p.line_spacing = line_spacing
    run = p.add_run()
    run.text = text
    _set_run_font(run, font)
    run.font.size = px(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = rgb(color)
    return box


def add_multiline(
    slide,
    lines,
    x: float,
    y: float,
    w: float,
    h: float,
    *,
    size: int = 15,
    color: tuple[int, int, int] = TEXT,
    font: str = FONT_BODY,
    bullet: bool = False,
    gap: int = 7,
    margin: float = 0.05,
):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.clear()
    tf.word_wrap = True
    tf.margin_left = Inches(margin)
    tf.margin_right = Inches(margin)
    tf.margin_top = Inches(margin)
    tf.margin_bottom = Inches(margin)
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.space_after = px(gap)
        p.line_spacing = 1.08
        run = p.add_run()
        run.text = ("• " if bullet else "") + str(line)
        _set_run_font(run, font)
        run.font.size = px(size)
        run.font.color.rgb = rgb(color)
    return box


def add_rect(
    slide,
    x: float,
    y: float,
    w: float,
    h: float,
    *,
    fill: tuple[int, int, int] = PANEL,
    line: tuple[int, int, int] | None = GOLD_DARK,
    line_width: float = 1.25,
    rounded: bool = False,
    radius: float = 0.12,
):
    shape_type = MSO_SHAPE.ROUNDED_RECTANGLE if rounded else MSO_SHAPE.RECTANGLE
    shape = slide.shapes.add_shape(shape_type, Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = rgb(fill)
    if line is None:
        shape.line.fill.background()
    else:
        shape.line.color.rgb = rgb(line)
        shape.line.width = Pt(line_width)
    if rounded and hasattr(shape, "adjustments"):
        try:
            shape.adjustments[0] = min(radius, 0.45)
        except Exception:
            pass
    return shape


def add_outline_rect(
    slide,
    x: float,
    y: float,
    w: float,
    h: float,
    *,
    line: tuple[int, int, int] = GOLD,
    line_width: float = 1.4,
    rounded: bool = False,
    radius: float = 0.12,
):
    shape_type = MSO_SHAPE.ROUNDED_RECTANGLE if rounded else MSO_SHAPE.RECTANGLE
    shape = slide.shapes.add_shape(shape_type, Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.background()
    shape.line.color.rgb = rgb(line)
    shape.line.width = Pt(line_width)
    if rounded and hasattr(shape, "adjustments"):
        try:
            shape.adjustments[0] = min(radius, 0.45)
        except Exception:
            pass
    return shape


def add_line(
    slide,
    x1: float,
    y1: float,
    x2: float,
    y2: float,
    *,
    color: tuple[int, int, int] = GOLD_DARK,
    width: float = 1.2,
):
    shape = slide.shapes.add_connector(1, Inches(x1), Inches(y1), Inches(x2), Inches(y2))
    shape.line.color.rgb = rgb(color)
    shape.line.width = Pt(width)
    return shape


def add_diamond(slide, x: float, y: float, size: float, color=GOLD):
    shape = slide.shapes.add_shape(
        MSO_SHAPE.DIAMOND, Inches(x), Inches(y), Inches(size), Inches(size)
    )
    shape.fill.solid()
    shape.fill.fore_color.rgb = rgb(color)
    shape.line.fill.background()
    return shape


def add_corner_ornaments(slide, x: float, y: float, w: float, h: float, color=GOLD_DARK):
    arm = 0.22
    for cx, cy, dx, dy in [
        (x, y, 1, 1),
        (x + w, y, -1, 1),
        (x, y + h, 1, -1),
        (x + w, y + h, -1, -1),
    ]:
        add_line(slide, cx, cy, cx + dx * arm, cy, color=color, width=1.6)
        add_line(slide, cx, cy, cx, cy + dy * arm, color=color, width=1.6)
        add_diamond(slide, cx - 0.035, cy - 0.035, 0.07, color)


def add_panel(slide, x, y, w, h, *, fill=PANEL, border=GOLD_DARK, inner=True, radius=0.08):
    add_rect(slide, x, y, w, h, fill=fill, line=border, rounded=True, radius=radius)
    if inner:
        add_rect(
            slide,
            x + 0.08,
            y + 0.08,
            w - 0.16,
            h - 0.16,
            fill=fill,
            line=(83, 65, 42),
            line_width=0.75,
            rounded=True,
            radius=radius,
        )
    add_corner_ornaments(slide, x + 0.02, y + 0.02, w - 0.04, h - 0.04)


def add_picture(slide, path: Path, x: float, y: float, w: float | None = None, h: float | None = None):
    kwargs = {}
    if w is not None:
        kwargs["width"] = Inches(w)
    if h is not None:
        kwargs["height"] = Inches(h)
    return slide.shapes.add_picture(str(path), Inches(x), Inches(y), **kwargs)


def add_bg(slide, path: Path):
    pic = slide.shapes.add_picture(str(path), 0, 0, width=Inches(13.333), height=Inches(7.5))
    slide.shapes._spTree.remove(pic._element)
    slide.shapes._spTree.insert(2, pic._element)
    return pic


def add_header(slide, number: str, kicker: str, title: str, subtitle: str = ""):
    add_text(
        slide,
        f"{number}  /  {kicker}",
        0.66,
        0.34,
        4.9,
        0.26,
        size=9,
        color=GOLD,
        bold=True,
    )
    add_text(
        slide,
        title,
        0.64,
        0.67,
        11.7,
        0.55,
        size=28,
        color=PARCHMENT,
        font=FONT_TITLE,
        bold=True,
    )
    add_line(slide, 0.68, 1.33, 12.48, 1.33, color=GOLD_DARK, width=1.3)
    add_diamond(slide, 0.625, 1.295, 0.08, GOLD)
    add_diamond(slide, 12.45, 1.295, 0.08, GOLD)
    if subtitle:
        add_text(
            slide,
            subtitle,
            0.72,
            1.43,
            11.6,
            0.35,
            size=11,
            color=TEXT_MUTED,
        )


def add_footer(slide, page: int, note: str = "勇者之旅 · 赤冠之龙"):
    add_line(slide, 0.68, 7.08, 12.48, 7.08, color=(71, 55, 37), width=0.8)
    add_text(slide, note, 0.72, 7.13, 5.0, 0.2, size=7.5, color=(130, 118, 99))
    add_text(
        slide,
        f"{page:02d}",
        12.23,
        7.11,
        0.25,
        0.23,
        size=8,
        color=GOLD,
        bold=True,
        align=PP_ALIGN.RIGHT,
        margin=0,
    )


def add_notes(slide, text: str):
    slide.notes_slide.notes_text_frame.text = text


# ---------------------------------------------------------------------------
# Image preparation
# ---------------------------------------------------------------------------

def make_cover_bg() -> Path:
    src = Image.open(ROOT / "graphics/ui/menu_bg.png").convert("RGB")
    base = ImageOps.fit(src, (1920, 1080), method=Image.Resampling.NEAREST)
    base = ImageEnhance.Color(base).enhance(0.84)
    overlay = Image.new("RGBA", base.size, (10, 12, 10, 0))
    px = overlay.load()
    for y in range(base.height):
        for x in range(base.width):
            a = int(142 + 80 * (1.0 - x / base.width))
            px[x, y] = (11, 13, 11, min(225, a))
    base = Image.alpha_composite(base.convert("RGBA"), overlay)

    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for i in range(12, 0, -1):
        alpha = int(7 + (12 - i) * 1.3)
        gd.ellipse((1160, 85, 1840, 765), fill=(224, 92, 37, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(38))
    base = Image.alpha_composite(base, glow)

    out = ASSETS / "cover_bg.png"
    base.convert("RGB").save(out, quality=95)
    return out


def make_deck_bg(final: bool = False) -> Path:
    src = Image.open(ROOT / "graphics/ui/menu_bg.png").convert("RGB")
    fitted = ImageOps.fit(src, (1920, 1080), method=Image.Resampling.NEAREST)
    fitted = fitted.filter(ImageFilter.GaussianBlur(1.3))
    base = Image.new("RGBA", (1920, 1080), (*BG, 255))
    base = Image.blend(base, fitted.convert("RGBA"), 0.11)

    shade = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    if final:
        for i in range(20, 0, -1):
            alpha = int(3 + (20 - i) * 1.1)
            sd.ellipse((1120, 50, 2020, 940), fill=(177, 57, 30, alpha))
    else:
        for i in range(15, 0, -1):
            alpha = int(2 + (15 - i) * 0.8)
            sd.ellipse((1280, 360, 2000, 1080), fill=(170, 108, 42, alpha))
    shade = shade.filter(ImageFilter.GaussianBlur(48))
    base = Image.alpha_composite(base, shade)

    vignette = Image.new("RGBA", base.size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle((0, 0, 1920, 80), fill=(0, 0, 0, 50))
    vd.rectangle((0, 1000, 1920, 1080), fill=(0, 0, 0, 80))
    base = Image.alpha_composite(base, vignette)

    out = ASSETS / ("final_bg.png" if final else "deck_bg.png")
    base.convert("RGB").save(out, quality=95)
    return out


def crop_sprite(src: Path, out_name: str, box=(0, 0, 48, 48), size=420) -> Path:
    image = Image.open(src).convert("RGBA")
    sprite = image.crop(box)
    bbox = sprite.getbbox()
    if bbox:
        sprite = sprite.crop(bbox)
    sprite = ImageOps.contain(sprite, (size, size), method=Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        sprite,
        ((size - sprite.width) // 2, (size - sprite.height) // 2),
    )
    out = ASSETS / out_name
    canvas.save(out)
    return out


def upscale_icon(src: Path, out_name: str, size=220) -> Path:
    image = Image.open(src).convert("RGBA")
    bbox = image.getbbox()
    if bbox:
        image = image.crop(bbox)
    image = ImageOps.contain(image, (size, size), method=Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        image,
        ((size - image.width) // 2, (size - image.height) // 2),
    )
    out = ASSETS / out_name
    canvas.save(out)
    return out


def make_arrow_icon() -> Path:
    image = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Diagonal arrow: wooden shaft, steel tip, green feather.
    draw.line((7, 25, 21, 11), fill=(190, 142, 73, 255), width=4)
    draw.polygon([(19, 13), (26, 6), (22, 18)], fill=(205, 215, 207, 255))
    draw.line((7, 25, 3, 29), fill=(98, 151, 93, 255), width=3)
    draw.line((5, 27, 10, 31), fill=(98, 151, 93, 255), width=2)
    image = image.resize((220, 220), Image.Resampling.NEAREST)
    out = ASSETS / "icon_arrow.png"
    image.save(out)
    return out


def make_dragon_sigil() -> Path:
    size = 640
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    cx, cy = size // 2, size // 2

    # Pixel step ring.
    draw.rectangle((72, 72, 568, 568), outline=(89, 60, 35, 255), width=12)
    draw.rectangle((94, 94, 546, 546), outline=(201, 155, 78, 255), width=5)
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        p1 = (cx + int(math.cos(rad) * 260), cy + int(math.sin(rad) * 260))
        p2 = (cx + int(math.cos(rad) * 288), cy + int(math.sin(rad) * 288))
        draw.line((p1, p2), fill=(155, 105, 49, 255), width=9)

    # Ember inner field.
    draw.ellipse((150, 150, 490, 490), fill=(84, 30, 24, 255), outline=(119, 45, 31, 255), width=8)
    draw.ellipse((184, 184, 456, 456), fill=(42, 26, 22, 255), outline=(166, 70, 38, 255), width=4)

    # Stylised dragon eye and horns.
    draw.polygon(
        [(244, 235), (198, 178), (280, 220), (318, 188), (358, 220), (448, 180), (397, 244)],
        fill=(174, 71, 39, 255),
        outline=(235, 150, 63, 255),
    )
    draw.polygon(
        [(208, 307), (285, 265), (345, 307), (397, 273), (431, 320), (372, 363), (322, 341), (275, 390), (214, 355)],
        fill=(31, 20, 18, 255),
        outline=(219, 104, 44, 255),
    )
    draw.polygon([(246, 313), (318, 291), (390, 319), (318, 336)], fill=(253, 166, 55, 255))
    draw.line((318, 292, 318, 337), fill=(79, 28, 20, 255), width=5)
    draw.line((300, 420, 275, 492), fill=(200, 73, 38, 255), width=18)
    draw.line((335, 420, 365, 495), fill=(200, 73, 38, 255), width=18)
    draw.line((274, 492, 245, 510), fill=(230, 122, 43, 255), width=10)
    draw.line((365, 495, 398, 510), fill=(230, 122, 43, 255), width=10)

    out = ASSETS / "dragon_sigil.png"
    image.save(out)
    return out


def make_ui_mock_asset() -> Path:
    """Small ornamental pixel divider used as a graphic accent."""
    image = Image.new("RGBA", (768, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.line((20, 48, 300, 48), fill=(*GOLD_DARK, 255), width=4)
    draw.line((468, 48, 748, 48), fill=(*GOLD_DARK, 255), width=4)
    draw.rectangle((322, 32, 446, 64), outline=(*GOLD, 255), width=4)
    draw.polygon([(344, 48), (370, 28), (396, 48), (370, 68)], fill=(173, 63, 48, 255))
    draw.polygon([(396, 48), (422, 28), (448, 48), (422, 68)], fill=(228, 104, 43, 255))
    for x in (8, 304, 464, 760):
        draw.rectangle((x - 5, 43, x + 5, 53), fill=(*GOLD, 255))
    out = ASSETS / "divider.png"
    image.save(out)
    return out


def prepare_assets():
    cover = make_cover_bg()
    deck = make_deck_bg(False)
    final = make_deck_bg(True)
    hero = crop_sprite(
        ROOT / "graphics/characters/player_animations.png",
        "hero_idle.png",
        (0, 0, 48, 48),
        520,
    )
    hero_alt = crop_sprite(
        ROOT / "graphics/characters/player_animations.png",
        "hero_attack.png",
        (48 * 7, 0, 48 * 8, 48),
        520,
    )
    melee = crop_sprite(
        ROOT / "graphics/enemies/enemy_melee.png",
        "enemy_melee.png",
        (0, 0, 48, 48),
        360,
    )
    ranged = crop_sprite(
        ROOT / "graphics/enemies/enemy_ranged.png",
        "enemy_ranged.png",
        (0, 0, 48, 48),
        360,
    )
    elite = crop_sprite(
        ROOT / "graphics/enemies/enemy_elite.png",
        "enemy_elite.png",
        (0, 0, 48, 48),
        360,
    )
    sword = upscale_icon(ROOT / "graphics/ui/weapon_sword.png", "icon_sword.png")
    axe = upscale_icon(ROOT / "graphics/ui/weapon_axe.png", "icon_axe.png")
    orb = upscale_icon(ROOT / "graphics/boss/orb.png", "icon_orb.png")
    herb = upscale_icon(ROOT / "graphics/items/herb.png", "icon_herb.png")
    vine = upscale_icon(ROOT / "graphics/items/vine.png", "icon_vine.png")
    shield = upscale_icon(ROOT / "graphics/items/shield_up.png", "icon_shield.png")
    armor = upscale_icon(ROOT / "graphics/items/armor2.png", "icon_armor.png")
    gland = upscale_icon(ROOT / "graphics/items/gland.png", "icon_gland.png")
    arrow = make_arrow_icon()
    sigil = make_dragon_sigil()
    divider = make_ui_mock_asset()
    warning = upscale_icon(ROOT / "graphics/boss/warning_square.png", "warning_square.png", 300)
    return locals()


# ---------------------------------------------------------------------------
# Reusable slide components
# ---------------------------------------------------------------------------

def add_keycap(slide, text: str, x: float, y: float, w: float, h: float, accent=GOLD):
    add_rect(slide, x, y, w, h, fill=(26, 23, 19), line=accent, line_width=1.2, rounded=True, radius=0.18)
    add_text(
        slide,
        text,
        x,
        y - 0.005,
        w,
        h,
        size=10 if len(text) <= 2 else 7,
        color=GOLD_LIGHT,
        bold=True,
        align=PP_ALIGN.CENTER,
        valign=MSO_ANCHOR.MIDDLE,
        margin=0,
    )


def add_number_badge(slide, number: str, x: float, y: float, color=GOLD):
    circle = slide.shapes.add_shape(MSO_SHAPE.OVAL, Inches(x), Inches(y), Inches(0.42), Inches(0.42))
    circle.fill.solid()
    circle.fill.fore_color.rgb = rgb((27, 23, 18))
    circle.line.color.rgb = rgb(color)
    circle.line.width = Pt(1.4)
    add_text(
        slide,
        number,
        x,
        y,
        w=0.42,
        h=0.42,
        size=9,
        color=color,
        bold=True,
        align=PP_ALIGN.CENTER,
        valign=MSO_ANCHOR.MIDDLE,
        margin=0,
    )


def add_icon_card(slide, icon: Path, x: float, y: float, w: float, h: float, accent=GOLD):
    add_panel(slide, x, y, w, h, fill=(31, 27, 21), border=(88, 68, 42))
    add_rect(slide, x + 0.12, y + 0.12, w - 0.24, 0.05, fill=accent, line=None)
    icon_size = min(w - 0.5, 1.25)
    add_picture(slide, icon, x + (w - icon_size) / 2, y + 0.25, icon_size, icon_size)


def add_dragon_seal(slide, sigil: Path, x: float, y: float, size: float):
    add_picture(slide, sigil, x, y, size, size)


# ---------------------------------------------------------------------------
# Slides
# ---------------------------------------------------------------------------

def slide_cover(prs, assets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_bg(slide, assets["cover"])

    add_rect(slide, 0.0, 0.0, 0.16, 7.5, fill=GOLD_DARK, line=None)
    add_rect(slide, 0.0, 0.0, 13.333, 0.10, fill=GOLD_DARK, line=None)
    add_text(
        slide,
        "GODOT 4  ·  2D ACTION ADVENTURE",
        0.86,
        0.64,
        6.2,
        0.3,
        size=10,
        color=GOLD_LIGHT,
        bold=True,
    )
    add_text(
        slide,
        "勇者之旅",
        0.78,
        1.17,
        7.1,
        1.12,
        size=54,
        color=PARCHMENT,
        font=FONT_TITLE,
        bold=True,
    )
    add_text(
        slide,
        "赤冠之龙",
        0.86,
        2.25,
        6.0,
        0.66,
        size=27,
        color=GOLD_LIGHT,
        font=FONT_TITLE,
        bold=True,
    )
    add_line(slide, 0.9, 3.09, 6.6, 3.09, color=GOLD, width=1.1)
    add_diamond(slide, 0.855, 3.05, 0.08, EMBER)
    add_text(
        slide,
        "从灰杉村启程，在誓火熄灭前击败恶龙。",
        0.88,
        3.31,
        6.0,
        0.52,
        size=17,
        color=TEXT,
    )
    add_text(
        slide,
        "三职业  ·  自由构筑  ·  探索式 Boss 战",
        0.88,
        4.04,
        6.2,
        0.36,
        size=12,
        color=TEXT_MUTED,
    )

    add_picture(slide, assets["hero"], 7.93, 1.20, 2.65, 2.65)
    add_picture(slide, assets["melee"], 10.32, 1.74, 1.10, 1.10)
    add_picture(slide, assets["sigil"], 10.02, 3.32, 2.28, 2.28)
    add_text(
        slide,
        "玩法与剧情介绍",
        0.88,
        5.71,
        4.0,
        0.3,
        size=12,
        color=GOLD,
        bold=True,
    )
    add_text(
        slide,
        "2026  /  GAME DESIGN PREVIEW",
        0.88,
        6.89,
        5.2,
        0.22,
        size=8,
        color=(135, 122, 102),
    )
    add_notes(
        slide,
        "开场：这是一部传统西幻风格的 2D 动作冒险游戏。玩家从边境村庄出发，"
        "选择职业，穿过自由探索的边境区域，最终面对赤冠之龙瓦洛斯。",
    )


def slide_world(prs, assets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_bg(slide, assets["deck"])
    add_header(slide, "01", "WORLD", "巨龙苏醒，誓约破碎", "一部明亮、直接的传统西幻动作冒险")

    add_panel(slide, 0.70, 1.97, 6.10, 4.70, fill=(31, 27, 21), border=GOLD_DARK)
    add_text(
        slide,
        "“人类曾与巨龙立誓。\n如今，旧约只剩灰烬。”",
        1.15,
        2.38,
        5.2,
        1.36,
        size=24,
        color=PARCHMENT,
        font=FONT_TITLE,
        bold=True,
        align=PP_ALIGN.CENTER,
        valign=MSO_ANCHOR.MIDDLE,
        line_spacing=1.20,
    )
    add_picture(slide, assets["divider"], 1.60, 3.87, 4.25, 0.53)
    add_text(
        slide,
        "玩家不是天选之子，而是一名刚取得资格的冒险者。",
        1.30,
        4.57,
        4.95,
        0.55,
        size=14,
        color=TEXT,
        align=PP_ALIGN.CENTER,
    )
    add_text(
        slide,
        "村庄  ·  公会  ·  古代遗迹  ·  龙焰荒原",
        1.23,
        5.39,
        5.05,
        0.34,
        size=10,
        color=GOLD,
        align=PP_ALIGN.CENTER,
    )

    cards = [
        ("王国", "艾尔德兰边境", "白鹿地区等待新的守护者", GOLD),
        ("威胁", "赤冠之龙 · 瓦洛斯", "封印衰弱，龙灾重新降临", RED),
        ("使命", "找回三座誓火", "击败巨龙，终结旧时代的誓约", EMBER),
    ]
    y = 1.98
    for label, title, desc, accent in cards:
        add_panel(slide, 7.12, y, 5.38, 1.34, fill=(34, 29, 22), border=(84, 65, 41))
        add_rect(slide, 7.20, y + 0.12, 0.07, 1.10, fill=accent, line=None)
        add_text(slide, label, 7.48, y + 0.17, 0.72, 0.25, size=9, color=accent, bold=True)
        add_text(
            slide,
            title,
            8.21,
            y + 0.12,
            3.95,
            0.42,
            size=17,
            color=PARCHMENT,
            font=FONT_TITLE,
            bold=True,
        )
        add_text(slide, desc, 8.25, y + 0.66, 3.84, 0.31, size=10.5, color=TEXT_MUTED)
        y += 1.56

    add_footer(slide, 2)
    add_notes(
        slide,
        "世界观：艾尔德兰王国与巨龙曾立下守护誓约。誓约破裂后，瓦洛斯即将苏醒。"
        "主角从边境村庄开始，目标不是统一天下，而是找到誓火石碑并终结龙灾。",
    )


def slide_story_flow(prs, assets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_bg(slide, assets["deck"])
    add_header(slide, "02", "STORY", "从村庄到龙巢", "一条始终清晰的主线，一次由玩家决定顺序的远征")

    nodes = [
        ("01", "灰杉村", "成为冒险者\n完成战斗教学", assets["hero"], GOLD),
        ("02", "白鹿镇", "加入公会\n接受龙灾委托", assets["shield"], TEAL),
        ("03", "三处边境", "自由选择探索顺序\n发现古代誓火", assets["elite"], GREEN),
        ("04", "誓火石碑", "确认龙骨山入口\n揭开旧誓约", assets["orb"], PURPLE),
        ("05", "龙骨山", "挑战赤冠之龙\n决定群岛未来", assets["sigil"], EMBER),
    ]
    start_x = 0.95
    step = 2.34
    add_line(slide, start_x + 0.42, 3.57, start_x + step * 4 + 0.42, 3.57, color=GOLD_DARK, width=2.2)
    for idx, (num, title, desc, icon, accent) in enumerate(nodes):
        x = start_x + idx * step
        circle = slide.shapes.add_shape(MSO_SHAPE.OVAL, Inches(x + 0.14), Inches(3.29), Inches(0.56), Inches(0.56))
        circle.fill.solid()
        circle.fill.fore_color.rgb = rgb((25, 22, 18))
        circle.line.color.rgb = rgb(accent)
        circle.line.width = Pt(2)
        add_text(
            slide,
            num,
            x + 0.14,
            3.29,
            0.56,
            0.56,
            size=9,
            color=GOLD_LIGHT,
            bold=True,
            align=PP_ALIGN.CENTER,
            valign=MSO_ANCHOR.MIDDLE,
            margin=0,
        )
        add_icon_card(slide, icon, x - 0.05, 1.78, 0.95, 1.15, accent)
        add_text(
            slide,
            title,
            x - 0.02,
            4.02,
            1.24,
            0.38,
            size=16,
            color=PARCHMENT,
            font=FONT_TITLE,
            bold=True,
            align=PP_ALIGN.CENTER,
        )
        add_text(
            slide,
            desc,
            x - 0.16,
            4.50,
            1.52,
            0.74,
            size=9.5,
            color=TEXT_MUTED,
            align=PP_ALIGN.CENTER,
            line_spacing=1.10,
        )

    add_panel(slide, 0.82, 5.72, 11.85, 0.86, fill=(31, 27, 21), border=(94, 71, 41))
    add_text(
        slide,
        "剧情始终指向最终目标。怎么练、打谁、先探索哪里，由玩家决定。",
        1.18,
        5.88,
        11.1,
        0.46,
        size=14,
        color=PARCHMENT,
        align=PP_ALIGN.CENTER,
        valign=MSO_ANCHOR.MIDDLE,
    )
    add_footer(slide, 3)
    add_notes(
        slide,
        "故事流：灰杉村完成序章，白鹿镇开启主线，三片边境可以自由探索。"
        "三座誓火石碑打开龙骨山，最终目标始终是击败瓦洛斯。",
    )


def slide_prologue(prs, assets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_bg(slide, assets["deck"])
    add_header(slide, "03", "PROLOGUE", "灰杉村的黎明", "10～15 分钟完成职业选择、装备领取与基础战斗教学")

    add_panel(slide, 0.70, 1.82, 4.80, 4.88, fill=(28, 29, 21), border=(98, 77, 43))
    add_text(
        slide,
        "VILLAGE  UNDER  ATTACK",
        0.93,
        2.02,
        2.45,
        0.24,
        size=8,
        color=RED,
        bold=True,
    )
    add_picture(slide, assets["warning"], 3.12, 2.42, 1.15, 1.15)
    add_picture(slide, assets["hero_alt"], 1.13, 2.55, 1.90, 1.90)
    add_picture(slide, assets["melee"], 3.37, 2.75, 1.30, 1.30)
    add_text(
        slide,
        "剧情导师  /  加雷斯爵士",
        0.98,
        4.65,
        2.60,
        0.26,
        size=9,
        color=GOLD,
        bold=True,
    )
    add_text(
        slide,
        "“那不是普通野兽。\n它只是赤冠之龙的眼睛和爪牙。”",
        0.98,
        5.04,
        3.92,
        0.96,
        size=13,
        color=PARCHMENT,
        font=FONT_TITLE,
        line_spacing=1.16,
    )

    steps = [
        ("01", "选择职业", "战士 · 游侠 · 法师"),
        ("02", "训练战斗", "左键 / 职业技能 / 武器特技"),
        ("03", "打开宝箱", "领取初始武器、护甲和药水"),
        ("04", "村庄遇袭", "两波翼蜥迫使玩家实战"),
        ("05", "击败裂翼兽", "完成序章，前往白鹿镇"),
    ]
    y = 1.88
    for i, (num, title, desc) in enumerate(steps):
        add_number_badge(slide, num, 6.04, y + 0.18, GOLD if i < 4 else EMBER)
        add_text(
            slide,
            title,
            6.68,
            y + 0.03,
            2.20,
            0.34,
            size=15,
            color=PARCHMENT,
            font=FONT_TITLE,
            bold=True,
        )
        add_text(slide, desc, 8.95, y + 0.04, 3.55, 0.32, size=10, color=TEXT_MUTED)
        if i < len(steps) - 1:
            add_line(slide, 6.25, y + 0.61, 6.25, y + 0.87, color=(86, 67, 42), width=1.2)
        y += 0.87

    add_footer(slide, 4)
    add_notes(
        slide,
        "序章不是纯教学关，而是完整的剧情事件。玩家选择职业、训练、开宝箱，"
        "随后村庄遭到翼蜥攻击。击败裂翼兽后，加雷斯指出巨龙已经苏醒，主角前往白鹿镇。",
    )


def slide_classes(prs, assets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_bg(slide, assets["deck"])
    add_header(slide, "04", "CLASSES", "三条战斗路线", "同一套操作规则，不同的距离、节奏与容错")

    classes = [
        {
            "name": "战士",
            "tag": "推荐新手",
            "accent": RED,
            "icon": assets["sword"],
            "role": "正面承伤 · 击退控制",
            "skill": "Z  破阵冲锋",
            "special": "右键  横斩",
            "desc": "利用冲锋打断敌人，争取近战输出空间。",
            "ch": "战",
        },
        {
            "name": "游侠",
            "tag": "灵活走位",
            "accent": GREEN,
            "icon": assets["arrow"],
            "role": "中距离 · 持续输出",
            "skill": "Z  战斗翻滚",
            "special": "右键  三连射",
            "desc": "保持安全距离，用翻滚穿过攻击，寻找连续射击机会。",
            "ch": "游",
        },
        {
            "name": "法师",
            "tag": "高爆发",
            "accent": PURPLE,
            "icon": assets["orb"],
            "role": "远程爆发 · 短距闪现",
            "skill": "Z  闪现",
            "special": "右键  蓄力火球",
            "desc": "用闪现调整位置，在安全距离完成高伤害蓄力。",
            "ch": "法",
        },
    ]
    x_positions = [0.72, 4.62, 8.52]
    for x, data in zip(x_positions, classes):
        add_panel(slide, x, 1.88, 3.62, 4.64, fill=(31, 27, 21), border=(88, 68, 42))
        add_rect(slide, x + 0.10, 1.98, 3.42, 0.08, fill=data["accent"], line=None)
        add_text(
            slide,
            data["ch"],
            x + 0.28,
            2.23,
            1.10,
            0.84,
            size=44,
            color=data["accent"],
            font=FONT_TITLE,
            bold=True,
            align=PP_ALIGN.CENTER,
        )
        add_text(
            slide,
            data["name"],
            x + 1.17,
            2.25,
            1.05,
            0.46,
            size=22,
            color=PARCHMENT,
            font=FONT_TITLE,
            bold=True,
        )
        add_text(slide, data["tag"], x + 2.23, 2.31, 1.00, 0.26, size=8, color=data["accent"], bold=True)
        add_picture(slide, data["icon"], x + 1.40, 2.88, 0.78, 0.78)
        add_text(
            slide,
            data["role"],
            x + 0.36,
            3.77,
            2.90,
            0.30,
            size=10,
            color=TEXT_MUTED,
            align=PP_ALIGN.CENTER,
        )
        add_rect(slide, x + 0.31, 4.17, 2.99, 0.52, fill=(43, 36, 27), line=(78, 61, 40), rounded=True, radius=0.12)
        add_text(slide, data["skill"], x + 0.38, 4.24, 2.84, 0.34, size=11, color=GOLD_LIGHT, bold=True, align=PP_ALIGN.CENTER)
        add_rect(slide, x + 0.31, 4.79, 2.99, 0.52, fill=(43, 36, 27), line=(78, 61, 40), rounded=True, radius=0.12)
        add_text(slide, data["special"], x + 0.38, 4.86, 2.84, 0.34, size=11, color=GOLD_LIGHT, bold=True, align=PP_ALIGN.CENTER)
        add_text(
            slide,
            data["desc"],
            x + 0.38,
            5.50,
            2.86,
            0.72,
            size=9.3,
            color=TEXT_MUTED,
            align=PP_ALIGN.CENTER,
            line_spacing=1.14,
        )

    add_text(
        slide,
        "职业在序章确定；到达白鹿镇后可以重新转职。",
        4.10,
        6.66,
        5.20,
        0.26,
        size=9.5,
        color=GOLD,
        align=PP_ALIGN.CENTER,
    )
    add_footer(slide, 5)
    add_notes(
        slide,
        "职业差异不是只改数值。战士用冲锋打断和控制，游侠用翻滚与连射，法师用闪现和蓄力爆发。"
        "三职业共用左键、右键和四个技能槽的基础规则。",
    )


def slide_combat(prs, assets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_bg(slide, assets["deck"])
    add_header(slide, "05", "COMBAT", "左键即战斗，右键有变化", "通用物品快捷栏 + 四技能槽，保持 HUD 简洁")

    add_panel(slide, 0.70, 1.82, 7.46, 4.94, fill=(25, 24, 20), border=GOLD_DARK)
    add_text(slide, "HUD  /  战斗界面示意", 1.03, 2.05, 2.75, 0.28, size=9, color=GOLD, bold=True)

    add_text(slide, "HP", 1.02, 2.53, 0.32, 0.22, size=8, color=TEXT_MUTED, bold=True)
    add_rect(slide, 1.39, 2.56, 4.72, 0.18, fill=(48, 24, 22), line=(90, 47, 38), rounded=True, radius=0.20)
    add_rect(slide, 1.39, 2.56, 3.47, 0.18, fill=RED, line=None, rounded=True, radius=0.20)
    add_text(slide, "86 / 120", 6.20, 2.49, 0.91, 0.25, size=9, color=PARCHMENT, bold=True, align=PP_ALIGN.RIGHT)
    add_text(slide, "防御 3", 1.03, 2.91, 0.76, 0.25, size=8, color=TEAL, bold=True)
    add_text(slide, "攻击 8", 2.02, 2.91, 0.76, 0.25, size=8, color=EMBER, bold=True)
    add_text(slide, "方向指示器", 3.05, 2.91, 0.92, 0.25, size=8, color=GOLD, bold=True)
    arrow = slide.shapes.add_shape(MSO_SHAPE.ISOSCELES_TRIANGLE, Inches(3.95), Inches(2.89), Inches(0.22), Inches(0.22))
    arrow.rotation = 90
    arrow.fill.solid()
    arrow.fill.fore_color.rgb = rgb(GOLD)
    arrow.line.fill.background()

    add_text(slide, "主动技能", 1.02, 3.42, 1.0, 0.26, size=9, color=TEXT_MUTED, bold=True)
    skill_keys = ["Z", "X", "C", "V"]
    for i, key in enumerate(skill_keys):
        sx = 1.04 + i * 1.02
        add_rect(slide, sx, 3.78, 0.74, 0.74, fill=(36, 31, 24), line=GOLD, line_width=1.3, rounded=True, radius=0.12)
        add_text(slide, key, sx, 3.83, 0.74, 0.24, size=9, color=GOLD_LIGHT, bold=True, align=PP_ALIGN.CENTER, margin=0)
        add_text(slide, ["职业技", "技能2", "技能3", "技能4"][i], sx - 0.02, 4.11, 0.78, 0.21, size=7, color=TEXT_MUTED, align=PP_ALIGN.CENTER, margin=0)

    add_text(slide, "物品快捷栏", 1.02, 4.82, 1.12, 0.26, size=9, color=TEXT_MUTED, bold=True)
    item_icons = [
        assets["sword"],
        assets["herb"],
        assets["shield"],
        assets["armor"],
        assets["arrow"],
        assets["gland"],
        assets["vine"],
        assets["orb"],
    ]
    for i in range(8):
        sx = 1.02 + i * 0.76
        add_rect(slide, sx, 5.18, 0.62, 0.73, fill=(34, 29, 23), line=(91, 70, 43), rounded=True, radius=0.10)
        add_picture(slide, item_icons[i], sx + 0.10, 5.22, 0.42, 0.42)
        add_text(slide, str(i + 1), sx + 0.43, 5.70, 0.10, 0.12, size=5.5, color=TEXT_MUTED, align=PP_ALIGN.RIGHT, margin=0)
        if i == 0:
            add_outline_rect(
                slide,
                sx - 0.03,
                5.15,
                0.68,
                0.79,
                line=GOLD_LIGHT,
                line_width=1.6,
                rounded=True,
                radius=0.10,
            )
    add_text(
        slide,
        "当前物品发光高亮",
        1.02,
        6.05,
        1.34,
        0.22,
        size=7.5,
        color=GOLD,
    )
    add_picture(slide, assets["hero"], 6.69, 2.91, 1.18, 1.18)

    labels = [
        ("鼠标左键", "武器普攻"),
        ("鼠标右键", "武器特技 / 使用物品"),
        ("Z / X / C / V", "四个主动技能"),
        ("1～8 / 滚轮", "选择快捷栏物品"),
        ("E", "角色 · 背包 · 技能"),
        ("F", "交互 / 拾取 / 开宝箱"),
        ("Esc", "系统设置 / 返回主菜单"),
    ]
    y = 1.95
    for i, (key, desc) in enumerate(labels):
        add_keycap(slide, key, 8.56, y, 1.47, 0.43, GOLD if i < 3 else (92, 130, 126))
        add_text(slide, desc, 10.19, y + 0.04, 2.30, 0.34, size=10.5, color=TEXT)
        y += 0.61

    add_panel(slide, 8.54, 6.33, 3.94, 0.42, fill=(31, 27, 21), border=(88, 68, 42), inner=False)
    add_text(
        slide,
        "背包不再常驻 HUD",
        8.76,
        6.39,
        3.50,
        0.22,
        size=9,
        color=GOLD_LIGHT,
        bold=True,
        align=PP_ALIGN.CENTER,
    )
    add_footer(slide, 6)
    add_notes(
        slide,
        "战斗输入统一为左键普攻、右键物品或武器特技，Z/X/C/V 是主动技能，1 到 8 选择快捷栏物品。"
        "E 打开角色和背包，F 交互，Esc 打开系统菜单。",
    )


def slide_exploration(prs, assets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_bg(slide, assets["deck"])
    add_header(slide, "06", "EXPLORATION", "Boss 可选，成长不断", "区域首领不是关卡钥匙，而是风险与回报的选择")

    bosses = [
        ("白桦林地", "裂牙格鲁姆", "范围击飞 · 高伤害", assets["melee"], GREEN, "通用技能：战吼"),
        ("失誓修道院", "失誓骑士罗兰", "突进 · 护盾 · 反击", assets["elite"], TEAL, "通用技能：铁壁"),
        ("赤烬海岸", "双首翼龙斯卡", "飞行 · 火焰 · 俯冲", assets["ranged"], EMBER, "通用技能：焰步"),
    ]
    x_positions = [0.72, 4.62, 8.52]
    for x, (region, name, combat, icon, accent, reward) in zip(x_positions, bosses):
        add_panel(slide, x, 1.86, 3.62, 4.02, fill=(31, 27, 21), border=(86, 67, 42))
        add_rect(slide, x + 0.10, 1.96, 0.08, 3.82, fill=accent, line=None)
        add_text(slide, region, x + 0.35, 2.09, 1.30, 0.25, size=8.5, color=accent, bold=True)
        add_picture(slide, icon, x + 0.92, 2.35, 1.55, 1.55)
        add_text(
            slide,
            name,
            x + 0.30,
            4.05,
            3.00,
            0.40,
            size=17,
            color=PARCHMENT,
            font=FONT_TITLE,
            bold=True,
            align=PP_ALIGN.CENTER,
        )
        add_text(slide, combat, x + 0.34, 4.54, 2.92, 0.32, size=10, color=TEXT_MUTED, align=PP_ALIGN.CENTER)
        add_rect(slide, x + 0.35, 5.08, 2.92, 0.48, fill=(44, 37, 28), line=(75, 58, 37), rounded=True, radius=0.12)
        add_text(slide, reward, x + 0.42, 5.15, 2.78, 0.28, size=9.5, color=GOLD_LIGHT, bold=True, align=PP_ALIGN.CENTER)
        add_text(
            slide,
            "Boss 可选",
            x + 2.62,
            2.09,
            0.72,
            0.23,
            size=7.5,
            color=(137, 123, 101),
            align=PP_ALIGN.RIGHT,
        )

    add_panel(slide, 0.82, 6.04, 11.86, 0.67, fill=(31, 27, 21), border=(103, 76, 43), inner=False)
    add_text(
        slide,
        "誓火石碑是主线线索；区域 Boss 提供技能与装备，不构成通关门槛。",
        1.12,
        6.18,
        11.27,
        0.34,
        size=12,
        color=PARCHMENT,
        bold=True,
        align=PP_ALIGN.CENTER,
    )
    add_footer(slide, 7)
    add_notes(
        slide,
        "三片区域都可以自由探索，三个区域 Boss 都提供不同的通用技能。"
        "但三座誓火石碑才是主线，玩家可以跳过所有区域 Boss 直接挑战瓦洛斯。",
    )


def slide_final(prs, assets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_bg(slide, assets["final"])
    add_header(slide, "07", "FINAL BOSS", "每一道预警，都有躲开的方式", "最终战按序章装备与职业技能也可通关的标准设计")

    phases = [
        (
            "第一阶段",
            "地面决战",
            ["爪击", "尾扫", "龙焰扇形喷射", "蓄力冲撞"],
            RED,
        ),
        (
            "第二阶段",
            "飞空压制",
            ["火焰落点", "连续喷火", "俯冲冲击", "场地边缘封锁"],
            EMBER,
        ),
    ]
    y = 1.91
    for tag, title, moves, accent in phases:
        add_panel(slide, 0.74, y, 5.14, 1.78, fill=(30, 26, 21), border=(88, 68, 42))
        add_text(slide, tag, 1.02, y + 0.18, 0.82, 0.26, size=9, color=accent, bold=True)
        add_text(
            slide,
            title,
            1.94,
            y + 0.10,
            2.95,
            0.43,
            size=20,
            color=PARCHMENT,
            font=FONT_TITLE,
            bold=True,
        )
        move_text = "   ·   ".join(moves)
        add_text(slide, move_text, 1.03, y + 0.75, 4.27, 0.65, size=10.2, color=TEXT_MUTED)
        y += 2.02

    add_panel(slide, 0.74, 6.06, 12.02, 0.63, fill=(31, 25, 21), border=(114, 73, 41), inner=False)
    add_text(
        slide,
        "操作可以弥补装备。没有必须刷满的 Boss，也没有强制的数值门槛。",
        1.08,
        6.20,
        11.31,
        0.31,
        size=12,
        color=GOLD_LIGHT,
        bold=True,
        align=PP_ALIGN.CENTER,
    )

    add_picture(slide, assets["sigil"], 8.78, 1.65, 3.66, 3.66)
    add_text(
        slide,
        "瓦洛斯",
        8.58,
        5.40,
        4.08,
        0.52,
        size=27,
        color=PARCHMENT,
        font=FONT_TITLE,
        bold=True,
        align=PP_ALIGN.CENTER,
    )
    add_text(
        slide,
        "赤 冠 之 龙",
        8.98,
        5.99,
        3.32,
        0.36,
        size=12,
        color=GOLD,
        bold=True,
        align=PP_ALIGN.CENTER,
    )
    add_footer(slide, 8, "序章  +  白鹿镇  +  自由边境  +  赤冠之龙最终战")
    add_notes(
        slide,
        "最终战分地面和飞空两个阶段，所有大招式都有明确预警。区域 Boss 提供更多解法，"
        "但不会成为强制门槛。整套体验的核心是让操作、职业和技能构筑决定战斗方式。",
    )


def build_deck():
    prepared = prepare_assets()
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    prs.core_properties.title = "勇者之旅：赤冠之龙 — 玩法与剧情介绍"
    prs.core_properties.subject = "游戏玩法与剧情介绍"
    prs.core_properties.author = "Codex"
    prs.core_properties.keywords = "勇者之旅, 赤冠之龙, Godot, 游戏设计, PPT"
    prs.core_properties.comments = "使用游戏内像素素材制作的视觉提案。"

    slide_cover(prs, prepared)
    slide_world(prs, prepared)
    slide_story_flow(prs, prepared)
    slide_prologue(prs, prepared)
    slide_classes(prs, prepared)
    slide_combat(prs, prepared)
    slide_exploration(prs, prepared)
    slide_final(prs, prepared)

    prs.save(OUT)
    print(OUT)
    print(f"slides={len(prs.slides)}")
    print(f"size={OUT.stat().st_size}")


if __name__ == "__main__":
    build_deck()
