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
  ring('ring'),
  gift('gift'),
  grad('grad'),
  flower('flower'),
  music('music'),
  bunny('bunny'),
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
      ring => '반지',
      gift => '선물',
      grad => '졸업',
      flower => '꽃',
      music => '음악',
      bunny => '토끼',
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

/// 16-wide pixel art, cropped and centered by the painter. `.` is empty.
/// Faces on the animals and a few objects, blush (`k`) and pastel fills
/// keep them soft next to the pixel font. Ids never change, so saved rooms
/// keep their icon.
List<String> _pixelsFor(DdayIconKind kind) {
  return switch (kind) {
    DdayIconKind.cake => const [
        '.......DD.......',
        '......DYOD......',
        '.......DD.......',
        '......DbbD......',
        '......DbbD......',
        '..DDDDDDDDDDDD..',
        '.DWWRWWWWWWRWWD.',
        '.DWWWWWWWWWWWWD.',
        '.DPPPPPPPPPPPPD.',
        '.DCCCCCCCCCCCCD.',
        '.DCCCCCCCCCCCCD.',
        '.DCCCCCCCCCCCCD.',
        '.DPPPPPPPPPPPPD.',
        '..DDDDDDDDDDDD..',
      ],
    DdayIconKind.plane => const [
        '..DD............',
        '.DBBD...........',
        '.DBBBD.DDDDD....',
        '..DBBDDbbbbbDD..',
        '..DDbbbbbbbbbbD.',
        '.DbbWWbWWbbbDbbD',
        '.DbbbbbbbbbbbkkD',
        '..DDbbBBBBbbbbD.',
        '....DDDBBBBDDD..',
        '......DBBBD.....',
        '......DDDD......',
      ],
    DdayIconKind.cat => const [
        '..DD........DD..',
        '.DPPD......DPPD.',
        '.DPPPDDDDDDPPPD.',
        '.DOOOOOOOOOOOOD.',
        'DOOOOOOOOOOOOOOD',
        'DOOODOOOOOODOOOD',
        'DOOODOOOOOODOOOD',
        'DOkkOOODDOOOkkOD',
        'DOOOOODOODOOOOOD',
        '.DOOOOOOOOOOOOD.',
        '..DDDDDDDDDDDD..',
      ],
    DdayIconKind.dog => const [
        '..DDD......DDD..',
        '.DKKKDDDDDDKKKD.',
        'DKKKCCCCCCCCKKKD',
        'DKKCCCCCCCCCCKKD',
        'DKKCCDCCCCDCCKKD',
        '.DKCCDCCCCDCCKD.',
        '.DDCkkCDDCkkCDD.',
        '..DCCCCDDCCCCD..',
        '..DCCCDCCDCCCD..',
        '...DCCCPPCCCD...',
        '....DDDDDDDD....',
      ],
    DdayIconKind.pen => const [
        '....DDDDDDDD....',
        '....DPPPPPPD....',
        '....DWWWWWWD....',
        '....DYYYYYYD....',
        '....DYYYYYYD....',
        '....DYYYYYYD....',
        '....DYYYYYYD....',
        '....DYYYYYYD....',
        '....DCCCCCCD....',
        '.....DCCCCD.....',
        '......DCCD......',
        '......DDDD......',
        '.......DD.......',
      ],
    DdayIconKind.notebook => const [
        'DDDDDDDDDDDDDDDD',
        'DpDppppppppppDpD',
        'DppDppppppppDppD',
        'DpppDppppppDpppD',
        'DppppDRRpRRDpppD',
        'DpppppRRRRRppppD',
        'DppppppRRRpppppD',
        'DpppppppRppppppD',
        'DDDDDDDDDDDDDDDD',
      ],
    DdayIconKind.sport => const [
        '.DDD........DDD.',
        'DPPPD......DPPPD',
        'DPWPDDDDDDDDPPPD',
        'DPPPDbbbbbbDPPPD',
        'DPPPDDDDDDDDPPPD',
        'DPPPD......DPPPD',
        '.DDD........DDD.',
      ],
    DdayIconKind.medal => const [
        '..DDD......DDD..',
        '..DRBD....DBRD..',
        '...DRBD..DBRD...',
        '....DRBDDBRD....',
        '.....DDYYDD.....',
        '....DYYYYYYD....',
        '...DYYWYYYYYD...',
        '..DYYYYYYYYYYD..',
        '..DYYYYYYYYYYD..',
        '..DYYYYYYYYYYD..',
        '...DYYYYYYYYD...',
        '....DDYYYYDD....',
        '......DDDD......',
      ],
    DdayIconKind.home => const [
        '.......DD.......',
        '......DRRD......',
        '.....DRRRRD.....',
        '....DRRRRRRD....',
        '...DRRRRRRRRD...',
        '..DRRRRRRRRRRD..',
        '.DDDDDDDDDDDDDD.',
        '..DCCCCCCCCCCD..',
        '..DCRCRCCKKKCD..',
        '..DCRRRCCKKKCD..',
        '..DCCRCCCKYKCD..',
        '..DCCCCCCKKKCD..',
        '..DDDDDDDDDDDD..',
      ],
    DdayIconKind.baby => const [
        '.....DDDDDD.....',
        '...DDbbbbbbDD...',
        '..DbbbbbbbbbbD..',
        '.DbbDDDDDDDDbbD.',
        '.DbDSSSSSSSSDbD.',
        '.DbDSDSSSSDSDbD.',
        '.DbDkkSSSSkkDbD.',
        '.DbDSSSPPSSSDbD.',
        '..DDSSPWWPSSDD..',
        '...DDSSPPSSDD...',
        '.....DDDDDD.....',
      ],
    DdayIconKind.tree => const [
        '.....DDDDDD.....',
        '...DDGGGGGGDD...',
        '..DGGLGGGGGGGD..',
        '.DGGLGGGGGGRGGD.',
        '.DGGGGGGGGGGGGD.',
        '.DGGGRGGGGGGGGD.',
        '.DGGGGGGGGGGRGD.',
        '..DGGGGGGRGGGD..',
        '...DDGGGGGGDD...',
        '.....DDKKDD.....',
        '......DKKD......',
        '....DDKKKKDD....',
      ],
    DdayIconKind.star => const [
        '.......DD.......',
        '......DYYD......',
        '.....DYYYYD.....',
        '.DDDDDYYYYDDDDD.',
        'DYYWYYYYYYYYYYYD',
        '.DYYYYYYYYYYYYD.',
        '..DYYYYYYYYYYD..',
        '...DYYYYYYYYD...',
        '...DYYYYYYYYD...',
        '..DYYYYDDYYYYD..',
        '..DYYYD..DYYYD..',
        '.DYYYD....DYYYD.',
        '.DDDD......DDDD.',
      ],
    DdayIconKind.wine => const [
        '.............Y..',
        '............YYY.',
        '...DDDDDDDDDDY..',
        '...DWbbbbbbbD...',
        '...DVVVVVVVVD...',
        '...DVWVVVVVVD...',
        '....DVVVVVVD....',
        '.....DVVVVD.....',
        '......DDDD......',
        '.......DD.......',
        '.......DD.......',
        '......DDDD......',
        '....DDDDDDDD....',
      ],
    DdayIconKind.ring => const [
        '......DDDD......',
        '.....DbWbbD.....',
        '....DbbbbbbD....',
        '.....DbbbbD.....',
        '......DbbD......',
        '.....DDDDDD.....',
        '....DYYYYYYD....',
        '...DYDDDDDDYD...',
        '..DYD......DYD..',
        '..DYD......DYD..',
        '..DYD......DYD..',
        '...DYDDDDDDYD...',
        '....DYYYYYYD....',
        '.....DDDDDD.....',
      ],
    DdayIconKind.gift => const [
        '...DD......DD...',
        '..DRRD....DRRD..',
        '...DRRD..DRRD...',
        '....DDRDDRDD....',
        '.DDDDDDDDDDDDDD.',
        '.DPPPPPRRPPPPPD.',
        '.DDDDDDDDDDDDDD.',
        '..DbbbbRRbbbbD..',
        '..DbDbbRRbbDbD..',
        '..DkbbbRRbbbkD..',
        '..DbbbbRRbbbbD..',
        '..DDDDDDDDDDDD..',
      ],
    DdayIconKind.grad => const [
        '.......DD.......',
        '.....DDBBDD.....',
        '...DDBBBBBBDD...',
        '.DDBBBBBBBBBBDD.',
        'DBBBBBBBBBBBBBBD',
        '.DDBBBBBBBBBBDD.',
        '...DDBBBBBBDDY..',
        '....DBBBBBBD.DY.',
        '....DBBBBBBD.DY.',
        '....DDDDDDDD.DYD',
        '.............DD.',
      ],
    DdayIconKind.flower => const [
        '.....DDDDDD.....',
        '...DDPPPPPPDD...',
        '..DPPPPPPPPPPD..',
        '.DPPPDDDDDDPPPD.',
        '.DPPDYYYYYYDPPD.',
        '.DPPDYDYYDYDPPD.',
        '.DPPDkYYYYkDPPD.',
        '.DPPDYYDDYYDPPD.',
        '.DPPPDDDDDDPPPD.',
        '..DPPPPPPPPPPD..',
        '...DDPPDDPPDD...',
        '.....DDGGDD.....',
        '..DLLLDGGDLLLD..',
        '...DDDDGGDDDD...',
        '.......DD.......',
      ],
    DdayIconKind.music => const [
        '......DDDDDDDD..',
        '......DVVVVVVD..',
        '......DVDDDDVD..',
        '......DVD..DVD..',
        '......DVD..DVD..',
        '......DVD..DVD..',
        '...DDDDVDDDDVD..',
        '..DVVVVVDVVVVVD.',
        '..DVkVVVDVkVVVD.',
        '..DVVVVVDVVVVVD.',
        '...DDDDD.DDDDD..',
      ],
    DdayIconKind.bunny => const [
        '...DD......DD...',
        '..DWPD....DPWD..',
        '..DWPD....DPWD..',
        '..DWPD....DPWD..',
        '..DWWDDDDDDWWD..',
        '.DWWWWWWWWWWWWD.',
        'DWWWWWWWWWWWWWWD',
        'DWWWDWWWWWWDWWWD',
        'DWkkWWWPPWWWkkWD',
        'DWWWWWDWWDWWWWWD',
        '.DWWWWWWWWWWWWD.',
        '..DDDDDDDDDDDD..',
      ],
    DdayIconKind.heart => const [
        '..DDDD....DDDD..',
        '.DPPPPD..DPPPPD.',
        'DPWWPPPDDPPPPPPD',
        'DPWPPPPPPPPPPPPD',
        'DPPPPPPPPPPPPPPD',
        'DPPPPPPPPPPPPPPD',
        '.DPPPPPPPPPPPPD.',
        '..DPPPPPPPPPPD..',
        '...DPPPPPPPPD...',
        '....DPPPPPPD....',
        '.....DPPPPD.....',
        '......DPPD......',
        '.......DD.......',
      ],
  };
}

Color? _colorFor(String ch) {
  return switch (ch) {
    // Warm plum outline: softer than the old grey.
    'D' => const Color(0xFF5E4B5C),
    'R' => const Color(0xFFFF7A96),
    'P' => const Color(0xFFFFA8C5),
    'p' => const Color(0xFFFFE0EA),
    'k' => const Color(0xFFFF8FAB),
    'Y' => const Color(0xFFFFD96E),
    'C' => const Color(0xFFFFE6C4),
    'S' => const Color(0xFFFFDCC8),
    'W' => const Color(0xFFFFFFFF),
    'B' => const Color(0xFF7FB0FF),
    'b' => const Color(0xFFD2E6FF),
    'O' => const Color(0xFFFFBD7A),
    'K' => const Color(0xFFB88A62),
    'G' => const Color(0xFF86D69A),
    'L' => const Color(0xFFD4F7DA),
    'V' => const Color(0xFFC3A1FF),
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
