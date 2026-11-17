import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:quotation/data/together_bg_themes.dart';
import 'package:quotation/data/together_bubble.dart';
import 'package:quotation/data/together_cheer_layout.dart';
import 'package:quotation/data/together_crowd_layout.dart';
import 'package:quotation/data/together_sticker.dart';
import 'package:quotation/data/widget_fonts.dart';
import 'package:quotation/widgets/together_bubble_view.dart';

/// Offscreen Together card for the iOS home widget — same layout as decorate.
class TogetherIosSnapshot extends StatelessWidget {
  const TogetherIosSnapshot({
    super.key,
    required this.width,
    required this.height,
    required this.charW,
    required this.charH,
    required this.label,
    required this.placed,
    required this.images,
    required this.bgImage,
    required this.bgIsFile,
    required this.isPixel,
    required this.textColor,
    required this.textScale,
    required this.textX,
    required this.textY,
    required this.textRotation,
    required this.textFont,
    required this.cornerRadius,
    this.bubbles = const [],
    this.stickerImages = const {},
    /// When false (home widget “투명”), leave clear so SwiftUI
    /// `ultraThinMaterial` shows through. Decorate preview uses glass paint.
    this.glassWhenNoBg = false,
  });

  final double width;
  final double height;
  final double charW;
  final double charH;
  final String label;
  final List<TogetherPlaced> placed;
  final Map<String, ui.Image> images;
  final ui.Image? bgImage;

  /// Album photos use cover (same as [TogetherWidgetPreview]); assets use fill.
  final bool bgIsFile;
  final bool isPixel;
  final int textColor;
  final int textScale;
  final double textX;
  final double textY;
  final double textRotation;
  final WidgetFont textFont;
  final double cornerRadius;
  final List<TogetherBubble> bubbles;
  /// Decoded sticker pictures by asset path (assets do not load in time
  /// off-screen).
  final Map<String, ui.Image> stickerImages;

  /// When there is no theme image, paint iOS frosted glass instead of clear.
  final bool glassWhenNoBg;

  @override
  Widget build(BuildContext context) {
    final radius = cornerRadius.clamp(0.0, 40.0);
    final inner = TogetherCheerLayout.innerSize(width, height, radius);
    final labelStyle = TogetherCheerLayout.style(
      isPixel: isPixel,
      textScale: textScale.toDouble(),
      font: textFont,
    ).copyWith(color: Color(textColor));

    return SizedBox(
      width: width,
      height: height,
      // Square edges: iOS rounds the widget itself, so a rounded clip here
      // would leave white system plate showing in the corners.
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bgImage != null)
              RawImage(
                image: bgImage,
                fit: bgIsFile ? BoxFit.cover : BoxFit.fill,
                filterQuality:
                    isPixel ? FilterQuality.none : FilterQuality.medium,
              )
            else if (glassWhenNoBg)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TogetherBgTheme.iosGlassHighlight,
                      TogetherBgTheme.iosGlassFill,
                      TogetherBgTheme.iosGlassShade,
                    ],
                  ),
                ),
              )
            else
              const ColoredBox(color: Color(0x00000000)),
            Positioned(
              left: (width - inner.width) / 2 + textX,
              top: (height - inner.height) / 2 - textY,
              width: inner.width,
              height: inner.height,
              child: Transform.rotate(
                angle: textRotation * math.pi / 180,
                // [label] is pre-wrapped at the shared width; keep its lines
                // and only scale down, same as the Galaxy widget.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.trim().isEmpty ? ' ' : label,
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: labelStyle,
                  ),
                ),
              ),
            ),
            for (final slot in placed)
              Positioned(
                left: 4 + slot.x,
                bottom: slot.y,
                width: charW * slot.scale,
                height: charH * slot.scale,
                child: Transform.rotate(
                  angle: slot.rotation * math.pi / 180,
                  child: images[slot.characterId] == null
                      ? const SizedBox.shrink()
                      : RawImage(
                          image: images[slot.characterId],
                          fit: BoxFit.contain,
                          filterQuality: isPixel && slot.rotation % 90 == 0
                              ? FilterQuality.none
                              : FilterQuality.medium,
                        ),
                ),
              ),
            for (final bubble in bubbles)
              Positioned(
                left: TogetherBubbleLayout.topLeft(
                  bubble,
                  _bubbleBox(bubble),
                  width,
                  height,
                ).dx,
                top: TogetherBubbleLayout.topLeft(
                  bubble,
                  _bubbleBox(bubble),
                  width,
                  height,
                ).dy,
                child: Transform.rotate(
                  angle: bubble.rotation * math.pi / 180,
                  child: switch (TogetherSticker.styleFor(bubble.sticker)) {
                    final style? => SizedBox.fromSize(
                        size: _bubbleBox(bubble),
                        child: stickerImages[style.asset] == null
                            ? const SizedBox.shrink()
                            : RawImage(
                                image: stickerImages[style.asset],
                                fit: BoxFit.fill,
                                filterQuality: isPixel
                                    ? FilterQuality.none
                                    : FilterQuality.medium,
                              ),
                      ),
                    null => TogetherBubbleView(
                        text: bubble.text,
                        tail: bubble.tail,
                        isPixel: isPixel,
                        font: textFont,
                        textColor: bubble.textColorOn(textColor),
                        scale: bubble.scale,
                      ),
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Size _bubbleBox(TogetherBubble bubble) => TogetherBubbleLayout.size(
        bubble.text,
        isPixel: isPixel,
        font: textFont,
        scale: bubble.scale,
        sticker: bubble.sticker,
      );
}
