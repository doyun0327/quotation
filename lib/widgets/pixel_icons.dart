import 'package:flutter/material.dart';
import 'package:quotation/theme/visual_style_controller.dart';

enum PixelIconKind { heart, church, book, sprout }

class PixelIcon extends StatelessWidget {
  const PixelIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 36,
  });

  final PixelIconKind kind;
  final Color color;
  final double size;

  IconData get _materialIcon => switch (kind) {
        PixelIconKind.heart => Icons.favorite_rounded,
        PixelIconKind.church => Icons.church_rounded,
        PixelIconKind.book => Icons.menu_book_rounded,
        PixelIconKind.sprout => Icons.eco_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: visualStyleController,
      builder: (context, _) {
        if (visualStyleController.isClean) {
          return Icon(
            _materialIcon,
            size: size,
            color: color,
          );
        }
        return CustomPaint(
          size: Size.square(size),
          painter: _PixelIconPainter(kind: kind, color: color),
        );
      },
    );
  }
}

class _PixelIconPainter extends CustomPainter {
  _PixelIconPainter({required this.kind, required this.color});

  final PixelIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 12;

    void pixel(int x, int y, [Color? c]) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, unit + 0.2, unit + 0.2),
        Paint()
          ..color = c ?? color
          ..style = PaintingStyle.fill
          ..isAntiAlias = false,
      );
    }

    switch (kind) {
      case PixelIconKind.heart:
        for (final p in const [
          [2, 2], [3, 2], [5, 2], [6, 2],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3],
          [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4],
          [2, 5], [3, 5], [4, 5], [5, 5], [6, 5],
          [3, 6], [4, 6], [5, 6],
          [4, 7],
        ]) {
          pixel(p[0], p[1]);
        }
      case PixelIconKind.church:
        for (final p in const [
          [5, 0],
          [4, 1], [5, 1], [6, 1],
          [5, 2],
          [3, 3], [4, 3], [5, 3], [6, 3], [7, 3],
          [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4], [8, 4],
          [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5], [8, 5],
          [2, 6], [4, 6], [5, 6], [6, 6], [8, 6],
          [2, 7], [4, 7], [5, 7], [6, 7], [8, 7],
          [2, 8], [3, 8], [4, 8], [5, 8], [6, 8], [7, 8], [8, 8],
          [2, 9], [3, 9], [4, 9], [5, 9], [6, 9], [7, 9], [8, 9],
        ]) {
          pixel(p[0], p[1]);
        }
        pixel(5, 6, color.withValues(alpha: 0.35));
        pixel(5, 7, color.withValues(alpha: 0.35));
      case PixelIconKind.book:
        for (final p in const [
          [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2],
          [2, 3], [5, 3], [8, 3],
          [2, 4], [5, 4], [8, 4],
          [2, 5], [5, 5], [8, 5],
          [2, 6], [5, 6], [8, 6],
          [2, 7], [3, 7], [4, 7], [5, 7], [6, 7], [7, 7], [8, 7],
          [3, 8], [4, 8], [5, 8], [6, 8], [7, 8],
        ]) {
          pixel(p[0], p[1]);
        }
      case PixelIconKind.sprout:
        for (final p in const [
          [5, 1], [6, 1],
          [4, 2], [5, 2], [6, 2], [7, 2],
          [3, 3], [4, 3], [7, 3], [8, 3],
          [2, 4], [3, 4], [8, 4], [9, 4],
          [5, 4], [5, 5], [5, 6], [5, 7], [5, 8],
          [4, 8], [5, 8], [6, 8],
          [3, 9], [4, 9], [5, 9], [6, 9], [7, 9],
        ]) {
          pixel(p[0], p[1]);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelIconPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}
