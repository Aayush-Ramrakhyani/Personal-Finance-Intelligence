"""
Generates FinanceAI app icons:
  - icon.png           (1024x1024, solid background)
  - icon_foreground.png (1024x1024, transparent background for adaptive icon)
  - splash_logo.png    (512x512, transparent, centered for splash)
"""

import math
from PIL import Image, ImageDraw, ImageFilter

# --- Brand colours ---
BG          = (21,  25,  54)   # #151929
ACCENT      = (0,  200, 150)   # #00C896
ACCENT_DIM  = (0,  160, 120)   # darker accent for depth
WHITE       = (255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

SIZE = 1024


def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill)


def draw_chart_bars(draw, cx, cy, bar_w, gap, heights, color):
    """Draw a bar chart centred at (cx, cy)."""
    n = len(heights)
    total_w = n * bar_w + (n - 1) * gap
    x = cx - total_w // 2
    max_h = max(heights)
    for h in heights:
        bar_h = int(h)
        y0 = cy - bar_h // 2 + (max_h - bar_h) // 2
        y1 = y0 + bar_h
        r = bar_w // 4
        draw.rounded_rectangle([x, y0, x + bar_w, y1], radius=r, fill=color)
        x += bar_w + gap


def draw_upward_arrow(draw, cx, cy, size, color, width=14):
    """Draw a small upward arrow to the top-right of the bars."""
    pts = [
        (cx,          cy - size),
        (cx - size//2, cy),
        (cx - size//5, cy),
        (cx - size//5, cy + size),
        (cx + size//5, cy + size),
        (cx + size//5, cy),
        (cx + size//2, cy),
    ]
    draw.polygon(pts, fill=color)


def make_logo_layer(size, bg_color):
    """
    Returns an RGBA image with the FinanceAI logo drawn on it.
    bg_color=None → transparent background (for foreground layer).
    """
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    cx, cy = size // 2, size // 2
    pad = int(size * 0.12)

    # --- Background card (only if bg_color given) ---
    if bg_color:
        draw_rounded_rect(draw, [0, 0, size - 1, size - 1],
                          radius=int(size * 0.22), fill=bg_color + (255,))

    # --- Subtle inner glow ring ---
    ring_r = int(size * 0.36)
    ring_w = int(size * 0.018)
    draw.ellipse(
        [cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
        outline=ACCENT + (40,), width=ring_w
    )

    # --- Bar chart (3 bars, ascending) ---
    bar_w  = int(size * 0.09)
    gap    = int(size * 0.04)
    base_y = cy + int(size * 0.10)
    heights = [
        int(size * 0.20),
        int(size * 0.30),
        int(size * 0.42),
    ]
    bar_color = ACCENT + (255,)

    n = len(heights)
    total_w = n * bar_w + (n - 1) * gap
    x = cx - total_w // 2
    max_h = max(heights)
    for h in heights:
        y1 = base_y
        y0 = base_y - h
        r  = bar_w // 4
        draw.rounded_rectangle([x, y0, x + bar_w, y1], radius=r, fill=bar_color)
        x += bar_w + gap

    # --- Upward arrow attached to tallest (right) bar ---
    arrow_cx = cx + total_w // 2 - bar_w // 2
    arrow_cy = base_y - max_h - int(size * 0.06)
    a_size   = int(size * 0.065)
    pts = [
        (arrow_cx,                arrow_cy - a_size),
        (arrow_cx - a_size // 2,  arrow_cy),
        (arrow_cx - a_size // 5,  arrow_cy),
        (arrow_cx - a_size // 5,  arrow_cy + a_size * 0.8),
        (arrow_cx + a_size // 5,  arrow_cy + a_size * 0.8),
        (arrow_cx + a_size // 5,  arrow_cy),
        (arrow_cx + a_size // 2,  arrow_cy),
    ]
    pts = [(int(px), int(py)) for px, py in pts]
    draw.polygon(pts, fill=ACCENT + (255,))

    # --- "FA" text badge (top-left quadrant) ---
    badge_r = int(size * 0.10)
    badge_cx = cx - int(size * 0.20)
    badge_cy = cy - int(size * 0.22)
    draw.ellipse(
        [badge_cx - badge_r, badge_cy - badge_r,
         badge_cx + badge_r, badge_cy + badge_r],
        fill=ACCENT_DIM + (255,)
    )
    # Draw "F" and "A" manually with lines (no font needed)
    fs = int(badge_r * 0.65)
    lw = max(3, int(badge_r * 0.14))

    # "F"
    fx, fy = badge_cx - int(fs * 0.55), badge_cy - fs + int(fs * 0.1)
    draw.line([(fx, fy), (fx, fy + fs * 2)], fill=WHITE + (255,), width=lw)
    draw.line([(fx, fy), (fx + int(fs * 0.85), fy)], fill=WHITE + (255,), width=lw)
    draw.line([(fx, fy + fs), (fx + int(fs * 0.7), fy + fs)], fill=WHITE + (255,), width=lw)

    # "A"
    ax = badge_cx + int(fs * 0.15)
    at = fy
    ab = fy + fs * 2
    draw.line([(ax, ab), (ax + int(fs * 0.5), at)], fill=WHITE + (255,), width=lw)
    draw.line([(ax + int(fs * 0.5), at), (ax + fs, ab)], fill=WHITE + (255,), width=lw)
    mid_y = at + (ab - at) // 2
    draw.line([(ax + int(fs * 0.2), mid_y), (ax + int(fs * 0.8), mid_y)],
              fill=WHITE + (255,), width=lw)

    return img


# ── 1. icon.png (solid background) ─────────────────────────────────────────
logo = make_logo_layer(SIZE, BG)
out  = Image.new("RGB", (SIZE, SIZE), BG)
out.paste(logo, (0, 0), logo)
out.save("assets/images/icon.png", "PNG")
print("OK icon.png")

# ── 2. icon_foreground.png (transparent bg, adaptive icon foreground) ──────
fg = make_logo_layer(SIZE, None)
fg.save("assets/images/icon_foreground.png", "PNG")
print("OK icon_foreground.png")

# ── 3. splash_logo.png (512x512, transparent, just the graphic) ────────────
SPLASH = 512
splash = make_logo_layer(SPLASH, None)
splash.save("assets/images/splash_logo.png", "PNG")
print("OK splash_logo.png")

print("All icons generated successfully.")
