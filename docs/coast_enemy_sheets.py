from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[1]
FRONT = ROOT / "front_view_chibi"
OUT = ROOT / "graphics" / "enemies" / "coast"
OUT.mkdir(parents=True, exist_ok=True)

# kind: (source, frame, effect)
SPECS = {
    "ash_feather": ("ash_feather.png", 48, "feather"),
    "dragonfire_digger": ("dragonfire_digger.png", 56, "pick"),
    "slag_skink": ("slag_skink.png", 48, "bite"),
    "ferry_strangler": ("ferry_strangler.png", 56, "whip"),
    "gamehound": ("gamehound.png", 48, "bite"),
    "menhir_golem": ("menhir_golem.png", 64, "slam"),
    "lava_span_basilisk": ("lava_span_basilisk.png", 64, "fire"),
    "cinder_falcon": ("cinder_falcon.png", 64, "fire_feather"),
    "ska": ("lava_span_basilisk.png", 128, "breath"),
}


def load_trim(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    bbox = image.getbbox()
    if bbox:
        image = image.crop(bbox)
    return image


def tint(im: Image.Image, color: tuple[int, int, int], amount: float) -> Image.Image:
    overlay = Image.new("RGBA", im.size, color + (255,))
    overlay.putalpha(im.getchannel("A").point(lambda a: int(a * amount)))
    return Image.alpha_composite(im, overlay)


def make_eye_glow(im: Image.Image, cx: int, cy: int, r: int) -> None:
    d = ImageDraw.Draw(im)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 98, 18, 235))
    d.ellipse((cx - r // 2, cy - r // 2, cx + r // 2, cy + r // 2), fill=(255, 224, 120, 255))


def make_boss_base() -> Image.Image:
    base = load_trim(FRONT / "lava_span_basilisk.png")
    # 统一到 720 像素宽，方便手动标眼睛和画尖刺
    base.thumbnail((720, 720), Image.LANCZOS)
    w, h = base.size
    base = ImageEnhance.Brightness(base).enhance(0.82)
    base = ImageEnhance.Color(base).enhance(1.18)
    base = tint(base, (78, 20, 12), 0.18)

    d = ImageDraw.Draw(base)
    # 更大的头冠尖刺
    for (x, y, s) in [
        (w * 0.36, h * 0.20, 0.08), (w * 0.44, h * 0.15, 0.09),
        (w * 0.52, h * 0.17, 0.07), (w * 0.60, h * 0.22, 0.08),
    ]:
        spike = [
            (x - w * s * 0.55, y + h * s * 0.9),
            (x, y - h * s),
            (x + w * s * 0.45, y + h * s * 0.75),
        ]
        d.polygon(spike, fill=(34, 29, 27, 255))
        d.line((x, y - h * s * 0.8, x + w * s * 0.1, y + h * s * 0.4), fill=(92, 78, 63, 255), width=max(2, int(w * 0.004)))
    # 背脊上的大尖刺
    for (x, y, s) in [
        (w * 0.66, h * 0.27, 0.07), (w * 0.73, h * 0.31, 0.08),
        (w * 0.80, h * 0.37, 0.07), (w * 0.86, h * 0.43, 0.06),
    ]:
        d.polygon([(x - w * s * 0.5, y + h * s), (x, y - h * s * 1.1), (x + w * s * 0.5, y + h * s * 0.8)], fill=(30, 26, 25, 255))
    # 愤怒眉骨：压住眼睛上沿，形成明显的倒八字
    brow = (28, 22, 19, 255)
    d.line((w * 0.19, h * 0.35, w * 0.31, h * 0.39), fill=brow, width=max(7, int(w * 0.024)))
    d.line((w * 0.31, h * 0.39, w * 0.42, h * 0.345), fill=brow, width=max(7, int(w * 0.024)))
    d.line((w * 0.36, h * 0.355, w * 0.45, h * 0.40), fill=(20, 16, 14, 255), width=max(4, int(w * 0.012)))
    d.line((w * 0.06, h * 0.43, w * 0.15, h * 0.40), fill=brow, width=max(4, int(w * 0.012)))
    # 红眼：大眼和小眼，压暗眼白
    make_eye_glow(base, int(w * 0.33), int(h * 0.435), max(6, int(w * 0.030)))
    make_eye_glow(base, int(w * 0.12), int(h * 0.435), max(4, int(w * 0.016)))
    # 下压的嘴角和更大的尖牙
    d.line((w * 0.14, h * 0.585, w * 0.28, h * 0.615), fill=(30, 22, 18, 255), width=max(4, int(w * 0.010)))
    d.line((w * 0.28, h * 0.615, w * 0.43, h * 0.575), fill=(30, 22, 18, 255), width=max(4, int(w * 0.010)))
    for (x, y, s) in [
        (w * 0.20, h * 0.59, 0.032), (w * 0.29, h * 0.605, 0.038),
        (w * 0.37, h * 0.60, 0.030), (w * 0.44, h * 0.575, 0.022),
    ]:
        d.polygon([(x - w * s * 0.5, y), (x, y + h * s), (x + w * s * 0.5, y)], fill=(232, 221, 190, 255))
        d.polygon([(x - w * s * 0.5, y), (x, y + h * s * 0.55), (x + w * s * 0.35, y)], fill=(255, 255, 255, 255))
    # 口鼻部的余烬裂纹
    d.line((w * 0.18, h * 0.63, w * 0.30, h * 0.67), fill=(230, 78, 20, 255), width=max(2, int(w * 0.006)))
    d.line((w * 0.31, h * 0.67, w * 0.40, h * 0.63), fill=(255, 146, 48, 255), width=max(1, int(w * 0.004)))
    # 脸颊上的旧伤疤
    d.line((w * 0.24, h * 0.48, w * 0.30, h * 0.55), fill=(48, 30, 24, 200), width=max(3, int(w * 0.008)))
    d.line((w * 0.27, h * 0.48, w * 0.33, h * 0.54), fill=(48, 30, 24, 200), width=max(2, int(w * 0.005)))
    return base


def draw_effect(canvas: Image.Image, frame: int, side: int, effect: str) -> None:
    d = ImageDraw.Draw(canvas)
    cx = frame // 2 + side * int(frame * 0.24)
    cy = frame // 2 - int(frame * 0.03)
    unit = max(1, frame // 48)
    if effect == "fire":
        for i in range(4):
            x = cx + side * i * frame * 0.055
            y = cy + (i % 2) * frame * 0.02
            r = max(2, int(frame * (0.055 - i * 0.008)))
            d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 128, 28, 230))
            d.ellipse((x - r // 2, y - r // 2, x + r // 2, y + r // 2), fill=(255, 226, 130, 255))
    elif effect == "fire_feather":
        for i in range(5):
            x = cx + side * (i - 2) * frame * 0.055
            y = cy + math.sin(i * 1.7) * frame * 0.10
            r = max(2, int(frame * 0.035))
            d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 132, 36, 240))
            d.point((x, y), fill=(255, 240, 160, 255))
    elif effect == "feather":
        for i in range(3):
            x = cx + side * i * frame * 0.06
            y = cy + (i - 1) * frame * 0.05
            d.polygon([(x, y - frame * 0.03), (x + side * frame * 0.06, y), (x, y + frame * 0.03)], fill=(94, 106, 112, 230))
            d.point((x, y), fill=(170, 184, 190, 255))
    elif effect == "pick":
        d.arc((cx - frame * 0.18, cy - frame * 0.18, cx + frame * 0.18, cy + frame * 0.18),
              200 if side < 0 else -20, 340 if side < 0 else 160, fill=(255, 225, 170, 255), width=unit * 2)
        for i in range(3):
            d.point((cx + side * frame * (0.10 + i * 0.03), cy + (i - 1) * frame * 0.05), fill=(255, 166, 54, 255))
    elif effect == "bite":
        d.arc((cx - frame * 0.16, cy - frame * 0.16, cx + frame * 0.16, cy + frame * 0.16),
              210 if side < 0 else -30, 330 if side < 0 else 150, fill=(255, 236, 196, 255), width=unit * 2)
        for i in range(2):
            d.point((cx + side * frame * (0.08 + i * 0.04), cy), fill=(255, 122, 36, 255))
    elif effect == "whip":
        for i in range(3):
            pts = []
            for t in range(7):
                pts.append((cx + side * t * frame * 0.025, cy + math.sin(t * 0.9 + i) * frame * 0.035 + (i - 1) * frame * 0.02))
            d.line(pts, fill=(42, 92, 62, 235), width=unit * 2)
    elif effect == "slam":
        d.ellipse((cx - frame * 0.22, cy + frame * 0.14, cx + frame * 0.22, cy + frame * 0.26),
                  outline=(190, 176, 148, 220), width=unit * 2)
        for i in range(4):
            x = cx + side * (i - 1.5) * frame * 0.06
            d.ellipse((x - unit * 2, cy + frame * 0.12, x + unit * 2, cy + frame * 0.18), fill=(110, 98, 80, 200))
    elif effect == "breath":
        d.ellipse((cx - frame * 0.055, cy - frame * 0.05, cx + frame * 0.055, cy + frame * 0.05),
                  fill=(255, 150, 36, 255))
        for i in range(11):
            t = i / 10.0
            x = cx + side * (frame * 0.06 + t * frame * 0.34)
            y = cy + math.sin(i * 1.35) * frame * (0.045 + 0.03 * t)
            r = max(2, int(frame * (0.065 - 0.025 * t)))
            d.ellipse((x - r, y - r, x + r, y + r), fill=(208, 48, 14, 220))
            r2 = max(1, int(r * 0.62))
            d.ellipse((x - r2, y - r2, x + r2, y + r2), fill=(255, 132, 30, 245))
            if i % 2 == 0:
                r3 = max(1, int(r * 0.32))
                d.ellipse((x - r3, y - r3, x + r3, y + r3), fill=(255, 234, 140, 255))
        for i in range(5):
            x = cx + side * frame * (0.12 + i * 0.06)
            y = cy + math.sin(i * 2.2) * frame * 0.12
            r = max(1, frame // 42)
            d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 196, 84, 235))


