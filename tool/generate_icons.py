#!/usr/bin/env python3
"""Generate NetCarve branding PNGs with no third-party dependencies.

Draws the logo mark — a rounded square carved into four quadrants — as:
  assets/images/app_icon.png             (512, gradient background)
  assets/images/app_icon_foreground.png  (1024, transparent, adaptive safe zone)
  assets/images/splash_logo.png          (512, transparent)
  assets/images/play_icon_512.png        (512, Play Store listing icon)
"""
import math
import struct
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "images"
OUT.mkdir(parents=True, exist_ok=True)

BG = (0x0B, 0x11, 0x20)
ACCENT = (0x2D, 0xD4, 0xBF)
BLUE = (0x60, 0xA5, 0xFA)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def write_png(path, width, height, pixels):
    """pixels: list of rows, each row a list of (r,g,b,a) tuples."""
    raw = bytearray()
    for row in pixels:
        raw.append(0)  # filter type 0
        for r, g, b, a in row:
            raw += bytes((r, g, b, a))
    compressed = zlib.compress(bytes(raw), 9)

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data +
                struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) +
           chunk(b"IDAT", compressed) + chunk(b"IEND", b""))
    path.write_bytes(png)


def rounded_rect_alpha(x, y, x0, y0, x1, y1, radius):
    """Coverage 0..1 for a rounded rectangle at pixel centre (x,y)."""
    cx = min(max(x, x0 + radius), x1 - radius)
    cy = min(max(y, y0 + radius), y1 - radius)
    if x < x0 or x > x1 or y < y0 or y > y1:
        return 0.0
    dist = math.hypot(x - cx, y - cy)
    return _edge(radius - dist)


def _edge(d):
    """1px anti-aliased coverage from a signed distance."""
    if d >= 0.5:
        return 1.0
    if d <= -0.5:
        return 0.0
    return d + 0.5


def segment_coverage(x, y, ax, ay, bx, by, half_width):
    """Coverage of a thick line segment around pixel (x,y)."""
    vx, vy = bx - ax, by - ay
    wx, wy = x - ax, y - ay
    seg_len2 = vx * vx + vy * vy
    t = 0.0 if seg_len2 == 0 else max(0.0, min(1.0, (wx * vx + wy * vy) / seg_len2))
    px, py = ax + t * vx, ay + t * vy
    return _edge(half_width - math.hypot(x - px, y - py))


def render(size, with_background, scale=1.0, supersample=2):
    """Render the mark with supersampled anti-aliasing."""
    pixels = [[(0, 0, 0, 0)] * size for _ in range(size)]

    cx = cy = size / 2.0
    half = (size / 2.0) * 0.62 * scale
    x0, y0, x1, y1 = cx - half, cy - half, cx + half, cy + half
    corner = half * 0.32
    stroke = half * 0.15

    ss = supersample
    n = ss * ss
    for py in range(size):
        for px in range(size):
            acc_r = acc_g = acc_b = acc_a = 0.0
            for sy in range(ss):
                for sx in range(ss):
                    fx = px + (sx + 0.5) / ss
                    fy = py + (sy + 0.5) / ss
                    r, g, b, a = sample(fx, fy, cx, cy, x0, y0, x1, y1,
                                        corner, stroke, with_background, size)
                    acc_r += r * a
                    acc_g += g * a
                    acc_b += b * a
                    acc_a += a
            alpha = acc_a / n
            if alpha <= 0.0001:
                pixels[py][px] = (0, 0, 0, 0)
            else:
                pixels[py][px] = (
                    int(round(min(255.0, acc_r / acc_a))),
                    int(round(min(255.0, acc_g / acc_a))),
                    int(round(min(255.0, acc_b / acc_a))),
                    int(round(alpha * 255)),
                )
    return pixels


def sample(x, y, cx, cy, x0, y0, x1, y1, corner, stroke, bg, size):
    # Mark outline: draw the rounded rect, then subtract the inner fill so it
    # becomes a frame; then add the two carving lines.
    frame = rounded_rect_alpha(x, y, x0, y0, x1, y1, corner)
    inner = rounded_rect_alpha(
        x, y, x0 + stroke, y0 + stroke, x1 - stroke, y1 - stroke,
        max(corner - stroke, 0.2))
    frame = max(0.0, frame - inner)

    cap = stroke * 0.62
    vline = segment_coverage(x, y, cx, y0 + cap, cx, y1 - cap, cap)
    hline = segment_coverage(x, y, x0 + cap, cy, x1 - cap, cy, cap)
    mark = max(frame, vline * 0.9, hline * 0.9)

    # Gradient per-pixel from accent (top-left) to blue (bottom-right).
    t = max(0.0, min(1.0, ((x - x0) + (y - y0)) / (2 * (x1 - x0))))
    mark_rgb = lerp(ACCENT, BLUE, t)

    out = [0.0, 0.0, 0.0, 0.0]
    if bg:
        # Deep navy with a soft diagonal sheen.
        sheen = max(0.0, min(1.0, ((x) + (y)) / (2 * size)))
        bg_rgb = lerp(BG, (0x14, 0x1B, 0x2E), sheen * 0.9)
        out[0], out[1], out[2], out[3] = bg_rgb[0], bg_rgb[1], bg_rgb[2], 1.0

    # Composite the mark over the (optional) background.
    a = mark
    out[0] = out[0] * (1 - a) + mark_rgb[0] * a
    out[1] = out[1] * (1 - a) + mark_rgb[1] * a
    out[2] = out[2] * (1 - a) + mark_rgb[2] * a
    out[3] = out[3] * (1 - a) + a * 1.0
    return out[0], out[1], out[2], out[3]


def main():
    icon = render(512, with_background=True, scale=1.0, supersample=2)
    write_png(OUT / "app_icon.png", 512, 512, icon)
    write_png(OUT / "play_icon_512.png", 512, 512, icon)

    fg = render(1024, with_background=False, scale=0.72, supersample=2)
    write_png(OUT / "app_icon_foreground.png", 1024, 1024, fg)

    splash = render(512, with_background=False, scale=0.9, supersample=2)
    write_png(OUT / "splash_logo.png", 512, 512, splash)

    for name in ("app_icon.png", "app_icon_foreground.png",
                 "splash_logo.png", "play_icon_512.png"):
        p = OUT / name
        print(f"  {name}: {p.stat().st_size} bytes")


if __name__ == "__main__":
    main()
