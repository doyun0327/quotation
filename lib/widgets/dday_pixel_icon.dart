import 'package:flutter/material.dart';

/// Selectable pixel icons for D-Day cards.
enum DdayIconKind {
  cake('cake'),
  plane('plane'),
  cat('cat'),
  dog('dog'),
  pen('pen'),
  notebook('notebook'),
  sport('sport'),
  medal('medal'),
  home('home'),
  baby('baby'),
  tree('tree'),
  star('star'),
  wine('wine'),
  heart('heart');

  const DdayIconKind(this.id);
  final String id;

  static const List<DdayIconKind> all = DdayIconKind.values;

  static DdayIconKind byId(String? id) {
    return DdayIconKind.values.firstWhere(
      (e) => e.id == id,
      orElse: () => DdayIconKind.heart,
    );
  }

  String labelKo() {
    return switch (this) {
      cake => '케이크',
      plane => '비행기',
      cat => '고양이',
      dog => '강아지',
      pen => '볼펜',
      notebook => '공책',
      sport => '운동',
      medal => '메달',
      home => '집',
      baby => '아기',
      tree => '나무',
      star => '별',
      wine => '와인',
      heart => '하트',
    };
  }
}

class DdayPixelIcon extends StatelessWidget {
  const DdayPixelIcon({
    super.key,
    required this.kind,
    this.size = 40,
  });

  final DdayIconKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelIconPainter(pixels: _pixelsFor(kind)),
      ),
    );
  }
}

