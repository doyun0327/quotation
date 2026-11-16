import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// One picture that can join the characters (assets/images/link/).
typedef TogetherLinkStyle = ({
  String id,
  String asset,

  /// Width / height of the picture, so it is drawn without stretching.
  double aspect,

  /// Multiplies drawn height (1 = natural). Keep in step with Android
  /// [DdayWidgetVisuals.drawImageLink] for the same link id.
  double heightScale,
  bool premium,
});

/// A picture drawn between neighbouring characters on the Together widget,
/// behind them. It keeps its own proportions: only its size follows the
/// gap between the two characters. Android draws the same thing in
/// DdayWidgetVisuals.drawImageLink: keep the numbers here and there in step.
abstract final class TogetherLink {
  static const none = '';

  static const List<TogetherLinkStyle> styles = [
    (
      id: 'heart_1',
      asset: 'assets/images/link/link_heart_1.png',
      aspect: 1330 / 202,
      heightScale: 1,
      premium: false,
    ),
    (
      id: 'heart_2',
      asset: 'assets/images/link/link_heart_2.png',
      aspect: 973 / 255,
      // A touch thicker than the source art.
      heightScale: 1.15,
      premium: true,
    ),
    (
      id: 'heart_3',
      asset: 'assets/images/link/link_heart_3.png',
      aspect: 1158 / 147,
      heightScale: 1,
      premium: false,
    ),
  ];

  static TogetherLinkStyle? styleFor(String? id) {
    for (final style in styles) {
      if (style.id == id) return style;
    }
    return null;
  }

  static String normalize(String? id) => styleFor(id)?.id ?? none;

  /// Subscribers only.
  static bool requiresPremium(String id) => styleFor(id)?.premium ?? false;

  /// Each end sits this far in from a character's center (share of its
  /// box width), at this height of its box.
  static const inset = 0.24;
  static const anchorHeight = 0.66;

  /// Never taller than this share of the characters' height, so a long gap
  /// does not blow the picture up.
  static const maxHeightShare = 0.32;

  /// Where the picture goes between each pair of neighbours (left to right,
  /// so a group gets one chain), in card coordinates.
  static List<Rect> rects(
    List<Rect> boxes,
    double aspect, {
    double heightScale = 1,
  }) {
    if (boxes.length < 2 || aspect <= 0) return const [];
    final scale = heightScale <= 0 ? 1.0 : heightScale;
    final sorted = [...boxes]
      ..sort((a, b) => a.center.dx.compareTo(b.center.dx));
    final out = <Rect>[];
    for (var i = 0; i + 1 < sorted.length; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      final start = a.center.dx + a.width * inset;
      final end = b.center.dx - b.width * inset;
      final gap = end - start;
      if (gap <= 0) continue;
      final y = ((a.top + a.height * anchorHeight) +
              (b.top + b.height * anchorHeight)) /
          2;
      var width = gap;
      var height = width / aspect * scale;
      final maxHeight = maxHeightShare * (a.height + b.height) / 2;
      if (height > maxHeight) {
        height = maxHeight;
        width = height * aspect / scale;
      }
      out.add(Rect.fromCenter(
        center: Offset((start + end) / 2, y),
        width: width,
        height: height,
      ));
    }
    return out;
  }

  /// Card-space box of a sprite placed like the widget does it:
  /// [x] from the left (after the 4dp gutter), [y] up from the bottom.
  static Rect box({
    required double x,
    required double y,
    required double width,
    required double height,
    required double cardHeight,
  }) {
    return Rect.fromLTWH(
      4 + x,
      cardHeight - y - height,
      math.max(0, width),
      math.max(0, height),
    );
  }
}

/// Draws [link] between the character [boxes]. Fills its parent (the card).
/// [image] is the decoded picture for off-screen snapshots, where an asset
/// would not load in time.
class TogetherLinkLayer extends StatelessWidget {
  const TogetherLinkLayer({
    super.key,
    required this.boxes,
    required this.link,
    this.image,
    this.pixel = true,
  });

  final List<Rect> boxes;
  final String link;
  final ui.Image? image;
  final bool pixel;

  @override
  Widget build(BuildContext context) {
    final style = TogetherLink.styleFor(link);
    if (style == null) return const SizedBox.shrink();
    final quality = pixel ? FilterQuality.none : FilterQuality.medium;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final rect in TogetherLink.rects(
          boxes,
          style.aspect,
          heightScale: style.heightScale,
        ))
          Positioned.fromRect(
            rect: rect,
            child: image != null
                ? RawImage(image: image, fit: BoxFit.contain, filterQuality: quality)
                : Image.asset(
                    style.asset,
                    fit: BoxFit.contain,
                    filterQuality: quality,
                    gaplessPlayback: true,
                  ),
          ),
      ],
    );
  }
}
