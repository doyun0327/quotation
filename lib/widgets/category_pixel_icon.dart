import 'package:flutter/material.dart';
import 'package:quotation/theme/app_palette.dart';

/// Colored pixel mark for a home subcategory.
class CategoryPixelIcon extends StatelessWidget {
  const CategoryPixelIcon({
    super.key,
    required this.categoryId,
    this.size = 28,
  });

  final String categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mark = CategoryMarks.of(categoryId);
    final tone = CategorySky.of(categoryId, context.palette);
    return CustomPaint(
      size: Size.square(size),
      painter: _CategoryPixelPainter(
        rows: mark.rows,
        main: tone.icon,
        light: tone.shine,
        accent: tone.detail,
      ),
    );
  }
}

/// White plus the active theme color, alternating down the category list.
abstract final class CategorySky {
  static const white = Color(0xFFFFFFFF);

  static const order = [
    'gratitude',
    'love',
    'tired',
    'self',
    'courage',
    'anxiety',
    'lonely',
    'growth',
    'relation',
    'dream',
    'buddhism',
    'christian',
    'quotes',
    'writers',
  ];

  static bool inverted(String id) {
    final index = order.indexOf(id);
    return (index < 0 ? 0 : index).isOdd;
  }

  static Color ink(AppPalette palette) =>
      Color.lerp(palette.accent, const Color(0xFF2C3340), 0.22)!;

  static Color border(AppPalette palette) =>
      Color.lerp(palette.accent, white, 0.42)!;

  static SkyTone of(String id, AppPalette palette) {
    final accent = palette.accent;
    final soft = palette.accentSoft;
    final line = border(palette);
    final deep = ink(palette);
    if (!inverted(id)) {
      return SkyTone(
        icon: accent,
        shine: white,
        detail: deep,
        plate: white,
        plateLine: line,
        card: white,
      );
    }
    return SkyTone(
      icon: accent,
      shine: white,
      detail: deep,
      plate: soft,
      plateLine: Color.lerp(accent, white, 0.62)!,
      card: Color.lerp(soft, white, 0.72)!,
    );
  }
}

class SkyTone {
  const SkyTone({
    required this.icon,
    required this.shine,
    required this.detail,
    required this.plate,
    required this.plateLine,
    required this.card,
  });

  final Color icon;
  final Color shine;
  final Color detail;
  final Color plate;
  final Color plateLine;
  final Color card;
}

class CategoryMark {
  const CategoryMark({
    required this.main,
    required this.light,
    required this.accent,
    required this.rows,
  });

  final Color main;
  final Color light;
  final Color accent;

  /// `#` main, `+` light, `*` accent, `.` empty.
  final List<String> rows;

  Color get wash => Color.lerp(const Color(0xFFFFFBF7), main, 0.30)!;

  Color get card => Color.lerp(const Color(0xFFFFFCF9), main, 0.07)!;

  Color get line => Color.lerp(const Color(0xFFFFFBF7), main, 0.42)!;

  Color get ink => Color.lerp(main, const Color(0xFF3A342E), 0.28)!;
}

abstract final class CategoryMarks {
  static CategoryMark of(String id) {
    return switch (id) {
      'gratitude' => const CategoryMark(
          main: Color(0xFFE2B15A),
          light: Color(0xFFF8E7B8),
          accent: Color(0xFFE8899A),
          rows: _gratitude,
        ),
      'love' => const CategoryMark(
          main: Color(0xFFE57B93),
          light: Color(0xFFF8C3D0),
          accent: Color(0xFFF3A8BA),
          rows: _love,
        ),
      'tired' => const CategoryMark(
          main: Color(0xFF7EADC8),
          light: Color(0xFFE7F4F8),
          accent: Color(0xFFB7D0DE),
          rows: _tired,
        ),
      'self' => const CategoryMark(
          main: Color(0xFFE2A07E),
          light: Color(0xFFFFF1E6),
          accent: Color(0xFFE57B93),
          rows: _self,
        ),
      'courage' => const CategoryMark(
          main: Color(0xFFC9A27A),
          light: Color(0xFFF6D7B4),
          accent: Color(0xFFE08A58),
          rows: _courage,
        ),
      'anxiety' => const CategoryMark(
          main: Color(0xFF8B98D0),
          light: Color(0xFFE6EAF8),
          accent: Color(0xFF6E7EBE),
          rows: _anxiety,
        ),
      'lonely' => const CategoryMark(
          main: Color(0xFFA894D4),
          light: Color(0xFFEDE6FA),
          accent: Color(0xFFE2B15A),
          rows: _lonely,
        ),
      'growth' => const CategoryMark(
          main: Color(0xFF6EAE7E),
          light: Color(0xFFD4EBD8),
          accent: Color(0xFFC4A07A),
          rows: _growth,
        ),
      'relation' => const CategoryMark(
          main: Color(0xFF7EADC8),
          light: Color(0xFFE7F4F8),
          accent: Color(0xFFE57B93),
          rows: _relation,
        ),
      'dream' => const CategoryMark(
          main: Color(0xFFE2B15A),
          light: Color(0xFFF8E7B8),
          accent: Color(0xFFF6F0D4),
          rows: _dream,
        ),
      'buddhism' => const CategoryMark(
          main: Color(0xFFE29AB0),
          light: Color(0xFFF8D5E0),
          accent: Color(0xFF6EAE7E),
          rows: _buddhism,
        ),
      'christian' => const CategoryMark(
          main: Color(0xFF7E9CC4),
          light: Color(0xFFE3EDF6),
          accent: Color(0xFFE2B15A),
          rows: _christian,
        ),
      'quotes' => const CategoryMark(
          main: Color(0xFFD4A04A),
          light: Color(0xFFF6E4B4),
          accent: Color(0xFFE8C98A),
          rows: _quotes,
        ),
      'writers' => const CategoryMark(
          main: Color(0xFFC98464),
          light: Color(0xFFF8EBDD),
          accent: Color(0xFF8E5E48),
          rows: _writers,
        ),
      _ => const CategoryMark(
          main: Color(0xFFD4A04A),
          light: Color(0xFFF6E4B4),
          accent: Color(0xFFE8C98A),
          rows: _quotes,
        ),
    };
  }

