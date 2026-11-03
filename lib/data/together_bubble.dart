import 'package:flutter/material.dart';

/// Which bottom corner the speech-bubble tail points out of.
enum TogetherBubbleTail {
  left,
  right;

  static TogetherBubbleTail byId(Object? id) =>
      id == 'right' || id == 'r' ? right : left;
}

/// One speech bubble placed on the Together widget.
///
/// [x]/[y] are the bubble's center offset from the card center in dp, with
/// y pointing up — the same convention as the cheer text.
@immutable
class TogetherBubble {
  const TogetherBubble({
    required this.id,
    required this.text,
    this.x = 0,
    this.y = 0,
    this.tail = TogetherBubbleTail.left,
    this.rotation = 0,
  });

  static const maxCount = 5;
  static const maxLength = 16;

  final String id;
  final String text;
  final double x;
  final double y;
  final TogetherBubbleTail tail;

  /// Clockwise degrees around the bubble center, 0–359.
  final int rotation;

  TogetherBubble copyWith({
    String? text,
    double? x,
    double? y,
    TogetherBubbleTail? tail,
    int? rotation,
  }) {
    return TogetherBubble(
      id: id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      tail: tail ?? this.tail,
      rotation: rotation == null ? this.rotation : normDegrees(rotation),
    );
  }

  static int normDegrees(int value) {
    final n = value % 360;
    return n < 0 ? n + 360 : n;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': x.round(),
        'y': y.round(),
        'tail': tail.name,
        if (rotation != 0) 'rotation': rotation,
      };

  /// Single line, capped — the home widget draws it without wrapping.
  static String clean(String raw) {
    final line = raw.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
    return line.length <= maxLength ? line : line.substring(0, maxLength);
  }

  /// [ax]/[ay] map another phone's canvas dp onto this one.
  static List<TogetherBubble> listFromJson(
    Object? raw, {
    int Function(int)? ax,
    int Function(int)? ay,
  }) {
    if (raw is! List) return const [];
    final out = <TogetherBubble>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final id = entry['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final x = (entry['x'] as num?)?.toInt() ?? 0;
      final y = (entry['y'] as num?)?.toInt() ?? 0;
      out.add(
        TogetherBubble(
          id: id,
          text: clean(entry['text']?.toString() ?? ''),
          x: (ax == null ? x : ax(x)).toDouble(),
          y: (ay == null ? y : ay(y)).toDouble(),
          tail: TogetherBubbleTail.byId(entry['tail']),
          rotation: normDegrees((entry['rotation'] as num?)?.toInt() ?? 0),
        ),
      );
      if (out.length >= maxCount) break;
    }
    return out;
  }

  static bool sameList(List<TogetherBubble> a, List<TogetherBubble> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final l = a[i];
      final r = b[i];
      if (l.id != r.id ||
          l.text != r.text ||
          l.x.round() != r.x.round() ||
          l.y.round() != r.y.round() ||
          l.tail != r.tail ||
          l.rotation != r.rotation) {
        return false;
      }
    }
    return true;
  }

  /// Same bubbles with the same words and tails; positions may differ.
  static bool sameContent(List<TogetherBubble> a, List<TogetherBubble> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].text != b[i].text ||
          a[i].tail != b[i].tail) {
        return false;
      }
    }
    return true;
  }

  /// Compact form the Android widget renderer reads.
  static List<Map<String, Object>> widgetJson(List<TogetherBubble> bubbles) => [
        for (final b in bubbles)
          if (b.text.isNotEmpty)
            {
              't': b.text,
              'x': b.x.round(),
              'y': b.y.round(),
              'd': b.tail == TogetherBubbleTail.right ? 'r' : 'l',
              'r': b.rotation,
            },
      ];
}

/// Bubble geometry shared by the decorate preview, the iPhone card and the
/// Android renderer (DdayWidgetVisuals.drawBubbles mirrors these numbers).
abstract final class TogetherBubbleLayout {
  static const fontSize = 12.0;
  static const lineHeight = 1.2;
  static const padX = 8.0;
  static const padY = 5.0;
  static const radius = 6.0;
  static const border = 1.5;
  static const tailW = 8.0;
  static const tailH = 6.0;
  static const tailInset = 10.0;
  static const fill = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2C3340);

  static TextStyle style({required bool isPixel}) => TextStyle(
        fontFamily: isPixel ? 'Galmuri' : null,
        fontSize: fontSize,
        // Galmuri ships one weight; a heavier one would fake bold here only.
        fontWeight: isPixel ? FontWeight.w400 : FontWeight.w700,
        height: lineHeight,
        color: ink,
      );

  /// Whole bubble including the tail.
  static Size size(String text, {required bool isPixel}) {
    final painter = TextPainter(
      text: TextSpan(text: text.isEmpty ? ' ' : text, style: style(isPixel: isPixel)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    final textSize = painter.size;
    painter.dispose();
    return Size(
      textSize.width + padX * 2,
      textSize.height + padY * 2 + tailH,
    );
  }

  /// Top-left of a bubble of [box] size inside a [width]×[height] card.
  static Offset topLeft(TogetherBubble bubble, Size box, double width, double height) {
    return Offset(
      width / 2 + bubble.x - box.width / 2,
      height / 2 - bubble.y - box.height / 2,
    );
  }
}
