"""Generate original, power-of-two RGBA TGA assets. No third-party dependencies."""
from pathlib import Path
import math
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "OrbsUI" / "Media"
SIZE = 256

def clamp(v):
    return max(0.0, min(1.0, v))

def pixel(name, x, y):
    phase = None
    if name.startswith("Sphere") and name != "Sphere":
        phase = (int(name[6:]) - 1) * math.tau / 64
        name = "Sphere"
    r = math.hypot(x, y)
    angle = math.atan2(y, x)
    edge = clamp((0.89 - r) * 128)
    z = math.sqrt(max(0, 1 - (r / 0.89) ** 2))
    if name == "OrbMask":
        return 1, 1, 1, edge
    if name == "Empty":
        return 0.045 + 0.025 * z, 0.04 + 0.02 * z, 0.042 + 0.02 * z, edge
    if name in ("Sphere", "Flat", "GradV", "GradH", "GradRadial"):
        if name == "Sphere":
            light = clamp(-0.3 * x - 0.48 * y + 0.72 * z)
            ribbon = math.sin(16 * y + 5 * math.sin(x * 5) + 3 * r) * 0.028
            if phase is not None:
                # Looping fluid ribbons with fixed sphere lighting and glass.
                ribbon = (math.sin(13 * y + 4 * math.sin(4 * x + phase) + 2 * r - phase) * 0.055
                          + math.sin(9 * x + 3 * math.sin(3 * y - phase) + phase) * 0.027) * z
            v = clamp(0.18 + 0.79 * light + ribbon)
        elif name == "GradV": v = clamp(0.35 + 0.65 * (1 - y) / 2)
        elif name == "GradH": v = clamp(0.3 + 0.7 * (x + 1) / 2)
        elif name == "GradRadial": v = clamp(0.24 + 0.76 * z ** 1.3)
        else: v = 0.85
        # Fill is rectangular; a mask anchored to the orb clips the native bar.
        return v, v, v, 1
    if name == "Gloss":
        shine = math.exp(-(((x + 0.3) / 0.28) ** 2 + ((y + 0.49) / 0.10) ** 2))
        arc = math.exp(-((r - 0.82) / 0.018) ** 2) * clamp(-x - y) * 0.25
        return 1, 0.97, 0.91, clamp(shine * 0.65 + arc) * edge
    if name == "RimShadow":
        return 0, 0, 0, clamp((r - 0.67) / 0.23) ** 2 * 0.7 * edge
    if name == "Swirl":
        v = (math.sin(14 * r + 4 * angle) + 1) / 2
        return 1, 1, 1, 0.1 * v ** 5 * edge
    if name in ("Bezel", "ThinBezel"):
        inner, outer = (0.89, 0.952) if name == "Bezel" else (0.89, 0.913)
        alpha = clamp((r - inner) * 220) * clamp((outer - r) * 220)
        ridge = math.sin((r - inner) / (outer - inner) * math.pi)
        light = clamp(0.55 - 0.35 * y - 0.20 * x)
        engraving = (0.85 + 0.15 * math.cos(angle * 64)) if name == "Bezel" else 1
        v = (0.24 + 0.65 * ridge) * light * engraving
        # Small cardinal ornaments retain a restrained Diablo-inspired silhouette.
        if name == "Bezel":
            ornament = clamp((0.027 - min(abs(x), abs(y))) * 120) * clamp((r - 0.86) * 160) * clamp((0.985 - r) * 160)
            alpha = max(alpha, ornament)
        return v * 1.1, v * 0.91, v * 0.61, alpha
    if name == "Glow":
        return 1, 1, 1, math.exp(-((r - 0.90) / 0.06) ** 2) * 0.7
    if name.startswith("SlotBorder") or name.startswith("SlotRing"):
        # Gold bevelled frame. A numbered variant is that many pixels thick on
        # the 38px slot button; the plain names keep the original widths.
        square = name.startswith("SlotBorder")
        digits = name[10:] if square else name[8:]
        width = int(digits) / 19 if digits else (0.21 if square else 0.18)
        inner = 0.98 - width
        d = max(abs(x), abs(y)) if square else r
        alpha = clamp((d - inner) * 80) * clamp((0.98 - d) * 80)
        light = 0.5 - 0.18 * y - 0.08 * x
        ridge = 0.55 + 0.45 * math.sin(clamp((d - inner) / width) * math.pi)
        return light * ridge, light * ridge * 0.82, light * ridge * 0.54, alpha
    if name == "SlotEmpty":
        plus = (abs(x) < 0.055 and abs(y) < 0.3) or (abs(y) < 0.055 and abs(x) < 0.3)
        return (0.45, 0.37, 0.24, 1) if plus else (0.055, 0.05, 0.045, 1)
    raise ValueError(name)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    names = ["OrbMask", "Empty", "Sphere", "Flat", "GradV", "GradH", "GradRadial",
             "Gloss", "RimShadow", "Swirl", "Bezel", "ThinBezel", "Glow", "SlotBorder", "SlotEmpty"]
    names += [f"Sphere{i:02d}" for i in range(1, 65)]
    names += [f"{frame}{n}" for frame in ("SlotBorder", "SlotRing") for n in range(1, 9)]
    if len(sys.argv) > 1: names = sys.argv[1:]
    for name in names:
        # Thickness variants are small on screen, so they ship at 128px.
        size = 128 if name[-1].isdigit() and name.startswith("Slot") else SIZE
        data = bytearray(struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 8))
        # Bottom-left origin, BGRA. Alpha has 8 bits; the game expects uncompressed TGA.
        for row in range(size):
            y = 1 - (row + 0.5) / size * 2
            for col in range(size):
                x = (col + 0.5) / size * 2 - 1
                r, g, b, a = pixel(name, x, y)
                data.extend(round(clamp(c) * 255) for c in (b, g, r, a))
        (OUT / (name + ".tga")).write_bytes(data)
    print(f"Generated {len(names)} textures in {OUT}")

if __name__ == "__main__":
    main()