/// 16x16 pixel art. `.` = transparent, letters map to palette colors.
List<String> _pixelsFor(DdayIconKind kind) {
  return switch (kind) {
    DdayIconKind.cake => const [
        '................',
        '......Y.P.Y.....',
        '......|.|.|.....',
        '....RRRRRRRR....',
        '...RWWWWWWWWR...',
        '...RWRWRWRWRR...',
        '...RWWWWWWWWR...',
        '..RRRRRRRRRRRR..',
        '.RCCCCCCCCCCCCR.',
        '.RCCCCCCCCCCCCR.',
        '.RCCCCCCCCCCCCR.',
        '..RRRRRRRRRRRR..',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.plane => const [
        '................',
        '..........W.....',
        '.........WW.....',
        '........WWW.....',
        '.......WWWW.....',
        '..BBBBWWWWWW....',
        '.BWWWWWWWWWWWB..',
        '..BBBBWWWWWW....',
        '.......WWWW.....',
        '........WWW.....',
        '.........WW.Y...',
        '..........W.....',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.cat => const [
        '................',
        '...O........O...',
        '..OOO......OOO..',
        '.OOOOOOOOOOOOOO.',
        '.OOYOOOOOOOYOOO.',
        '.OOOOOBBBOOOOOO.',
        '.OOOOOOOOOOOOOO.',
        '..OOOOOOOOOOOO..',
        '..OOOOPPPPOOOO..',
        '...OOOOOOOOOO...',
        '....OOOOOOOO....',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.dog => const [
        '................',
        '..KK........KK..',
        '.KKKK......KKKK.',
        '.KKKKKKKKKKKKKK.',
        '.KKYKKBKKBYKKKK.',
        '.KKKKKKKKKKKKKK.',
        '..KKKKPPKKKKKK..',
        '...KKKKKKKKKK...',
        '...KKKKKKKKKK...',
        '..KK..KKKK..KK..',
        '.KK....KK....KK.',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.pen => const [
        '................',
        '.............B..',
        '............BB..',
        '...........BB...',
        '..........BB....',
        '.........BB.....',
        '........BB......',
        '.......BB.......',
        '......YY........',
        '.....YY.........',
        '....KK..........',
        '...KK...........',
        '..K.............',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.notebook => const [
        '................',
        '..WWWWWWWWWWW...',
        '.WBWWWWWWWWWWB..',
        '.WBWWWWWWWWWWB..',
        '.WBWBBBBBBWWWB..',
        '.WBWWWWWWWWWWB..',
        '.WBWBBBBBBWWWB..',
        '.WBWWWWWWWWWWB..',
        '.WBWBBBBBBWWWB..',
        '.WBWWWWWWWWWWB..',
        '.WBBBBBBBBBBBB..',
        '..WWWWWWWWWWW...',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.sport => const [
        '................',
        '......OOOO......',
        '....OOYYYYOO....',
        '...OYYYYYYYYO...',
        '..OYYOOYYOOYYO..',
        '..OYYYYYYYYYYO..',
        '..OYYOOYYOOYYO..',
        '..OYYYYYYYYYYO..',
        '...OYYYYYYYYO...',
        '....OOYYYYOO....',
        '......OOOO......',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.medal => const [
        '................',
        '......R...R.....',
        '......RR.RR.....',
        '.......RRR......',
        '......YYYYY.....',
        '.....YYYYYYY....',
        '....YYYBYBYYY...',
        '....YYYYYYYYY...',
        '.....YYYYYYY....',
        '......YYYYY.....',
        '................',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.home => const [
        '................',
        '.......R........',
        '......RRR.......',
        '.....RRRRR......',
        '....RRRRRRR.....',
        '...RRRRRRRRR....',
        '..WWWWWWWWWWW...',
        '..WBBWWWWWBBW...',
        '..WBBWWWWWBBW...',
        '..WWWWWYYWWWW...',
        '..WWWWWYYWWWW...',
        '..WWWWWWWWWWW...',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.baby => const [
        '................',
        '.....PPPPPP.....',
        '....PPPPPPPP....',
        '...PPYPPPPYPP...',
        '...PPPPPPPPPP...',
        '....PPPOOPPP....',
        '.....PPPPPP.....',
        '......BBBB......',
        '.....BBBBBB.....',
        '....BBBBBBBB....',
        '....BB....BB....',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.tree => const [
        '................',
        '......GGG.......',
        '.....GGGGG......',
        '....GGGGGGG.....',
        '.....GGGGG......',
        '....GGGGGGG.....',
        '...GGGGGGGGG....',
        '....GGGGGGG.....',
        '......KKK.......',
        '......KKK.......',
        '......KKK.......',
        '.....KKKKK......',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.star => const [
        '................',
        '.......Y........',
        '......YYY.......',
        '.....YYYYY......',
        '..YYYYYYYYYYY...',
        '...YYYYYYYYY....',
        '....YYYYYYY.....',
        '....YY...YY.....',
        '...YY.....YY....',
        '..Y.........Y...',
        '................',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.wine => const [
        '................',
        '.....WWWWWW.....',
        '......W..W......',
        '......WRRW......',
        '......WRRW......',
        '.....WRRRRW.....',
        '.....WRRRRW.....',
        '......WRRW......',
        '.......WW.......',
        '.......KK.......',
        '......KKKK......',
        '.....KKKKKK.....',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.heart => const [
        '................',
        '...RRR....RRR...',
        '..RRRRR..RRRRR..',
        '.RRRRRRRRRRRRRR.',
        '.RRRRRRRRRRRRRR.',
        '..RRRRRRRRRRRR..',
        '...RRRRRRRRRR...',
        '....RRRRRRRR....',
        '.....RRRRRR.....',
        '......RRRR......',
        '.......RR.......',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
  };
}

Color? _colorFor(String ch) {
  return switch (ch) {
    'R' => const Color(0xFFE85A7A),
    'P' => const Color(0xFFFF8FB5),
    'Y' => const Color(0xFFFFD56A),
    'C' => const Color(0xFFFFC9A8),
    'W' => const Color(0xFFFFFFFF),
    'B' => const Color(0xFF5B8DEF),
    'O' => const Color(0xFFFFB26B),
    'K' => const Color(0xFF8B6B4A),
    'G' => const Color(0xFF5FBF6B),
    '|' => const Color(0xFFD0D5DE),
    '.' => null,
    _ => const Color(0xFF2C3340),
  };
}

class _PixelIconPainter extends CustomPainter {
  _PixelIconPainter({required this.pixels});

  final List<String> pixels;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = pixels.length;
    final cols = pixels.first.length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var y = 0; y < rows; y++) {
      final row = pixels[y];
      for (var x = 0; x < cols; x++) {
        final color = _colorFor(row[x]);
        if (color == null) continue;
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.3, cellH + 0.3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelIconPainter oldDelegate) =>
      oldDelegate.pixels != pixels;
}
