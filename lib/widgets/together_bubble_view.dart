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

  /// Pixel-art outline built from axis-aligned rects (body + tail as one
  /// shape, so no seam shows): corners are notched by one pixel and the tail
  /// steps down in pixel rows toward its outer side.
  static Path outline(Size size, TogetherBubbleTail tail) {
    const u = TogetherBubbleLayout.pixel;
    const t = TogetherBubbleLayout.tailH;
    const tw = TogetherBubbleLayout.tailW;
    const inset = TogetherBubbleLayout.tailInset;
    final w = size.width;
    final bodyH = size.height - t;
    Path rect(double l, double top, double r, double b) =>
        Path()..addRect(Rect.fromLTRB(l, top, r, b));
    var path = Path.combine(
      PathOperation.union,
      rect(u, 0, w - u, bodyH),
      rect(0, u, w, bodyH - u),
    );
    final left = tail == TogetherBubbleTail.left;
    final base = left ? inset : w - inset - tw;
    final rows = (t / u).round();
    final unitsW = (tw / u).round();
    for (var k = 0; k < rows; k++) {
      final rowW = (unitsW * (rows - k) / rows).round().clamp(1, unitsW) * u;
      final l = left ? base : base + tw - rowW;
      // First row overlaps the body bottom so the outline merges cleanly.
      final top = k == 0 ? bodyH - u : bodyH + k * u;
      path = Path.combine(
        PathOperation.union,
        path,
        rect(l, top, l + rowW, bodyH + (k + 1) * u),
      );
    }
    return path;
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
        ..isAntiAlias = false,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = TogetherBubbleLayout.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.miter
        ..isAntiAlias = false,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.tail != tail;
}
