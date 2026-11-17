import 'package:flutter/widgets.dart';

/// One sticker picture (assets/images/link/).
typedef TogetherStickerStyle = ({
  String id,
  String asset,

  /// Width / height of the picture, so it is never stretched.
  double aspect,
  bool premium,
});

/// Stickers placed on the Together widget like speech bubbles: each tap in
/// the decorator adds one, and each can be moved, sized, turned and removed
/// on its own. They are [TogetherBubble]s with [TogetherBubble.sticker] set.
///
/// Adding one needs a subscription, or sharing Dearly's store link once
/// (see StickerUnlock). Placed stickers show to everyone in the room.
abstract final class TogetherSticker {
  static const List<TogetherStickerStyle> styles = [
    (
      id: 'heart_1',
      asset: 'assets/images/link/link_heart_1.png',
      aspect: 1330 / 202,
      premium: false,
    ),
    (
      id: 'heart_2',
      asset: 'assets/images/link/link_heart_2.png',
      aspect: 973 / 255,
      premium: false,
    ),
    (
      id: 'heart_3',
      asset: 'assets/images/link/link_heart_3.png',
      aspect: 1158 / 147,
      premium: false,
    ),
  ];

  /// Width in dp at 100% (the height follows the picture's own shape).
  static const baseWidth = 110.0;

  static TogetherStickerStyle? styleFor(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final style in styles) {
      if (style.id == id) return style;
    }
    return null;
  }

  static bool requiresPremium(String id) => styleFor(id)?.premium ?? false;

  /// Drawn size in dp at [scale] percent, keeping the picture's proportions.
  static Size size(TogetherStickerStyle style, {int scale = 100}) {
    final width = baseWidth * scale / 100;
    return Size(width, width / style.aspect);
  }
}
