import 'package:flutter/material.dart';
import 'package:quotation/data/together_bubble.dart';

/// Speech bubble drawn on the Together widget. Size comes from
/// [TogetherBubbleLayout.size] so callers can position it before layout.
class TogetherBubbleView extends StatelessWidget {
  const TogetherBubbleView({
    super.key,
    required this.text,
    required this.tail,
    required this.isPixel,
  });

  final String text;
  final TogetherBubbleTail tail;
  final bool isPixel;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
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
          style: TogetherBubbleLayout.style(isPixel: isPixel),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.tail});

  final TogetherBubbleTail tail;

  /// Body + tail as one outline, so no seam shows where they meet.
  static Path outline(Size size, TogetherBubbleTail tail) {
    const t = TogetherBubbleLayout.tailH;
    const tw = TogetherBubbleLayout.tailW;
    const inset = TogetherBubbleLayout.tailInset;
    final bodyH = size.height - t;
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, bodyH),
          const Radius.circular(TogetherBubbleLayout.radius),
        ),
      );
    final left = tail == TogetherBubbleTail.left;
    final baseStart = left ? inset : size.width - inset - tw;
    final tipX = left ? baseStart - 2 : baseStart + tw + 2;
    final tailPath = Path()
      ..moveTo(baseStart, bodyH - 1)
      ..lineTo(baseStart + tw, bodyH - 1)
      ..lineTo(tipX, size.height)
      ..close();
    return Path.combine(PathOperation.union, body, tailPath);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = TogetherBubbleLayout.border;
    // Keep the stroke inside the box so the tail tip is not clipped.
    final inner = Size(size.width - stroke, size.height - stroke);
    canvas.save();
    canvas.translate(stroke / 2, stroke / 2);
    final path = outline(inner, tail);
    canvas.drawPath(path, Paint()..color = TogetherBubbleLayout.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = TogetherBubbleLayout.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.tail != tail;
}
