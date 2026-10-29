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
      notebook => '편지',
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

/// 16x16 pixel art. `.` is empty. Ink is centered in the plate.
List<String> _pixelsFor(DdayIconKind kind) {
  return switch (kind) {
    DdayIconKind.cake => const [
        '................',
        '....D......D....',
        '....Y......Y....',
        '....D......D....',
        '...DDDDDDDDDD...',
        '..DPPPPPPPPPPD..',
        '.DPWWPPPPPPWWPD.',
        '.DPPPPPPPPPPPPD.',
        '..DCCCCCCCCCCD..',
        '.DCWCWCWWCWCWCD.',
        '.DDDDDDDDDDDDDD.',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.plane => const [
        '................',
        '................',
        '..DD............',
        '.DBBD...........',
        'DBBBBBBBBBBBBBD.',
        'DBBBBBBBBBBBBBBD',
        'DBBBBBBBWWBBBBBD',
        'DBBBBBBBBBBBBBBD',
        'DBBBBBBBBBBBBBD.',
        '.DBBD...........',
        '..DD............',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.cat => const [
        '................',
        '..DD........DD..',
        '.DPPD......DPPD.',
        '.DPPDDDDDDDDPPD.',
        '..DOOOOOOOOOOD..',
        '..DOWDOOOODWOD..',
        '..DOPPOOOOPPOD..',
        '..DOOOOPPOOOOD..',
        '..DOOOOOOOOOOD..',
        '...DOOOOOOOOD...',
        '....DOOOOOOD....',
        '.....DDDDDD.....',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.dog => const [
        '................',
        '.DDD........DDD.',
        '.DKKD......DKKD.',
        '.DKKKDDDDDDKKKD.',
        '..DKKKKKKKKKKD..',
        '..DKWKKKKKKWKD..',
        '..DKKKKKKKKKKD..',
        '..DKKKKPPKKKKD..',
        '..DKKKPPPPKKKD..',
        '...DKKKKKKKKD...',
        '....DKKKKKKD....',
        '.....DDDDDD.....',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.pen => const [
        '................',
        '....DDDDDDDD....',
        '....DPPPPPPD....',
        '....DYYYYYYD....',
        '....DYYYYYYD....',
        '....DYYYYYYD....',
        '....DYYYYYYD....',
        '....DWWWWWWD....',
        '....DKKKKKKD....',
        '.....DKKKKD.....',
        '......DDDD......',
        '.......DD.......',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.notebook => const [
        '................',
        'DDDDDDDDDDDDDDDD',
        'DWWWWWWWWWWWWWWD',
        'DWWWRRRWWRRRWWWD',
        'DWWWRRRRRRRRWWWD',
        'DWWWWRRRRRWWWWWD',
        'DWWWWWRRRRWWWWWD',
        'DWWWWWWRRWWWWWWD',
        'DWWWWWWWWWWWWWWD',
        'DDDDDDDDDDDDDDDD',
        '................',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.sport => const [
        '................',
        '................',
        '..DDD......DDD..',
        '.DWWWD....DWWWD.',
        '.DOOODDDDDDOOOD.',
        '.DOOOOOOOOOOOOD.',
        '.DOOODDDDDDOOOD.',
        '.DWWWD....DWWWD.',
        '..DDD......DDD..',
        '................',
        '................',
        '................',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.medal => const [
        '................',
        '....DD....DD....',
        '....DR....RD....',
        '....DRR..RRD....',
        '.....DRRRRD.....',
        '......DDDD......',
        '....DDYYYYDD....',
        '...DYYYYYYYYD...',
        '..DYYYYYYYYYYD..',
        '..DYYYWWWWYYYD..',
        '..DYYYYYYYYYYD..',
        '...DYYYYYYYYD...',
        '....DDYYYYDD....',
        '.....DDDDDD.....',
        '................',
        '................',
      ],
    DdayIconKind.home => const [
        '................',
        '.......DD.......',
        '......DRRD......',
        '.....DRRRRD.....',
        '....DRRRRRRD....',
        '...DRRRRRRRRD...',
        '..DRRRRRRRRRRD..',
        '.DRRRRRRRRRRRRD.',
        '.DWWDDWWWWDDWWD.',
        '.DWWDDWWWWDDWWD.',
        '.DWWWWWDDWWWWWD.',
        '.DWWWWWDDWWWWWD.',
        '.DDDDDDDDDDDDDD.',
        '................',
        '................',
      ],
    DdayIconKind.baby => const [
        '................',
        '.....DPPPPD.....',
        '....DPWWWWPD....',
        '...DDDDDDDDDD...',
        '..DSSSSSSSSSSD..',
        '..DSWSSSSSSWSD..',
        '..DSSSSSSSSSSD..',
        '..DSSSSDDSSSSD..',
        '...DSSSSSSSSD...',
        '....DDDDDDDD....',
        '...DPPPPPPPPD...',
        '...DPPPPPPPPD...',
        '....DDDDDDDD....',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.tree => const [
        '................',
        '.....DDDDDD.....',
        '....DGLLLLGD....',
        '...DGGGGGGGGD...',
        '..DGGRGGGGRGGD..',
        '..DGGGGGGGGGGD..',
        '..DGGGGDDGGGGD..',
        '...DGGGGGGGGD...',
        '....DDGGGGDD....',
        '......DKKD......',
        '......DKKD......',
        '.....DDKKDD.....',
        '................',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.star => const [
        '.......DD.......',
        '......DYYD......',
        '.....DYYYYD.....',
        '....DYYYYYYD....',
        '..DYYYYYYYYYYD..',
        'DYYYYYYYYYYYYYYD',
        '..DYYYYYYYYYYD..',
        '....DYYYYYYD....',
        '....DYY..YYD....',
        '...DYYY..YYYD...',
        '..DYYY....YYYD..',
        '.DYYY......YYYD.',
        '..DY........YD..',
        '...D........D...',
        '................',
        '................',
      ],
    DdayIconKind.wine => const [
        '................',
        '..DDDDDDDDDDDD..',
        '..DWWWWWWWWWWD..',
        '...DWWRRRRRWD...',
        '....DWRRRRWD....',
        '....DWRRRRWD....',
        '.....DWWRWD.....',
        '......DWWD......',
        '.......DD.......',
        '.......DD.......',
        '......DKKD......',
        '.....DKKKKD.....',
        '....DDDDDDDD....',
        '................',
        '................',
        '................',
      ],
    DdayIconKind.heart => const [
        '................',
        '...DDD....DDD...',
        '..DPPPD..DPPPD..',
        '.DPWWPPDDPPWWPD.',
        '.DPPPPPPPPPPPPD.',
        '..DPPPPPPPPPPD..',
        '...DPPPPPPPPD...',
        '....DPPPPPPD....',
        '.....DPPPPD.....',
        '......DPPD......',
        '.......DD.......',
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
    'D' => const Color(0xFF6E657C),
    'R' => const Color(0xFFFF6B8A),
    'P' => const Color(0xFFFF9EBE),
    'Y' => const Color(0xFFFFD56A),
    'C' => const Color(0xFFFFC9A8),
    'S' => const Color(0xFFFFD3BE),
    'W' => const Color(0xFFFFFFFF),
    'B' => const Color(0xFF5B8DEF),
    'O' => const Color(0xFFFFB26B),
    'K' => const Color(0xFFA67C52),
    'G' => const Color(0xFF5FBF6B),
    'L' => const Color(0xFFC8F5CF),
    '.' => null,
    _ => null,
  };
}

class _PixelIconPainter extends CustomPainter {
  _PixelIconPainter({required this.pixels});

  final List<String> pixels;

  @override
  void paint(Canvas canvas, Size size) {
    if (pixels.isEmpty) return;
    final height = pixels.length;
    final width = pixels.map((row) => row.length).reduce((a, b) => a > b ? a : b);
    var minX = width;
    var maxX = -1;
    var minY = height;
    var maxY = -1;
    for (var y = 0; y < height; y++) {
      final row = pixels[y];
      for (var x = 0; x < row.length; x++) {
        if (_colorFor(row[x]) == null) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX < 0) return;

    final unit = size.shortestSide / ((width > height ? width : height) + 2);
    final contentW = (maxX - minX + 1) * unit;
    final contentH = (maxY - minY + 1) * unit;
    final ox = (size.width - contentW) / 2 - minX * unit;
    final oy = (size.height - contentH) / 2 - minY * unit;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    for (var y = 0; y < height; y++) {
      final row = pixels[y];
      for (var x = 0; x < row.length; x++) {
        final color = _colorFor(row[x]);
        if (color == null) continue;
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            ox + x * unit,
            oy + y * unit,
            unit + 0.08,
            unit + 0.08,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelIconPainter oldDelegate) =>
      oldDelegate.pixels != pixels;
}
