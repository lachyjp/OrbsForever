"""Build a portable addon ZIP with one top-level OrbsUI folder."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
addon = ROOT / "OrbsUI"
toc_version = re.search(r"^## Version:\s*(\S+)", (addon / "OrbsUI.toc").read_text(), re.M).group(1)
core_version = re.search(r'O\.version = "([^"]+)"', (addon / "Core.lua").read_text()).group(1)
assert toc_version == core_version, f"TOC version {toc_version} != Core.lua version {core_version}"
dest = ROOT / "dist" / f"OrbsForever-{toc_version}.zip"
dest.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(addon.rglob("*")):
        if path.is_file(): archive.write(path, path.relative_to(ROOT))
with zipfile.ZipFile(dest) as archive:
    assert archive.testzip() is None
    assert "OrbsUI/OrbsUI.toc" in archive.namelist()
    assert "OrbsUI/Bindings.xml" in archive.namelist()
    assert "OrbsUI/INSTALL.txt" in archive.namelist()
    assert "OrbsUI/CHANGELOG.md" in archive.namelist()
    assert not any("SavedVariables" in name or name.endswith((".bak", ".py")) for name in archive.namelist())
    assert all(name.startswith("OrbsUI/") for name in archive.namelist())
    print(f"Verified {len(archive.namelist())} packaged files")
print(f"{dest} ({dest.stat().st_size:,} bytes)")