  static const _gratitude = [
    '......**......',
    '.....*++*.....',
    '......**......',
    '...########...',
    '...#++##++#...',
    '...########...',
    '...#++++++#...',
    '...#++++++#...',
    '...########...',
  ];

  static const _love = [
    '..##....##..',
    '.#++#..#++#.',
    '#++++##++++#',
    '#++++++++++#',
    '.#++++++++#.',
    '..#++++++#..',
    '...#++++#...',
    '....#++#....',
    '.....##.....',
  ];

  static const _tired = [
    '....*...*...',
    '.....* *....',
    '....*...*...',
    '............',
    '...######...',
    '..#++++++#..',
    '..#++++++#..',
    '..#++++++#..',
    '...######...',
    '.....##.....',
  ];

  static const _self = [
    '....####....',
    '...#++++#...',
    '..#+#**#+#..',
    '..#++**++#..',
    '...#++++#...',
    '....####....',
    '......#.....',
    '......#.....',
    '.....###....',
  ];

  static const _courage = [
    '....#.......',
    '....##*.....',
    '....#+*#....',
    '....#+**#...',
    '....#+*#....',
    '....##*.....',
    '....#.......',
    '....#.......',
    '..#####.....',
  ];

  static const _anxiety = [
    '....####....',
    '...#++++#...',
    '..##++++##..',
    '.##########.',
    '............',
    '....*...*...',
    '............',
    '....*...*...',
  ];

  static const _lonely = [
    '.....####...',
    '....##+++#..',
    '...##++++...',
    '..##++++.*..',
    '..##++++....',
    '..##++++....',
    '...##++++...',
    '....##+++#..',
    '.....####...',
  ];

  static const _growth = [
    '...##.......',
    '..#++#..##..',
    '.#++++#.#+#.',
    '..#++#...##.',
    '...##..*....',
    '.....* *....',
    '......*.....',
    '.....###....',
    '...#####....',
  ];

  static const _relation = [
    '..#......*..',
    '.###....***.',
    '..#......*..',
    '.###....***.',
    '#.#.#..*.*.*',
    '#.#.#..*.*.*',
  ];

  static const _dream = [
    '......#.....',
    '.....###....',
    '...#+#+#+...',
    '.###+#+#+###',
    '...#+#+#+...',
    '.....###....',
    '......#.....',
    '........*...',
  ];

  static const _buddhism = [
    '......#.....',
    '.....#.#....',
    '....#.+.#...',
    '...#..+..#..',
    '..##.#+#.##.',
    '...##*##*#..',
    '....#***#...',
    '.....***....',
  ];

  static const _christian = [
    '......#.....',
    '.....###....',
    '...#+#+#+...',
    '..#######...',
    '..#.....#...',
    '..#..*..#...',
    '..#.###.#...',
    '..#..*..#...',
    '..#######...',
  ];

  static const _quotes = [
    '..##....##..',
    '.#++#..#++#.',
    '.#++#..#++#.',
    '..##....##..',
    '...#....#...',
    '..#....#....',
  ];

  static const _writers = [
    '.##########.',
    '.#+++*+++#..',
    '.#+++*+++#..',
    '.#+++*+++#..',
    '.#+++*+++#..',
    '.##########.',
    '..********..',
  ];
}

class _CategoryPixelPainter extends CustomPainter {
  _CategoryPixelPainter({
    required this.rows,
    required this.main,
    required this.light,
    required this.accent,
  });

  final List<String> rows;
  final Color main;
  final Color light;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) return;
    final height = rows.length;
    final width = rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
    var minX = width;
    var maxX = -1;
    var minY = height;
    var maxY = -1;
    for (var y = 0; y < height; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        if (_colorOf(row[x]) == null) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX < 0) return;

    final unit = size.shortestSide / (width > height ? width : height);
    final contentW = (maxX - minX + 1) * unit;
    final contentH = (maxY - minY + 1) * unit;
    final ox = (size.width - contentW) / 2 - minX * unit;
    final oy = (size.height - contentH) / 2 - minY * unit;

    for (var y = 0; y < height; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final color = _colorOf(row[x]);
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(ox + x * unit, oy + y * unit, unit + 0.35, unit + 0.35),
          Paint()
            ..color = color
            ..isAntiAlias = false,
        );
      }
    }
  }

  Color? _colorOf(String cell) {
    return switch (cell) {
      '#' => main,
      '+' => light,
      '*' => accent,
      _ => null,
    };
  }

  @override
  bool shouldRepaint(covariant _CategoryPixelPainter oldDelegate) {
    return oldDelegate.main != main ||
        oldDelegate.light != light ||
        oldDelegate.accent != accent ||
        oldDelegate.rows != rows;
  }
}
