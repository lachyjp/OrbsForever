"""Compose a texture proof sheet from the shipped assets (requires Pillow)."""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "OrbsUI" / "Media"

def asset(name):
    return Image.open(MEDIA / (name + ".tga")).convert("RGBA")

def orb(style, color, level=1, bezel="Bezel", gloss=True):
    im = asset("Empty")
    fill = asset(style)
    tint = Image.new("RGBA", fill.size, (*color, 255))
    fill = ImageChops.multiply(fill, tint)
    mask = asset("OrbMask").getchannel("A")
    cut = Image.new("L", fill.size)
    ImageDraw.Draw(cut).rectangle((0, round(256 * (1 - level)), 256, 256), fill=255)
    fill.putalpha(ImageChops.multiply(mask, cut))
    im = Image.alpha_composite(im, fill)
    if style == "Sphere": im = Image.alpha_composite(im, asset("RimShadow"))
    if gloss: im = Image.alpha_composite(im, asset("Gloss"))
    if bezel: im = Image.alpha_composite(im, asset(bezel))
    return im

def font(size):
    return ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", size)

def orbfont(size):
    path = Path("C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/DialogueUI/Fonts/frizqt__.ttf")
    return ImageFont.truetype(str(path), size) if path.exists() else font(size)

out = Image.new("RGB", (1440, 1050), "#111211")
d = ImageDraw.Draw(out)
d.text((64, 42), "O R B S U I", font=font(38), fill="#ddbd80")
d.text((66, 99), "A quieter HUD. A little Sanctuary.", font=font(22), fill="#aaa69d")
d.text((66, 136), "Texture proof from the addon assets  /  In-game rendering still needs verification", font=font(16), fill="#777970")
for x, color, level, title, val in [(365, (255, 41, 51), .76, "HEALTH", "76%"), (817, (26, 110, 255), .58, "MANA", "58%")]:
    im = orb("Sphere", color, level).resize((280, 280), Image.Resampling.LANCZOS)
    out.paste(im, (x, 206), im)
    d.text((x + 141, 336), val, font=orbfont(28), fill="#111111", anchor="mm")
    d.text((x + 140, 335), val, font=orbfont(28), fill="#fff3db", anchor="mm")
    d.text((x + 140, 365), "760" if title == "HEALTH" else "580", font=orbfont(19), fill="#efd6b0", anchor="mm")
    d.text((x + 140, 501), title, font=orbfont(15), fill="#b8a985", anchor="mm")
    slot = asset("SlotEmpty").resize((44, 44))
    slot = Image.alpha_composite(slot, asset("SlotBorder").resize((44, 44)))
    sx = x + 290 if title == "HEALTH" else x - 58
    out.paste(slot, (sx, 365), slot)
    d.text((sx+22, 352), "1" if title == "HEALTH" else "2", font=font(14), fill="#cab384", anchor="mm")
d.line((66, 558, 1374, 558), fill="#373329")
d.text((66, 587), "FIVE SURFACES. YOUR PLACEMENT.", font=font(19), fill="#d6bd8d")
for i, (style, title) in enumerate([("Sphere", "Globe 3D"), ("GradV", "Vertical"), ("GradH", "Left to right"), ("GradRadial", "Centre"), ("Flat", "Flat")]):
    x = 65 + i * 267
    im = orb(style, (255, 41, 51), bezel="ThinBezel", gloss=style == "Sphere").resize((230, 230), Image.Resampling.LANCZOS)
    out.paste(im, (x, 650), im)
    d.text((x + 115, 912), title, font=font(19), fill="#bdb8ab", anchor="mm")
d.text((66, 993), "Dialogue font shown   /   Values beneath percentages   /   Damage flash + draining trail available in-game", font=font(18), fill="#898a7e")
out.save(ROOT / "preview.png")
print(ROOT / "preview.png")
