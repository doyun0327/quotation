#!/usr/bin/env python3
"""Portable port of remove_background.swift (needs only Pillow).

Fake/solid background -> transparent. Flood-fills from the image border, so
the character outline protects colours inside it.

  python tool/character_art/remove_background.py in.png out.png 30 1 8   # fake checkerboard
  python tool/character_art/remove_background.py in.png out.png 18 0     # solid black

Arguments: tolerance, pockets (1 also clears enclosed checkerboard patches,
e.g. between the legs; use 0 when the character has grey checks or plaid),
optional neutralMaxSpread (only near-grey pixels count as background).
"""
import sys
from collections import deque

from PIL import Image


def main(src, dst, tol=30, pockets=False, neutral=-1):
    img = Image.open(src).convert('RGBA')
    w, h = img.size
    px = img.load()
    rgb = [px[x, y][:3] for y in range(h) for x in range(w)]

    # Background colour clusters from the border.
    buckets = {}
    border = [x for x in range(w)] + [(h - 1) * w + x for x in range(w)]
    border += [y * w for y in range(h)] + [y * w + w - 1 for y in range(h)]
    for p in border:
        r, g, b = rgb[p]
        k = (r // 24, g // 24, b // 24)
        s = buckets.get(k, [0, 0, 0, 0])
        buckets[k] = [s[0] + r, s[1] + g, s[2] + b, s[3] + 1]
    nb = len(border)
    centers = [(s[0] // s[3], s[1] // s[3], s[2] // s[3])
               for s in buckets.values() if s[3] * 100 // nb >= 8]

    def dist(c, k):
        return max(abs(c[0] - k[0]), abs(c[1] - k[1]), abs(c[2] - k[2]))

    def is_bg(p):
        c = rgb[p]
        if neutral >= 0 and max(c) - min(c) > neutral:
            return False
        return any(dist(c, k) <= tol for k in centers)

    bg = [is_bg(p) for p in range(w * h)]

    def neighbours(p):
        x, y = p % w, p // w
        if x > 0:
            yield p - 1
        if x < w - 1:
            yield p + 1
        if y > 0:
            yield p - w
        if y < h - 1:
            yield p + w

    removed = bytearray(w * h)
    queue = deque()
    for p in border:
        if bg[p] and not removed[p]:
            removed[p] = 1
            queue.append(p)
    while queue:
        p = queue.popleft()
        for q in neighbours(p):
            if bg[q] and not removed[q]:
                removed[q] = 1
                queue.append(q)

    pocket_count = 0
    if pockets and len(centers) >= 2:
        seen = bytearray(removed)
        for p0 in range(w * h):
            if seen[p0] or not bg[p0]:
                continue
            comp = [p0]
            seen[p0] = 1
            tones = [0] * len(centers)
            i = 0
            while i < len(comp):
                p = comp[i]
                i += 1
                c = rgb[p]
                tones[min(range(len(centers)), key=lambda k: dist(c, centers[k]))] += 1
                for q in neighbours(p):
                    if not seen[q] and bg[q]:
                        seen[q] = 1
                        comp.append(q)
            tones.sort(reverse=True)
            if len(comp) > 200 and tones[1] * 100 // len(comp) >= 20:
                for p in comp:
                    removed[p] = 1
                pocket_count += 1

    # Edge cleanup: neutral, light-ish pixels touching removed background.
    loose = tol + 25
    min_l = min((min(c) for c in centers), default=0) - 40
    for _ in range(3):
        add = []
        for p in range(w * h):
            if removed[p] or not any(removed[q] for q in neighbours(p)):
                continue
            c = rgb[p]
            if (max(c) - min(c) <= 12 and min(c) >= min_l
                    and any(dist(c, k) <= loose for k in centers)):
                add.append(p)
        if not add:
            break
        for p in add:
            removed[p] = 1

    # Tiny opaque specks floating in the removed area.
    seen = bytearray(removed)
    for p0 in range(w * h):
        if seen[p0]:
            continue
        comp = [p0]
        seen[p0] = 1
        i = 0
        while i < len(comp):
            p = comp[i]
            i += 1
            for q in neighbours(p):
                if not seen[q]:
                    seen[q] = 1
                    comp.append(q)
        if len(comp) <= 60:
            for p in comp:
                removed[p] = 1

    n = 0
    for p in range(w * h):
        if removed[p]:
            px[p % w, p // w] = (0, 0, 0, 0)
            n += 1
    img.save(dst)
    print(f'{src}: centers {centers} removed {n * 100 // (w * h)}% pockets {pocket_count}')


if __name__ == '__main__':
    a = sys.argv
    main(a[1], a[2], int(a[3]) if len(a) > 3 else 30,
         len(a) > 4 and a[4] == '1', int(a[5]) if len(a) > 5 else -1)