def build_sheet(kind: str, source: str, frame: int, effect: str) -> None:
    base = make_boss_base() if kind == "ska" else load_trim(FRONT / source)
    pad = max(4, frame // 14)
    fit_box = frame - pad * 2
    base.thumbnail((fit_box, fit_box), Image.LANCZOS)
    sheet = Image.new("RGBA", (frame * 3, frame * 2), (0, 0, 0, 0))
    for row in range(2):
        side = -1 if row == 0 else 1
        for col in range(3):
            canvas = Image.new("RGBA", (frame, frame), (0, 0, 0, 0))
            image = base
            if row == 1:
                image = ImageOps.mirror(image)
            if col == 1:
                image = image.rotate(-2 if side < 0 else 2, resample=Image.NEAREST, expand=True)
                image.thumbnail((fit_box, fit_box), Image.NEAREST)
            elif col == 2:
                image = image.rotate(5 if side < 0 else -5, resample=Image.NEAREST, expand=True)
                image.thumbnail((int(fit_box * 1.04), int(fit_box * 1.04)), Image.NEAREST)
            x = (frame - image.width) // 2 + (side * 1 if col == 1 else 0)
            y = (frame - image.height) // 2 + (-1 if col == 1 else 0)
            canvas.alpha_composite(image, (x, y))
            if col == 2:
                draw_effect(canvas, frame, side, effect)
            sheet.alpha_composite(canvas, (col * frame, row * frame))
    sheet.save(OUT / f"{kind}_sheet.png")


for kind, (source, frame, effect) in SPECS.items():
    build_sheet(kind, source, frame, effect)
    print("sheet", kind, frame)

# 预览
preview = Image.new("RGBA", (5 * 300, 2 * 330), (28, 30, 34, 255))
pd = ImageDraw.Draw(preview)
for i, kind in enumerate(SPECS):
    sheet = Image.open(OUT / f"{kind}_sheet.png").convert("RGBA")
    max_w, max_h = 280, 270
    sheet.thumbnail((max_w, max_h), Image.LANCZOS)
    x = (i % 5) * 300
    y = (i // 5) * 330
    for yy in range(0, 300, 16):
        for xx in range(0, 300, 16):
            if (xx // 16 + yy // 16) % 2 == 0:
                pd.rectangle((x + xx, y + yy, x + xx + 15, y + yy + 15), fill=(40, 43, 49, 255))
    preview.alpha_composite(sheet, (x + (300 - sheet.width) // 2, y + (300 - sheet.height) // 2))
    pd.text((x + 8, y + 306), kind, fill=(238, 232, 216, 255))
preview.convert("RGB").save(OUT / "preview_coast_enemies.png")
print("preview written")
