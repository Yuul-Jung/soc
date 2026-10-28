#!/usr/bin/env python3
"""Convert verified SoC03 dark-theme Vitis GUI screenshots to a readable light palette.

This is pixel-only color conversion; do not regenerate or retype GUI content.
Original WebP screenshots are retained byte-for-byte in dark_originals/.
"""
from pathlib import Path
from hashlib import sha256
import io
import json
import shutil

import cv2
import numpy as np
from PIL import Image

ROOT = Path("MicroBlaze_V_SoC01_41/images/soc03")
BACKUP = ROOT / "dark_originals"
files = sorted(ROOT.glob("*.webp"))
assert len(files) == 22, f"Expected 22 verified originals, found {len(files)}"
BACKUP.mkdir(exist_ok=True)
records = []
converted = 0

def dark_fraction(rgb):
    sample = rgb[::8, ::8, :]
    return float((sample.astype(np.float32).mean(axis=2) < 85).mean())

for file in files:
    original_bytes = file.read_bytes()
    with Image.open(io.BytesIO(original_bytes)) as im:
        rgb = np.asarray(im.convert("RGB"))
        original_size = im.size
    before = dark_fraction(rgb)
    saved = BACKUP / file.name

    if saved.exists():
        # Safety: never recompute over a previously processed screenshot.
        # The preserved original remains authoritative.
        with Image.open(saved) as im:
            saved_dark = dark_fraction(np.asarray(im.convert("RGB")))
        assert saved_dark > 0.6, f"Unexpected non-dark backup: {saved}"
        assert before < 0.1, f"Converted file unexpectedly dark: {file}"
        records.append(dict(filename=file.name, mode="already-light", dark_before=saved_dark,
                            dark_after=before, original_sha256=sha256(saved.read_bytes()).hexdigest()))
        continue

    if before < 0.60:
        # First screenshot is Ubuntu's already-light file selection dialog.
        records.append(dict(filename=file.name, mode="already-light-original",
                            dark_before=before, dark_after=before,
                            original_sha256=sha256(original_bytes).hexdigest()))
        continue

    assert rgb.shape[0] >= 500 and rgb.shape[1] >= 900, file
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB).astype(np.float32)
    lab[:, :, 0] = np.clip(255.0 - 1.20 * np.maximum(lab[:, :, 0] - 25.0, 0.0),
                           0.0, 255.0)
    light = cv2.cvtColor(lab.astype(np.uint8), cv2.COLOR_LAB2RGB)
    after = dark_fraction(light)
    assert after < 0.08, f"Background did not become light: {file} ({after:.2%})"
    assert light.shape == rgb.shape
    BACKUP.joinpath(file.name).write_bytes(original_bytes)
    Image.fromarray(light).save(file, format="WEBP", quality=98, method=6)
    with Image.open(file) as verify:
        assert verify.size == original_size, f"Image dimensions changed: {file}"
        verify.load()
    converted += 1
    records.append(dict(filename=file.name, mode="converted", dark_before=before,
                        dark_after=after, original_sha256=sha256(original_bytes).hexdigest()))
    print(f"LIGHT {file.name}: dark pixels {before:.1%} -> {after:.1%}")

assert len(records) == 22
assert len(list(BACKUP.glob("*.webp"))) == 21, "All 21 dark original files must be preserved"
assert sum(x["mode"] in ("converted", "already-light") for x in records) == 21
report = {
    "method": "CIELAB luminance remapping with unchanged image dimensions; no text redrawing",
    "scope": "SoC03 Vitis 2024.2 screenshots",
    "images": records,
    "note": "Original dark-theme screenshots retained in images/soc03/dark_originals",
}
ROOT.joinpath("light_theme_manifest.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)
print(f"PASS: {len(records)} screenshots checked, {converted} changed, 21 dark originals preserved")
