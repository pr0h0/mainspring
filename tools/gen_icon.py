"""Draws the app icon (a brass wind-up key on a night-blue tile).

    python3 tools/gen_icon.py      -> icon.png, tools/web/icon-192.png, tools/web/icon-512.png
"""
import math

from PIL import Image, ImageDraw, ImageFilter

S = 512
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle([0, 0, S - 1, S - 1], radius=96, fill=(24, 22, 44, 255))
# Clock face behind the key.
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(glow).ellipse([96, 96, 416, 416], fill=(250, 220, 160, 120))
img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(28)))
d.ellipse([116, 116, 396, 396], fill=(245, 228, 190, 255), outline=(120, 90, 50, 255), width=8)
for k in range(12):
    a = k * math.tau / 12
    r1, r2 = 118, 104 if k % 3 else 92
    d.line([256 + math.sin(a) * r1, 256 - math.cos(a) * r1, 256 + math.sin(a) * r2, 256 - math.cos(a) * r2], fill=(90, 66, 40, 255), width=6)
# Hands at one minute to midnight.
d.line([256, 256, 256 - 10, 150], fill=(40, 30, 24, 255), width=12)
d.line([256, 256, 256 - 4, 132], fill=(40, 30, 24, 255), width=7)
# The key, brass, lying across the face.
brass, dark = (222, 168, 82, 255), (130, 90, 40, 255)
d.rounded_rectangle([238, 250, 274, 452], radius=14, fill=brass, outline=dark, width=5)
for cx in (196, 316):
    d.ellipse([cx - 62, 386, cx + 62, 486], fill=brass, outline=dark, width=6)
    d.ellipse([cx - 22, 420, cx + 22, 452], fill=(24, 22, 44, 255))
d.ellipse([234, 238, 278, 282], fill=dark)
img.save("icon.png")
for n in (192, 512):
    img.resize((n, n), Image.LANCZOS).save(f"tools/web/icon-{n}.png")
print("icon written")
