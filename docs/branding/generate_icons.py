"""Regenerate every app icon from the master artwork.

Run from the repo root:  python3 docs/branding/generate_icons.py docs/branding/echat_app_icon_source.png . /tmp
then:                   dart run flutter_native_splash:create
"""
import sys, json
from PIL import Image, ImageDraw, ImageFilter
src_path, root = sys.argv[1], sys.argv[2]
R = lambda p: f"{root}/{p}"
src = Image.open(src_path).convert("RGB")
BOX = (95, 87, 1160, 1148)          # the rounded tile inside the artwork
tile = src.crop(BOX).resize((1024, 1024), Image.LANCZOS)   # square, full-bleed tile

def rounded(img, radius_frac=0.225):
    """Tile with transparent rounded corners (anti-aliased)."""
    n = img.size[0]; big = n * 4
    m = Image.new("L", (big, big), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, big - 1, big - 1), radius=int(big * radius_frac), fill=255)
    out = img.convert("RGBA"); out.putalpha(m.resize((n, n), Image.LANCZOS)); return out
icon = rounded(tile)

def save(img, path, size, rgb=False):
    im = img.resize((size, size), Image.LANCZOS)
    if rgb: im = im.convert("RGB")
    im.save(R(path), optimize=True)

def on_canvas(img, canvas, size, bg=(0, 0, 0, 0)):
    c = Image.new("RGBA", (canvas, canvas), bg)
    im = img.resize((size, size), Image.LANCZOS)
    c.alpha_composite(im, ((canvas - size) // 2, (canvas - size) // 2)); return c

# ---- in-app logo + brand master
save(icon, "assets/logo.png", 512)
save(src, "docs/branding/echat_app_icon.png", 1024, rgb=True)
save(icon, "assets/splash.png", 1024)

# ---- native splash sources (flutter_native_splash regenerates platform files)
for name in ("android12", "android12_dark"):
    on_canvas(icon, 1152, 600).save(R(f"assets/native_splash/{name}.png"), optimize=True)
for name in ("splash", "splash_dark"):
    on_canvas(icon, 1024, 520).save(R(f"assets/native_splash/{name}.png"), optimize=True)

# ---- iOS (opaque, square; iOS rounds it itself)
d = R("ios/Runner/Assets.xcassets/AppIcon.appiconset")
for img in json.load(open(f"{d}/Contents.json"))["images"]:
    pt = float(img["size"].split("x")[0]); sc = int(img["scale"][0])
    save(tile, f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{img['filename']}", round(pt * sc), rgb=True)

# ---- macOS
for s in (16, 32, 64, 128, 256, 512, 1024):
    save(on_canvas(icon, 1024, 824), f"macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{s}.png", s)

# ---- Android legacy launcher (pre-8.0)
dens = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
for k, f in dens.items():
    save(on_canvas(icon, 1024, 920), f"android/app/src/main/res/mipmap-{k}/ic_launcher.png", int(48 * f))

# ---- Android adaptive (8.0+): the artwork centred on the tile, scaled so the
# launcher's visible circle (72 of 108dp) shows the tile interior and the whole E.
bg = src.getpixel((0, 0))
N = 1680
fore = Image.new("RGBA", (N, N), (0, 0, 0, 0))
fore.paste(src, ((N - 1254) // 2, (N - 1254) // 2 + 10))
back = Image.new("RGBA", (N, N), bg + (255,))
for k, f in dens.items():
    save(fore, f"android/app/src/main/res/mipmap-{k}/ic_launcher_adaptive_fore.png", int(108 * f))
    save(back, f"android/app/src/main/res/mipmap-{k}/ic_launcher_adaptive_back.png", int(108 * f))
full = back.copy(); full.alpha_composite(fore)
full.convert("RGB").save(sys.argv[3] + "/adaptive_preview.png")

# ---- Web
save(icon, "web/favicon.png", 32)
save(icon, "web/icons/Icon-192.png", 192); save(icon, "web/icons/Icon-512.png", 512)
save(full, "web/icons/Icon-maskable-192.png", 192, rgb=True); save(full, "web/icons/Icon-maskable-512.png", 512, rgb=True)
