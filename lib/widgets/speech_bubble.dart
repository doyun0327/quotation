import 'package:flutter/material.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.message,
    this.isSaved = false,
    this.onHeartTap,
    this.onMessageTap,
  });

  final String message;
  final bool isSaved;
  final VoidCallback? onHeartTap;
  final VoidCallback? onMessageTap;

  static const double _tailHeight = 12;
  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clean = visualStyleController.isClean;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _RectBubblePainter(
              fill: AppColors.card,
              border: palette.border,
              shadow: clean
                  ? const Color(0x18000000)
                  : const Color(0x14000000),
              radius: clean ? 22 : _radius,
              tailHeight: _tailHeight,
              soft: clean,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10 + _tailHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMessageTap,
                  borderRadius: BorderRadius.circular(clean ? 16 : 10),
                  child: Text(
                    message,
                    softWrap: true,
                    style: AppTheme.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onHeartTap,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: CustomPaint(
                          key: ValueKey(isSaved),
                          size: const Size.square(18),
                          painter: _PixelHeartPainter(
                            color: AppColors.heart,
                            filled: isSaved,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RectBubblePainter extends CustomPainter {
  _RectBubblePainter({
    required this.fill,
    required this.border,
    required this.shadow,
    required this.radius,
    required this.tailHeight,
    this.soft = false,
  });

  final Color fill;
  final Color border;
  final Color shadow;
  final double radius;
  final double tailHeight;
  final bool soft;

  Path _path(Size size) {
    final bodyBottom = size.height - tailHeight;
    final w = size.width;
    final r = radius;
    const tailAnchor = 16.0;
    const tipX = 6.0;

    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, bodyBottom - r)
      ..quadraticBezierTo(w, bodyBottom, w - r, bodyBottom)
      ..lineTo(tailAnchor + 20, bodyBottom)
      ..cubicTo(
        tailAnchor + 12,
        bodyBottom + 1,
        tipX + 10,
        bodyBottom + tailHeight * 0.55,
        tipX,
        size.height - 1,
      )
      ..cubicTo(
        tipX + 2,
        bodyBottom + tailHeight * 0.45,
        tailAnchor + 2,
        bodyBottom + 1,
        tipX,
        bodyBottom,
      )
      ..lineTo(r, bodyBottom)
      ..quadraticBezierTo(0, bodyBottom, 0, bodyBottom - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);

    if (soft) {
      canvas.drawPath(
        path.shift(const Offset(0, 2)),
        Paint()
          ..color = shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..isAntiAlias = true,
      );
    } else {
      canvas.drawPath(
        path.shift(const Offset(2, 3)),
        Paint()
          ..color = shadow
          ..isAntiAlias = false,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill
        ..isAntiAlias = soft,
    );
    final stroke = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = soft ? 1.4 : 1.6
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = soft;
    const dash = 5.0;
    const gap = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), stroke);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RectBubblePainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.border != border ||
        oldDelegate.shadow != shadow ||
        oldDelegate.radius != radius ||
        oldDelegate.tailHeight != tailHeight ||
        oldDelegate.soft != soft;
  }
}

class _PixelHeartPainter extends CustomPainter {
  const _PixelHeartPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  static const _pixels = <List<int>>[
    [2, 2], [3, 2], [5, 2], [6, 2],
    [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3],
    [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4],
    [2, 5], [3, 5], [4, 5], [5, 5], [6, 5],
    [3, 6], [4, 6], [5, 6],
    [4, 7],
  ];

  static const _inner = <List<int>>[
    [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
    [2, 4], [3, 4], [4, 4], [5, 4], [6, 4],
    [3, 5], [4, 5], [5, 5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 9;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final hidden = filled ? const <String>{} : {for (final p in _inner) '${p[0]},${p[1]}'};
    for (final p in _pixels) {
      if (hidden.contains('${p[0]},${p[1]}')) continue;
      canvas.drawRect(
        Rect.fromLTWH(p[0] * unit, p[1] * unit, unit + 0.4, unit + 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PixelHeartPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.filled != filled;
  }
}
