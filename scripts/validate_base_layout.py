#!/usr/bin/env python3
"""Validates design/config/base_layout.json: no two rectangles (HQ + slots +
defense_slots) overlap, and everything fits within grid_size. Run after any
manual edit to the layout file."""
import json
import sys
from pathlib import Path

LAYOUT_PATH = Path(__file__).resolve().parent.parent / "design" / "config" / "base_layout.json"


def bounds(rect: dict) -> tuple[int, int, int, int]:
    return rect["x"], rect["y"], rect["x"] + rect["size"], rect["y"] + rect["size"]


def main() -> int:
    data = json.loads(LAYOUT_PATH.read_text(encoding="utf-8"))
    grid_w = data["grid_size"]["w"]
    grid_h = data["grid_size"]["h"]

    rects = [dict(data["hq_slot"], id="hq")] + data["slots"] + data["defense_slots"]

    errors = []
    for r in rects:
        x0, y0, x1, y1 = bounds(r)
        if x0 < 0 or y0 < 0 or x1 > grid_w or y1 > grid_h:
            errors.append(f"{r['id']} out of bounds: {bounds(r)}")

    for i in range(len(rects)):
        for j in range(i + 1, len(rects)):
            a, b = rects[i], rects[j]
            ax0, ay0, ax1, ay1 = bounds(a)
            bx0, by0, bx1, by1 = bounds(b)
            if ax0 < bx1 and bx0 < ax1 and ay0 < by1 and by0 < ay1:
                errors.append(f"OVERLAP {a['id']} {bounds(a)} vs {b['id']} {bounds(b)}")

    if errors:
        for e in errors:
            print(e)
        print(f"TOTAL ERRORS: {len(errors)}")
        return 1

    print(f"OK: no overlaps, all within bounds - {len(rects)} rects total")
    return 0


if __name__ == "__main__":
    sys.exit(main())
