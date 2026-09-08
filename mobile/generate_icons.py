#!/usr/bin/env python3
"""Generate flat one-color app icons for stokesdrift.

The icon is the brand wave motif with a location pin dot,
drawn in a single flat color (tertiary #FF7A5C) on a 
surface (#F3FAF7) background.

Required sizes:
- iOS: 20, 29, 40, 60, 76, 83.5, 1024 (with @1x/@2x/@3x variants)
- Android: 48, 72, 96, 144, 192
"""

from PIL import Image, ImageDraw
import math
import os

# Brand colors
TERTIARY = (255, 122, 92)    # #FF7A5C
SURFACE  = (243, 250, 247)   # #F3FAF7

ICON_DIR = "/Users/dmarchant/workspaces/farm-red/stokedrift/mobile/assets"
IOS_DIR  = "/Users/dmarchant/workspaces/farm-red/stokedrift/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_DIRS = {
    "mdpi":    "/Users/dmarchant/workspaces/farm-red/stokedrift/mobile/android/app/src/main/res/mipmap-mdpi",
    "hdpi":    "/Users/dmarchant/workspaces/farm-red/stokedrift/mobile/android/app/src/main/res/mipmap-hdpi",
    "xhdpi":   "/Users/dmarchant/workspaces/farm-red/stokedrift/mobile/android/app/src/main/res/mipmap-xhdpi",
    "xxhdpi":  "/Users/dmarchant/workspaces/farm-red/stokedrift/mobile/android/app/src/main/res/mipmap-xxhdpi",
    "xxxhdpi": "/Users/dmarchant/workspaces/farm-red/stokedrift/mobile/android/app/src/main/res/mipmap-xxxhdpi",
}

ANDROID_SIZES = {
    "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192
}

def draw_wave_icon(size):
    """Draw the stokesdrift wave+dot icon at the given pixel size."""
    img = Image.new('RGBA', (size, size), SURFACE + (255,))
    draw = ImageDraw.Draw(img)
    
    cx = size / 2
    cy = size / 2
    
    # Scale parameters relative to icon size
    wave_amp = size * 0.06
    wave_len = size * 0.35
    line_width = max(2, round(size * 0.035))
    
    # Draw three wave lines
    for i in range(3):
        y_offset = cy + (i - 1) * wave_amp * 3.5
        phase = i * 0.8  # phase offset per line
        
        points = []
        for px in range(size):
            x = (px - cx) / wave_len
            y = y_offset + math.sin(x * math.pi * 2 + phase) * wave_amp
            points.append((px, y))
        
        for j in range(len(points) - 1):
            draw.line([points[j], points[j+1]], fill=TERTIARY + (255,), width=line_width)
    
    # Draw location dot (upper right of wave group)
    dot_cx = cx + size * 0.15
    dot_cy = cy - size * 0.18
    dot_r = max(2, round(size * 0.04))
    draw.ellipse(
        [dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
        fill=TERTIARY + (255,)
    )
    
    return img


def draw_android_foreground(size):
    """Draw the foreground layer for Android adaptive icon (just the symbol, no background)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx = size / 2
    cy = size / 2
    
    # Android adaptive icon safe zone is 72% of the total size (center 72%)
    # So we scale the icon content to fit in that zone
    safe = size * 0.72
    
    wave_amp = safe * 0.05
    wave_len = safe * 0.30
    line_width = max(2, round(size * 0.028))
    
    for i in range(3):
        y_offset = cy + (i - 1) * wave_amp * 3.5
        phase = i * 0.8
        
        points = []
        for px in range(size):
            x = (px - cx) / wave_len
            y = y_offset + math.sin(x * math.pi * 2 + phase) * wave_amp
            points.append((px, y))
        
        for j in range(len(points) - 1):
            draw.line([points[j], points[j+1]], fill=TERTIARY + (255,), width=line_width)
    
    dot_cx = cx + safe * 0.12
    dot_cy = cy - safe * 0.15
    dot_r = max(2, round(size * 0.032))
    draw.ellipse(
        [dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
        fill=TERTIARY + (255,)
    )
    
    return img


def draw_android_background(size):
    """Draw the background layer for Android adaptive icon (solid surface color)."""
    return Image.new('RGBA', (size, size), SURFACE + (255,))


# ── Generate main icon ──────────────────────────────────────────────────────

# 1024x1024 master icon
icon_1024 = draw_wave_icon(1024)
icon_1024.save(os.path.join(ICON_DIR, "icon.png"))
print("✓ assets/icon.png (1024x1024)")

# favicon
favicon = draw_wave_icon(32)
favicon.save(os.path.join(ICON_DIR, "favicon.png"))
print("✓ assets/favicon.png (32x32)")

# ── Generate iOS icons ──────────────────────────────────────────────────────

ios_sizes = [
    ("Icon-App-20x20@1x", 20),
    ("Icon-App-20x20@2x", 40),
    ("Icon-App-20x20@3x", 60),
    ("Icon-App-29x29@1x", 29),
    ("Icon-App-29x29@2x", 58),
    ("Icon-App-29x29@3x", 87),
    ("Icon-App-40x40@1x", 40),
    ("Icon-App-40x40@2x", 80),
    ("Icon-App-40x40@3x", 120),
    ("Icon-App-60x60@2x", 120),
    ("Icon-App-60x60@3x", 180),
    ("Icon-App-76x76@1x", 76),
    ("Icon-App-76x76@2x", 152),
    ("Icon-App-83.5x83.5@2x", 167),
    ("Icon-App-1024x1024@1x", 1024),
]

for name, px in ios_sizes:
    icon = draw_wave_icon(px)
    icon.save(os.path.join(IOS_DIR, f"{name}.png"))
    print(f"✓ iOS {name}.png ({px}x{px})")

# ── Generate Android icons ──────────────────────────────────────────────────

for density, px in ANDROID_SIZES.items():
    icon = draw_wave_icon(px)
    d = ANDROID_DIRS[density]
    os.makedirs(d, exist_ok=True)
    icon.save(os.path.join(d, "ic_launcher.png"))
    print(f"✓ Android {density} ic_launcher.png ({px}x{px})")

# ── Generate Android adaptive icon layers ─────────────────────────────────────

for density, px in ANDROID_SIZES.items():
    fg = draw_android_foreground(px)
    bg = draw_android_background(px)
    d = ANDROID_DIRS[density]
    fg.save(os.path.join(d, "ic_launcher_foreground.png"))
    bg.save(os.path.join(d, "ic_launcher_background.png"))
    print(f"✓ Android {density} adaptive icon layers ({px}x{px})")

print("\nDone! All icons generated.")