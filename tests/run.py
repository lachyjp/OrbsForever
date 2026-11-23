"""Run with Python + lupa (Lua 5.1); no WoW installation needed."""
from pathlib import Path
import sys
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".test-deps"))
from lupa.lua51 import LuaRuntime

files = [line.strip() for line in (ROOT / "OrbsUI/OrbsUI.toc").read_text().splitlines()
         if line.strip() and not line.startswith("#")]
for modern in (False, True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().modern = modern
    lua.execute((ROOT / "tests/wow_mock.lua").read_text())
    for filename in files:
        source = (ROOT / "OrbsUI" / filename).read_text()
        lua.execute("assert(loadstring(...))(\"OrbsUI\", O)", source)
    count = lua.execute((ROOT / "tests/behaviour.lua").read_text())
    print(f"{'Modern' if modern else 'Legacy'} API: {count} behavioural checks passed (Lua 5.1)")
    extra = lua.execute((ROOT / "tests/features.lua").read_text())
    print(f"  {extra} stacked-value, font and damage-animation checks passed")
    layout_auto = lua.execute((ROOT / "tests/auto_layout.lua").read_text())
    print(f"  {layout_auto} label, padding and automatic-consumable checks passed")
    motion = lua.execute((ROOT / "tests/motion_ring.lua").read_text())
    print(f"  {motion} globe-animation and circular-placement checks passed")
    text_checks = lua.execute((ROOT / "tests/text_controls.lua").read_text())
    print(f"  {text_checks} combined-display, text-size, spacing and options-tab checks passed")
    colour_checks = lua.execute((ROOT / "tests/colours.lua").read_text())
    print(f"  {colour_checks} colour-picker, cancel and reset checks passed")
    edit_checks = lua.execute((ROOT / "tests/edit_mode.lua").read_text())
    print(f"  {edit_checks} Edit Mode unlock and per-layout position checks passed")
    heal_checks = lua.execute((ROOT / "tests/heals.lua").read_text())
    print(f"  {heal_checks} incoming-heal band checks passed (readable and secret values)")
    # Simulate a reload in a fresh runtime, retaining only the character DB.
    def serialize(value):
        if hasattr(value, "items"):
            return "{" + ",".join("[" + serialize(k) + "]=" + serialize(v) for k, v in value.items()) + "}"
        if isinstance(value, bool): return str(value).lower()
        if isinstance(value, str): return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'
        return str(value)
    saved = serialize(lua.globals().OrbsUIDB)
    reload = LuaRuntime()
    reload.execute((ROOT / "tests/wow_mock.lua").read_text())
    reload.execute("OrbsUIDB=" + saved)
    for filename in files:
        reload.execute("assert(loadstring(...))(\"OrbsUI\", O)", (ROOT / "OrbsUI" / filename).read_text())
    reload.execute('fire("ADDON_LOADED", "OrbsUI"); flush(); assert(O.db.size == 200); assert(O.db.scale == 1.4); assert(O.db.healthSlots == 2); assert(O.db.powerSlots == 3); assert(O.db.secondSlot == nil); assert(O.db.text == "combined"); assert(O.db.fontSize == 24); assert(O.db.valueFontSize == 20); assert(O.db.textOrder == "valueFirst"); assert(O.db.lineGap == 12); assert(O.db.separatorPadding == 3); assert(O.db.font == "dialogue"); assert(O.db.damageFlash); assert(O.db.animateDamage); assert(not O.db.healthLabel); assert(O.db.powerLabel); assert(O.db.slotDistance == -24); assert(O.db.slotGap == 42); assert(O.db.healthSlotAngle == 121); assert(O.db.powerSlotAngle == 225); assert(O.db.animateGlobe); assert(O.db.slotPosition == "Ring")')
    reload.execute('assert(O.db.customPowerColor); assert(O.db.powerColor[2] == 0.3); assert(O.orbs.power.bar.color[3] == 0.4)')
    print("  Saved settings survived simulated reload")
    for legacy, expected in (("true", 2), ("false", 1)):
        old = LuaRuntime()
        old.execute((ROOT / "tests/wow_mock.lua").read_text())
        old.execute("OrbsUIDB={secondSlot=" + legacy + "}")
        for filename in files:
            old.execute("assert(loadstring(...))(\"OrbsUI\", O)", (ROOT / "OrbsUI" / filename).read_text())
        old.execute('fire("ADDON_LOADED", "OrbsUI"); flush()')
        old.execute(f'assert(O.db.healthSlots == {expected} and O.db.powerSlots == {expected} and O.db.secondSlot == nil)')
    print("  1.0.x second-slot setting migrated to slot counts")

for path in (ROOT / "OrbsUI/Media").glob("*.tga"):
    data = path.read_bytes()
    width, height, depth, descriptor = struct.unpack_from("<HHBB", data, 12)
    assert (width, height, depth, descriptor) == (256, 256, 32, 8), path
    assert len(data) == 18 + width * height * 4, path
frames = [(ROOT / f"OrbsUI/Media/Sphere{i:02d}.tga").read_bytes()[18::4] for i in range(1, 65)]
assert len(set(frames)) == 64, "Animation frames must differ"
deltas = [sum(abs(a-b) for a, b in zip(frames[i], frames[(i+1) % 64])) / len(frames[i]) for i in range(64)]
assert max(deltas) < min(deltas) * 3, "Loop boundary should be as smooth as interior frames"
print("79 TGA assets: headers, dimensions, alpha, payloads and animation loop validated")
bindings = ET.parse(ROOT / "OrbsUI/Bindings.xml").getroot()
assert len(bindings) == 8
print("8 binding declarations: XML parsed")
