"""Render the square CurseForge logo from the shipped orb textures (requires Pillow).

One antique-gold orb, health red on the left and mana blue on the right, on a
dark warm backdrop. Writes logo.png (1024 px) and logo-400.png.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "OrbsUI" / "Media"
SIZE = 1024


def asset(name, size):
    return Image.open(MEDIA / (name + ".tga")).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)


def tinted(fill, color):
    return ImageChops.multiply(fill, Image.new("RGBA", fill.size, (*color, 255)))


def ring(size, inner_frac, outer_frac):
    """A crisp antique-gold rim drawn at full resolution."""
    ss = 2  # supersample for smooth edges
    n = size * ss
    c = n / 2
    im = Image.new("RGBA", (n, n))
    px = im.load()
    import math
    ro, ri = c * outer_frac, c * inner_frac
    for y in range(n):
        dy = y - c
        for x in range(n):
            dx = x - c
            r = math.hypot(dx, dy)
            if r > ro or r < ri:
                continue
            t = (r - ri) / (ro - ri)               # 0 inner edge .. 1 outer edge
            bevel = math.sin(t * math.pi)           # raised in the middle
            light = 0.5 - 0.5 * (dx + dy) / (r * 1.4142 + 1e-6)   # 1 at top-left, 0 at bottom-right
            # Bevel: the outer slope catches light from the top-left, the inner slope from the bottom-right.
            slope = light if t > 0.5 else 1 - light
            k = 0.28 + 0.72 * (0.45 * bevel + 0.55 * slope * bevel ** 0.5)
            # Thin dark grooves at both edges and along the middle.
            if t < 0.07 or t > 0.93: k *= 0.3
            elif abs(t - 0.5) < 0.035: k *= 0.6
            px[x, y] = (int(min(255, 236 * k + 20)), int(min(255, 186 * k + 12)), int(min(255, 104 * k + 6)), 255)
    return im.resize((size, size), Image.Resampling.LANCZOS)


def split_orb(size, level=0.82):
    import math
    base = asset("Empty", size)
    fill = asset("Sphere", size)
    red, blue = tinted(fill, (255, 41, 51)), tinted(fill, (26, 110, 255))
    mask = asset("OrbMask", size).getchannel("A")

    # Health on the left, mana on the right, divided by a gentle S-curve.
    seam = Image.new("L", (size, size))
    d = ImageDraw.Draw(seam)
    pts = [(0, 0)]
    for y in range(0, size + 1, 4):
        pts.append((size / 2 + size * 0.07 * math.sin((y / size) * 2 * math.pi), y))
    pts.append((0, size))
    d.polygon(pts, fill=255)
    seam = seam.filter(ImageFilter.GaussianBlur(size * 0.008))
    liquid = Image.composite(red, blue, seam)

    # Wavy liquid surface.
    top = size * (1 - level)
    cut = Image.new("L", (size, size))
    wave = [(x, top + size * 0.018 * math.sin(x / size * 3 * math.pi)) for x in range(0, size + 1, 4)]
    ImageDraw.Draw(cut).polygon(wave + [(size, size), (0, size)], fill=255)
    cut = cut.filter(ImageFilter.GaussianBlur(1.2))
    liquid.putalpha(ImageChops.multiply(mask, cut))
    im = Image.alpha_composite(base, liquid)

    surface = Image.new("RGBA", (size, size))
    ImageDraw.Draw(surface).line(wave, fill=(255, 236, 205, 110), width=max(2, size // 150))
    surface = surface.filter(ImageFilter.GaussianBlur(1))
    surface.putalpha(ImageChops.multiply(surface.getchannel("A"), mask))
    im = Image.alpha_composite(im, surface)
    for layer in ("RimShadow", "Gloss"):
        im = Image.alpha_composite(im, asset(layer, size))
    return Image.alpha_composite(im, ring(size, 0.862, 0.995))


def backdrop(size):
    # Dark warm radial vignette with a thin gold inner border.
    bg = Image.new("RGBA", (size, size), (14, 12, 10, 255))
    glow = Image.new("L", (size, size))
    r = size * 0.42
    ImageDraw.Draw(glow).ellipse((size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r), fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.12))
    bg = Image.composite(Image.new("RGBA", (size, size), (58, 44, 28, 255)), bg, glow)
    d = ImageDraw.Draw(bg)
    inset = round(size * 0.035)
    d.rectangle((inset, inset, size - inset - 1, size - inset - 1), outline=(150, 118, 70, 255), width=max(2, size // 220))
    return bg


def main():
    out = backdrop(SIZE)
    orb_size = round(SIZE * 0.86)
    # Soft shadow under the orb.
    shadow = Image.new("L", (SIZE, SIZE))
    pad = (SIZE - orb_size) / 2
    ImageDraw.Draw(shadow).ellipse((pad + SIZE * 0.03, pad + SIZE * 0.06, SIZE - pad + SIZE * 0.03, SIZE - pad + SIZE * 0.06), fill=170)
    shadow = shadow.filter(ImageFilter.GaussianBlur(SIZE * 0.03))
    out = Image.composite(Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 255)), out, shadow)
    orb = split_orb(orb_size)
    out.alpha_composite(orb, (round(pad), round(pad)))
    out = out.convert("RGB")
    out.save(ROOT / "logo.png")
    out.resize((400, 400), Image.Resampling.LANCZOS).save(ROOT / "logo-400.png")
    print(ROOT / "logo.png")


if __name__ == "__main__":
    main()
