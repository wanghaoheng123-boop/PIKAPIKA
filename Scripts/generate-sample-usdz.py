#!/usr/bin/env python3
"""Build tiny USDZ sample packs (ZIP + root USDA) for PIKAPIKA bundle demos."""
from __future__ import annotations

import argparse
import zipfile
from pathlib import Path


def usda_tetra(stem: str, r: float, g: float, b: float, scale: float) -> str:
    s = scale
    return f"""#usda 1.0
(
    defaultPrim = "{stem}"
    metersPerUnit = 1
    upAxis = "Y"
)

def Xform "{stem}"
{{
    def Mesh "Body"
    {{
        int[] faceVertexCounts = [3, 3, 3, 3]
        int[] faceVertexIndices = [0, 1, 2, 0, 2, 3, 0, 3, 1, 1, 3, 2]
        point3f[] points = [
            (0, {0.35 * s:.4f}, 0),
            ({-0.3 * s:.4f}, {-0.2 * s:.4f}, {0.2 * s:.4f}),
            ({0.3 * s:.4f}, {-0.2 * s:.4f}, {0.2 * s:.4f}),
            (0, {-0.2 * s:.4f}, {-0.28 * s:.4f})
        ]
        color3f[] primvars:displayColor = [({r:.3f}, {g:.3f}, {b:.3f})]
        token primvars:displayColor:interpolation = "constant"
    }}
}}
"""


def write_usdz(out_path: Path, stem: str, body: str) -> None:
    inner = f"{stem}.usda"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    data = body.encode("utf-8")
    with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_STORED) as zf:
        zf.writestr(inner, data)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--out-dir", type=Path, required=True)
    args = p.parse_args()
    out: Path = args.out_dir
    specs = [
        ("PikaSampleCat", 0.95, 0.55, 0.12, 1.15),
        ("PikaSampleDog", 0.55, 0.32, 0.14, 1.35),
        ("PikaSampleSpark", 0.98, 0.92, 0.22, 1.0),
    ]
    for stem, r, g, b, sc in specs:
        write_usdz(out / f"{stem}.usdz", stem, usda_tetra(stem, r, g, b, sc))
    print("Wrote", len(specs), "USDZ files.")


if __name__ == "__main__":
    main()
