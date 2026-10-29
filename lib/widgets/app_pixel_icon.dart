import 'package:flutter/material.dart';

/// Shared pixel icons so navigation, settings, and reader chrome
/// match the home category marks.
enum AppGlyph {
  home,
  people,
  gear,
  sparkle,
  crown,
  globe,
  style,
  palette,
  text,
  page,
  info,
  chevronLeft,
  chevronRight,
  lock,
  share,
  menu,
  search,
  close,
  add,
  check,
  play,
  qr,
}

class AppPixelIcon extends StatelessWidget {
  const AppPixelIcon(
    this.glyph, {
    super.key,
    this.size = 22,
    this.color = const Color(0xFF6E675F),
  });

  final AppGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AppPixelPainter(rows: _rows[glyph]!, color: color),
    );
  }
}

const _rows = <AppGlyph, List<String>>{
  AppGlyph.home: [
    '...####.....',
    '..######....',
    '.########...',
    '##########..',
    '....##......',
    '....##......',
    '..######....',
    '..#....#....',
    '..#....#....',
    '..######....',
  ],
  AppGlyph.people: [
    '.#......#...',
    '###....###..',
    '.#......#...',
    '###....###..',
    '#.#....#.#..',
    '#.#....#.#..',
  ],
  AppGlyph.gear: [
    '....##......',
    '..######....',
    '.#.####.#...',
    '.########...',
    '.########...',
    '.#.####.#...',
    '..######....',
    '....##......',
  ],
  AppGlyph.sparkle: [
    '.....#......',
    '....###.....',
    '...#.#.#....',
    '.#########..',
    '...#.#.#....',
    '....###.....',
    '.....#......',
  ],
  AppGlyph.crown: [
    '#..#..#..#..',
    '##.##.##.##.',
    '.##########.',
    '..########..',
    '...######...',
  ],
  AppGlyph.globe: [
    '...####.....',
    '..#.#..#....',
    '.#...#...#..',
    '.#########..',
    '.#...#...#..',
    '..#.#..#....',
    '...####.....',
  ],
  AppGlyph.style: [
    '..######....',
    '.#..##..#...',
    '.########...',
    '..######....',
    '..#....#....',
    '..######....',
  ],
  AppGlyph.palette: [
    '..##..##....',
    '..##..##....',
    '....##..##..',
    '....##..##..',
    '..##....##..',
    '..##....##..',
  ],
  AppGlyph.text: [
    '..######....',
    '..#....#....',
    '..######....',
    '..#....#....',
    '..#....#....',
  ],
  AppGlyph.page: [
    '..######....',
    '..#....##...',
    '..#....#.#..',
    '..#....#....',
    '..#....#....',
    '..######....',
  ],
  AppGlyph.info: [
    '....##......',
    '....##......',
    '............',
    '....##......',
    '....##......',
    '....##......',
    '....##......',
  ],
  AppGlyph.chevronRight: [
    '..##........',
    '...##.......',
    '....##......',
    '.....##.....',
    '....##......',
    '...##.......',
    '..##........',
  ],
  AppGlyph.chevronLeft: [
    '......##....',
    '.....##.....',
    '....##......',
    '...##.......',
    '....##......',
    '.....##.....',
    '......##....',
  ],
  AppGlyph.lock: [
    '...####.....',
    '..#....#....',
    '..#....#....',
    '.########...',
    '.#..##..#...',
    '.#..##..#...',
    '.########...',
  ],
  AppGlyph.share: [
    '.....#......',
    '....###.....',
    '...#.#.#....',
    '.....#......',
    '.....#......',
    '..#######...',
    '..#.....#...',
    '..#######...',
  ],
  AppGlyph.menu: [
    '.########...',
    '............',
    '.########...',
    '............',
    '.########...',
  ],
  AppGlyph.search: [
    '...####.....',
    '..#....#....',
    '.#......#...',
    '..#....#....',
    '...####.....',
    '......#.....',
    '.......##...',
  ],
  AppGlyph.close: [
    '.##.....##..',
    '..##...##...',
    '...##.##....',
    '....###.....',
    '...##.##....',
    '..##...##...',
    '.##.....##..',
  ],
  AppGlyph.add: [
    '....##......',
    '....##......',
    '....##......',
    '.########...',
    '....##......',
    '....##......',
    '....##......',
  ],
  AppGlyph.check: [
    '.........#..',
    '........##..',
    '.##....##...',
    '..##..##....',
    '...####.....',
    '....##......',
  ],
  AppGlyph.play: [
    '...#........',
    '...###......',
    '...#####....',
    '...###......',
    '...#........',
  ],
  AppGlyph.qr: [
    '###.....###.',
    '#.#.....#.#.',
    '###.....###.',
    '............',
    '....##......',
    '...#..#.....',
    '..######....',
    '............',
    '###.....###.',
    '#.#.....#.#.',
    '###.....###.',
  ],
};

class _AppPixelPainter extends CustomPainter {
  _AppPixelPainter({required this.rows, required this.color});

  final List<String> rows;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) return;
    final height = rows.length;
    final width = rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
    final unit = size.shortestSide / (width > height ? width : height);
    final ox = (size.width - width * unit) / 2;
    final oy = (size.height - height * unit) / 2;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (var y = 0; y < height; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        if (row[x] == '.') continue;
        canvas.drawRect(
          Rect.fromLTWH(ox + x * unit, oy + y * unit, unit + 0.08, unit + 0.08),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AppPixelPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.rows != rows;
  }
}
