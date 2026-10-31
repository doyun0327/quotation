import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quotation/data/widget_fonts.dart';

/// Cheer text box shared by the decorate preview and the home widget.
///
/// Line breaks are computed here and stored with newlines so Android draws
/// the same lines, then both sides shrink the block into this box.
abstract final class TogetherCheerLayout {
  static double insetX(double cornerDp) => math.max(cornerDp, 16);

  static double insetY(double cornerDp) => math.max(cornerDp, 12);

  static Size innerSize(double width, double height, double cornerDp) {
    return Size(
      (width - insetX(cornerDp) * 2).clamp(8.0, width),
      (height - insetY(cornerDp) * 2).clamp(8.0, height),
    );
  }

  static TextStyle style({
    required bool isPixel,
    required double textScale,
    WidgetFont font = WidgetFont.basic,
  }) {
    final factor = (textScale / 100).clamp(0.6, 2.4);
    final family = font.family;
    if (family != null) {
      // Bundled fonts ship one weight. A heavier weight would fake bold here
      // while Android draws the plain face, so the lines would differ.
      return TextStyle(
        fontFamily: family,
        fontSize: 22.0 * factor,
        fontWeight: FontWeight.w400,
        height: 1.2,
      );
    }
    return TextStyle(
      fontFamily: isPixel ? 'Galmuri' : null,
      fontSize: (isPixel ? 16.0 : 22.0) * factor,
      fontWeight: FontWeight.w900,
      height: 1.2,
      letterSpacing: isPixel ? null : -0.1,
    );
  }

  /// Fixed wrap width (dp) on every device: the text box of the 4×2 card on a
  /// 360dp phone (301 − 2×28). Wrapping against each phone's own box gave a
  /// wider iPhone fewer lines than a Galaxy for the same cheer.
  static const double wrapWidth = 245;

  /// Wrap [text] at [wrapWidth], joined with newlines. Renderers draw these
  /// lines as-is and only scale the block down to fit, so the line count is
  /// the same on iPhone and Galaxy.
  static String wrap({
    required String text,
    required bool isPixel,
    required double textScale,
    WidgetFont font = WidgetFont.basic,
  }) {
    return wrapStyled(
      text,
      style(isPixel: isPixel, textScale: textScale, font: font),
    );
  }

  /// [wrap] with an already-built [textStyle] (color etc. ignored).
  static String wrapStyled(String text, TextStyle textStyle) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final painter = TextPainter(
      text: TextSpan(text: trimmed, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: wrapWidth);
    final lines = <String>[];
    var cursor = 0;
    final count = painter.computeLineMetrics().length;
    for (var i = 0; i < count && cursor < trimmed.length; i++) {
      final range = painter.getLineBoundary(TextPosition(offset: cursor));
      final end = range.end.clamp(cursor + 1, trimmed.length);
      lines.add(trimmed.substring(range.start.clamp(0, trimmed.length), end).trimRight());
      cursor = end;
      if (cursor < trimmed.length && trimmed[cursor] == '\n') cursor++;
    }
    painter.dispose();
    if (lines.isEmpty) return trimmed;
    return lines.join('\n');
  }
}
