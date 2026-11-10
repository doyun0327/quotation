import 'package:flutter/material.dart';
import 'package:quotation/data/together_bubble.dart';
import 'package:quotation/data/widget_fonts.dart';

/// Speech bubble drawn on the Together widget. Size comes from
/// [TogetherBubbleLayout.size] so callers can position it before layout.
///
/// Always drawn as a clean (non-pixel) rounded bubble so decorate and the
/// home widget match, even when the rest of the card is pixel style.
class TogetherBubbleView extends StatelessWidget {
  const TogetherBubbleView({
    super.key,
    required this.text,
    required this.tail,
    required this.isPixel,
    this.font = WidgetFont.basic,
    this.textColor = TogetherBubbleLayout.ink,
    this.scale = 100,
  });

  final String text;
  final TogetherBubbleTail tail;
  /// Kept for call-site compatibility; bubble outline/text stay clean.
  final bool isPixel;
  final WidgetFont font;
  final Color textColor;

  /// Percent of the normal bubble, see [TogetherBubble.scale].
  final int scale;

  @override
  Widget build(BuildContext context) {
    final bubble = CustomPaint(
      painter: _BubblePainter(tail: tail),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TogetherBubbleLayout.padX,
          TogetherBubbleLayout.padY,
          TogetherBubbleLayout.padX,
          TogetherBubbleLayout.padY + TogetherBubbleLayout.tailH,
        ),
        child: Text(
          text.isEmpty ? ' ' : text,
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: TogetherBubbleLayout.style(
            isPixel: false,
            font: font,
            color: textColor,
          ),
        ),
      ),
    );
    if (scale == 100) return bubble;
    return SizedBox.fromSize(
      size: TogetherBubbleLayout.size(
        text,
        isPixel: isPixel,
        font: font,
        scale: scale,
      ),
      child: FittedBox(fit: BoxFit.fill, child: bubble),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.tail});

  final TogetherBubbleTail tail;

  /// Smooth rounded body + triangular tail (clean style).
  static Path outline(Size size, TogetherBubbleTail tail) {
    const t = TogetherBubbleLayout.tailH;
    const tw = TogetherBubbleLayout.tailW;
    const inset = TogetherBubbleLayout.tailInset;
    const radius = 10.0;
    final w = size.width;
    final bodyH = size.height - t;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, bodyH),
      const Radius.circular(radius),
    );
    final left = tail == TogetherBubbleTail.left;
    final base = left ? inset : w - inset - tw;
    final tipX = base + tw / 2;
    final tipY = size.height;
    final path = Path()..addRRect(body);
    final tailPath = Path()
      ..moveTo(base, bodyH - 1)
      ..lineTo(tipX, tipY)
      ..lineTo(base + tw, bodyH - 1)
      ..close();
    return Path.combine(PathOperation.union, path, tailPath);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = TogetherBubbleLayout.border;
    // Keep the stroke inside the box so the tail tip is not clipped.
    final inner = Size(size.width - stroke, size.height - stroke);
    canvas.save();
    canvas.translate(stroke / 2, stroke / 2);
    final path = outline(inner, tail);
    canvas.drawPath(
      path,
      Paint()
        ..color = TogetherBubbleLayout.fill
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = TogetherBubbleLayout.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.tail != tail;
}
