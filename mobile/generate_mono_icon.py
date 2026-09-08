#!/usr/bin/env python3
"""Generate monochrome Android adaptive icon (black on transparent, for themed icons)."""

from PIL import Image, ImageDraw
import math

SIZE = 432
BLACK = (0, 0, 0, 255)
TRANSPARENT = (0, 0, 0, 0)

def draw_monochrome_wave(size):
    img = Image.new('RGBA', (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    
    cx = size / 2
    cy = size / 2
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
            draw.line([points[j], points[j+1]], fill=BLACK, width=line_width)
    
    dot_cx = cx + safe * 0.12
    dot_cy = cy - safe * 0.15
    dot_r = max(2, round(size * 0.032))
    draw.ellipse(
        [dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
        fill=BLACK
    )
    
    return img

icon = draw_monochrome_wave(SIZE)
icon.save('/Users/dmarchant/workspaces/farm-red/stokedrift/mobile/android/app/src/main/res/drawable/ic_launcher_monochrome.png')
print(f"Monochrome icon: {icon.size}, colors: {len(set(icon.getdata()))}")