import 'package:flutter/material.dart';
import 'package:quotation/theme/app_theme.dart';

/// Chunky pixel-art color tile (hard outline + mosaic fill).
class PixelColorTile extends StatelessWidget {
  const PixelColorTile({
    super.key,
    required this.argb,
    required this.selected,
    required this.onTap,
    this.transparent = false,
    this.size = 36,
  });

  final int argb;
  final bool selected;
  final bool transparent;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A22),
          border: Border.all(
            color: selected ? const Color(0xFFFFF6E8) : const Color(0xFF1A1A22),
            width: selected ? 3 : 2,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF1A1A22)),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: transparent
                ? const CustomPaint(painter: PixelCheckerPainter())
                : CustomPaint(
                    painter: PixelMosaicFillPainter(argb, unit: 4),
                  ),
          ),
        ),
      ),
    );
  }
}

/// “더 고르기” — square pixel chrome.
class PixelMoreColorsButton extends StatelessWidget {
  const PixelMoreColorsButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E8),
          border: Border.all(color: const Color(0xFF1A1A22), width: 2),
        ),
        child: Text(
          label,
          style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C3340),
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Soft shades extracted from the reference cream pixel mosaic (+ pastels).
const kPixelBgQuick = <int>[
  0x00000000, // transparent
  0xFFFEFBE8, // ref highlight
  0xFFFDF7D5, // ref base light
  0xFFF9F1C6, // ref mid
  0xFFFBEFA7, // ref deeper gold
  0xFFFFF8E1,
  0xFFFFE4EC,
  0xFFE8F5E9,
  0xFFE3F2FD,
  0xFFF3E5F5,
  0xFFD4E5FF,
  0xFFFFD6E8,
];

/// Reference cream family (from attached mosaic photo).
const kPixelCreamShades = <int>[
  0xFFFEFBE8,
  0xFFFDF7D5,
  0xFFF9F1C6,
  0xFFF5EEC0,
  0xFFFBEFA7,
  0xFFF8F0B8,
  0xFFFFFCEB,
  0xFFFFF3E8,
];

/// Soft mosaic: equal-size square pixels, subtle shade noise (not a checker).
class PixelMosaicFillPainter extends CustomPainter {
  const PixelMosaicFillPainter(this.argb, {this.unit = 8});

  final int argb;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final base = Color(argb | 0xFF000000);
    final rng = _SeedRng(argb ^ size.width.round() ^ (size.height.round() << 8));
    final shades = _softShades(base);
    final paint = Paint()..isAntiAlias = false;
    final u = unit.clamp(3.0, 16.0);

    // Same pixel size everywhere; only shade varies (seeded, not checker).
    final cols = (size.width / u).ceil();
    final rows = (size.height / u).ceil();
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        // Neighborhood-biased pick so clumps feel natural, not striped.
        final n = rng.next();
        final idx = n < 0.22
            ? 0
            : n < 0.42
                ? 1
                : n < 0.62
                    ? 2
                    : n < 0.80
                        ? 3
                        : n < 0.92
                            ? 4
                            : 5;
        paint.color = shades[idx];
        final x = col * u;
        final y = row * u;
        canvas.drawRect(
          Rect.fromLTWH(x, y, u + 0.4, u + 0.4),
          paint,
        );
      }
    }
  }

  /// Very soft family around [base] — same feel as the cream reference.
  static List<Color> _softShades(Color base) {
    return [
      Color.lerp(base, const Color(0xFFFFFFFF), 0.14)!,
      Color.lerp(base, const Color(0xFFFFFFFF), 0.07)!,
      base,
      Color.lerp(base, const Color(0xFFE8D98A), 0.10)!,
      Color.lerp(base, const Color(0xFF000000), 0.035)!,
      Color.lerp(base, const Color(0xFF000000), 0.06)!,
    ];
  }

  @override
  bool shouldRepaint(covariant PixelMosaicFillPainter oldDelegate) =>
      oldDelegate.argb != argb || oldDelegate.unit != unit;
}

class PixelCheckerPainter extends CustomPainter {
  const PixelCheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final cell = size.width / n;
    final light = Paint()..color = const Color(0xFFE8E8E8);
    final dark = Paint()..color = const Color(0xFF9E9E9E);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          ((x + y).isEven) ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeedRng {
  _SeedRng(int seed) : _s = seed == 0 ? 0xA5A5 : seed & 0x7fffffff;

  int _s;

  double next() {
    _s = (1103515245 * _s + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }

  int nextInt(int max) => (next() * max).floor().clamp(0, max - 1);
}
