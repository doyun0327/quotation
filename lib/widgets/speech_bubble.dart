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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final width = !maxW.isFinite || maxW <= 0 ? 220.0 : maxW;
        final height = !maxH.isFinite || maxH <= 0
            ? 120.0
            : maxH.clamp(100.0, 132.0);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10 + _tailHeight),
                child: Column(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onMessageTap,
                          borderRadius: BorderRadius.circular(clean ? 16 : 10),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
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
                              child: Icon(
                                isSaved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                key: ValueKey(isSaved),
                                size: 20,
                                color: AppColors.heart,
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
          ),
        );
      },
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
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = soft ? 1 : 1.5
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = soft,
    );
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
