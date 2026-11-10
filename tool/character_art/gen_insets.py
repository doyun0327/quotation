#!/usr/bin/env python3
"""Regenerate the _byFile table in lib/data/character_art_insets.dart.

Usage (from the repo root, any OS, needs Pillow):
  python3 tool/character_art/gen_insets.py

Same rule as alpha_bounds.swift: a pixel counts as art when alpha > 24.
"""
import os

from PIL import Image

DART = 'lib/data/character_art_insets.dart'
ROOT = 'assets/images/character'


def bounds(path):
    img = Image.open(path).convert('RGBA')
    w, h = img.size
    box = img.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    if box is None:
        return w, h, 0.0, 0.0, 0.0, 0.0
    min_x, min_y, max_x, max_y = box[0], box[1], box[2] - 1, box[3] - 1
    return (w, h, min_x / w, (w - 1 - max_x) / w,
            min_y / h, (h - 1 - max_y) / h)


def rows(folder, prefix):
    lines = []
    for name in sorted(os.listdir(f'{ROOT}/{folder}')):
        if not name.lower().endswith('.png'):
            continue
        w, h, left, right, top, bottom = bounds(f'{ROOT}/{folder}/{name}')
        lines.append(f"    '{prefix}{name}': CharacterArtInsets("
                     f"{w / h:.4f}, {left:.3f}, {right:.3f}, {top:.3f}, {bottom:.3f}),")
    return lines


src = open(DART, encoding='utf-8').read()
start = src.index('  static const Map<String, CharacterArtInsets> _byFile = {')
end = src.index('  };', start) + len('  };')
table = (['  static const Map<String, CharacterArtInsets> _byFile = {',
          '    // woman/ (looked up by file name)']
         + rows('woman', '')
         + ["    // man/ (looked up as 'man/<file>'; some names repeat woman files)"]
         + rows('man', 'man/')
         + ["    // christmas/ pack (looked up as 'christmas/<file>')"]
         + rows('christmas', 'christmas/')
         + ["    // shareEvent/ reward (looked up as 'shareEvent/<file>')"]
         + rows('shareEvent', 'shareEvent/')
         + ['  };'])
open(DART, 'w', encoding='utf-8', newline='').write(src[:start] + '\n'.join(table) + src[end:])
print('updated', DART)
