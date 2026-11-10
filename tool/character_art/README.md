# Character art tools

Run from the repo root. The Python tools work on any OS and need only
Pillow; the Swift originals need macOS.

**Margin table** — after adding or changing images in
`assets/images/character/{woman,man,christmas}`:

```sh
python3 tool/character_art/gen_insets.py
```

**Background removal on Windows/Linux** — same options as the Swift tool below:

```sh
python3 tool/character_art/remove_background.py in.png out.png 30 1 8   # fake checkerboard
python3 tool/character_art/remove_background.py in.png out.png 18 0     # solid black
```

**Fake/solid background → transparent** (flood-fills from the image border,
so the character outline protects colours inside it):

```sh
swiftc -O tool/character_art/remove_background.swift -o /tmp/rmbg
# rmbg <in> <out> <tolerance> <pockets 0|1> [neutralMaxSpread]
/tmp/rmbg in.png out.png 30 1 8   # fake checkerboard
/tmp/rmbg in.png out.png 18 0     # solid black
```

Use `pockets 0` when the character itself has grey checks/plaid. Always check
the result on a bright background before replacing the original.
