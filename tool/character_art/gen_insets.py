#!/usr/bin/env python3
"""Regenerate the _byFile table in lib/data/character_art_insets.dart.

Usage (from the repo root):
  swiftc -O tool/character_art/alpha_bounds.swift -o /tmp/alpha_bounds
  python3 tool/character_art/gen_insets.py
"""
import re
import subprocess

DART = 'lib/data/character_art_insets.dart'
ROOT = 'assets/images/character'


def rows(folder, prefix):
    out = subprocess.run(['/tmp/alpha_bounds', f'{ROOT}/{folder}'],
                         capture_output=True, text=True, check=True).stdout
    lines = []
    for line in out.splitlines():
        name, size, rest = line.split('\t')
        w, h = map(int, size.split('x'))
        left, right, top, bottom = [float(v) for v in re.findall(r'[\d.]+', rest)]
        lines.append(f"    '{prefix}{name}': CharacterArtInsets("
                     f"{w / h:.4f}, {left:.3f}, {right:.3f}, {top:.3f}, {bottom:.3f}),")
    return lines


src = open(DART).read()
start = src.index('  static const Map<String, CharacterArtInsets> _byFile = {')
end = src.index('  };', start) + len('  };')
table = (['  static const Map<String, CharacterArtInsets> _byFile = {',
          '    // woman/ (looked up by file name)']
         + rows('woman', '')
         + ["    // man/ (looked up as 'man/<file>'; some names repeat woman files)"]
         + rows('man', 'man/')
         + ['  };'])
open(DART, 'w').write(src[:start] + '\n'.join(table) + src[end:])
print('updated', DART)
