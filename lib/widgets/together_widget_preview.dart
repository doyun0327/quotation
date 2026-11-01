import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quotation/data/character_art_insets.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/together_cheer_layout.dart';
import 'package:quotation/data/widget_fonts.dart';

typedef TogetherWidgetPanDelta = void Function(double dx, double dy);

/// One character drawn on the shared widget.
class TogetherPreviewSprite {
  const TogetherPreviewSprite({
    required this.keyId,
    required this.assetPath,
    required this.x,
    required this.y,
    required this.scale,
    this.rotation = 0,
    this.highlight = false,
    this.onPan,
    this.onSelect,
    this.onRotate,
  });

  final String keyId;
  final String assetPath;
  final double x;
  final double y;

  /// Multiplies [TogetherWidgetPreview.charW] and charH.
  final double scale;

  /// Clockwise degrees. The rotate handle exists only while [onRotate] is set.
  final double rotation;
  final bool highlight;
  final TogetherWidgetPanDelta? onPan;
  final VoidCallback? onSelect;
  final ValueChanged<double>? onRotate;
}

Widget _backgroundImage(String path, bool isPixel) {
  final quality = isPixel ? FilterQuality.none : FilterQuality.medium;
  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: BoxFit.fill,
      filterQuality: quality,
      isAntiAlias: !isPixel,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
  return Image.file(
    File(path),
    key: ValueKey(path),
    fit: BoxFit.cover,
    gaplessPlayback: false,
    filterQuality: quality,
    isAntiAlias: !isPixel,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

/// Shared preview for the Together home widget (solo / duo).
class TogetherWidgetPreview extends StatelessWidget {
  const TogetherWidgetPreview({
    super.key,
    required this.width,
    required this.height,
    required this.charW,
    required this.charH,
    required this.label,
    this.labelListenable,
    required this.me,
    required this.friend,
    required this.meX,
    required this.meY,
    required this.friendX,
    required this.friendY,
    required this.isPixel,
    this.textX = 0,
    this.textY = 0,
    this.textRotation = 0,
    this.meScale = 100,
    this.friendScale = 100,
    this.textScale = 100,
    this.bgColor = 0xFFFFF3E8,
    this.bgOpacity = 100,
    this.bgAssetPath,
    this.textColor = 0xFFF26B8A,
    this.textFont = WidgetFont.basic,
    this.shape = TogetherWidgetShape.square,
    this.cornerRadius,
    this.onMePan,
    this.onFriendPan,
    this.onTextPan,
    this.onTextRotate,
    this.onTextSelect,
    this.highlightText = false,
    this.onMeSelect,
    this.onFriendSelect,
    this.highlightMe = false,
    this.highlightFriend = false,
    this.onDragStart,
    this.onDragEnd,
    this.crowd,
  });

  final double width;
  final double height;
  final double charW;
  final double charH;
  final String label;
  /// Typed cheer. When set, only the label rebuilds while the user types.
  final ValueNotifier<String>? labelListenable;
  final AppCharacter me;
  final AppCharacter? friend;
  final double meX;
  final double meY;
  final double friendX;
  final double friendY;
  final double textX;
  final double textY;
  /// Clockwise degrees. Tap the selected label to add 45, same as a character.
  final double textRotation;
  final bool isPixel;
  final int meScale;
  final int friendScale;
  final int textScale;
  final int bgColor;
  final int bgOpacity;
  /// Image theme path; when set, used instead of solid/mosaic fill.
  final String? bgAssetPath;
  final int textColor;
  final WidgetFont textFont;
  final TogetherWidgetShape shape;
  /// Matches Android system widget corner when provided.
  final double? cornerRadius;
  final TogetherWidgetPanDelta? onMePan;
  final TogetherWidgetPanDelta? onFriendPan;
  final TogetherWidgetPanDelta? onTextPan;
  final ValueChanged<double>? onTextRotate;
  final VoidCallback? onTextSelect;
  final bool highlightText;
  final VoidCallback? onMeSelect;
  final VoidCallback? onFriendSelect;
  final bool highlightMe;
  final bool highlightFriend;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  /// When set, these sprites replace the single me/friend pair.
  final List<TogetherPreviewSprite>? crowd;

  /// Same dp as the home widget: measured launcher cell, else One UI span.
  static Size sizeForShape(
    TogetherWidgetShape shape, [
    TogetherWidgetSize widgetSize = TogetherWidgetSize.s42,
    Size? hostSize,
    TogetherWidgetSize? hostForSize,
  ]) {
    final host = hostSize;
    if (host != null && host.width >= 40 && host.height >= 40) {
      final forSize = hostForSize ?? widgetSize;
      if (forSize.cellsW == widgetSize.cellsW &&
          forSize.cellsH == widgetSize.cellsH) {
        return TogetherWidgetSize.fitCardAspect(host);
      }
      final cellW = host.width / forSize.cellsW;
      final cellH = host.height / forSize.cellsH;
      return TogetherWidgetSize.fitCardAspect(
        Size(cellW * widgetSize.cellsW, cellH * widgetSize.cellsH),
      );
    }
    return widgetSize.homeSize(_screenWidthDp());
  }

  static double _screenWidthDp() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 360;
    final width = views.first.physicalSize.width / views.first.devicePixelRatio;
    if (width.isFinite && width > 0) return width;
    return 360;
  }

  /// Border follows the fill — a slightly darker/richer tone of [bgColor].
  static Color borderColorForBg(int bgColor) {
    final hsl = HSLColor.fromColor(Color(bgColor));
    final lightness = (hsl.lightness * 0.78).clamp(0.15, 0.92);
    final saturation = (hsl.saturation * 1.05).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).withSaturation(saturation).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final raw = Color(bgColor);
    final opacity = raw.a == 0
        ? 0.0
        : (raw.a < 1 ? raw.a : (bgOpacity / 100).clamp(0.0, 1.0));
    final color = raw.withValues(alpha: opacity);
    final meFactor = (meScale / 100).clamp(
      DdayController.scaleMin / 100,
      DdayController.charScaleMax / 100,
    );
    final friendFactor = (friendScale / 100).clamp(
      DdayController.scaleMin / 100,
      DdayController.charScaleMax / 100,
    );
    final meW = charW * meFactor;
    final meH = charH * meFactor;
    final friendW = charW * friendFactor;
    final friendH = charH * friendFactor;
    final mePos = TogetherCharacterBounds.me(
      x: meX,
      y: meY,
      width: width,
      height: height,
      charW: meW,
      charH: meH,
      art: CharacterArtInsets.forAsset(me.assetPath),
    );
    final friendPos = TogetherCharacterBounds.me(
      x: friendX,
      y: friendY,
      width: width,
      height: height,
      charW: friendW,
      charH: friendH,
      art: friend == null
          ? CharacterArtInsets.none
          : CharacterArtInsets.forAsset(friend!.assetPath),
    );
    // Same outer corner the launcher clips, so the frame matches the home widget.
    final radius = (cornerRadius ?? 6.0).clamp(0.0, 40.0).toDouble();
    // Stay inside the rounded corner so letters are not clipped.
    final textBox = TogetherCheerLayout.innerSize(width, height, radius);
    final innerW = textBox.width;
    final innerH = textBox.height;
    final labelStyle = TogetherCheerLayout.style(
      isPixel: isPixel,
      textScale: textScale.toDouble(),
      font: textFont,
    ).copyWith(color: Color(textColor));

    Widget panTarget({
      required Widget child,
      required TogetherWidgetPanDelta? onPan,
      VoidCallback? onSelect,
      double rotation = 0,
      ValueChanged<double>? onRotate,
    }) {
      final VoidCallback? onTap = onRotate != null
          ? () {
              onDragStart?.call();
              onRotate((rotation + 45) % 360);
              onDragEnd?.call();
            }
          : onSelect;
      if (onTap == null && onPan == null) return child;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanStart: onPan == null
            ? null
            : (_) {
                onSelect?.call();
                onDragStart?.call();
              },
        onPanUpdate: onPan == null
            ? null
            : (d) => onPan(d.delta.dx, -d.delta.dy),
        onPanEnd: onPan == null
            ? null
            : (_) {
                onDragEnd?.call();
              },
        onPanCancel: onPan == null
            ? null
            : () {
                onDragEnd?.call();
              },
        child: child,
      );
    }

    Widget sprite({
      required String asset,
      required double spriteW,
      required double spriteH,
      required bool highlight,
      required TogetherWidgetPanDelta? onPan,
      required VoidCallback? onSelect,
      double rotation = 0,
      ValueChanged<double>? onRotate,
      bool art = true,
    }) {
      const knob = 36.0;
      const gap = 6.0;
      // Sit a little closer to the picture. The angle still uses the real center.
      const knobDrop = 8.0;
      final showKnob = highlight && onRotate != null;
      final artGap = CharacterArtInsets.forAsset(asset).gaps(spriteW, spriteH);
      // Extra space stays inside this box so the handle can be hit.
      // The picture stays on the bottom edge, so bottom-anchored layout
      // does not shift the character.
      final reach = showKnob ? knob + gap : 0.0;
      return SizedBox(
        width: spriteW,
        height: spriteH + reach,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              width: spriteW,
              height: spriteH,
              child: panTarget(
                onPan: onPan,
                onSelect: onSelect,
                rotation: rotation,
                onRotate: onRotate,
                child: Transform.rotate(
                  alignment: Alignment.center,
                  angle: rotation * math.pi / 180,
                  child: Opacity(
                    opacity: art ? 1 : 0,
                    child: Image.asset(
                      asset,
                      width: spriteW,
                      height: spriteH,
                      fit: BoxFit.contain,
                      filterQuality: rotation % 90 == 0 && isPixel
                          ? FilterQuality.none
                          : FilterQuality.medium,
                      isAntiAlias: !isPixel || rotation % 90 != 0,
                    ),
                  ),
                ),
              ),
            ),
            // Hug the drawn art (per-character transparent margins), not the
            // 3:4 sprite box.
            if (highlight)
              Positioned(
                left: artGap.left,
                bottom: artGap.bottom,
                width: math.max(1.0, spriteW - artGap.left - artGap.right),
                height: math.max(1.0, spriteH - artGap.top - artGap.bottom),
                child: const IgnorePointer(
                  child: CustomPaint(painter: _PixelSelectPainter()),
                ),
              ),
            if (showKnob)
              Positioned(
                left: (spriteW - knob) / 2,
                // Follow the drawn character, not the empty top of the sprite box.
                top: knobDrop + artGap.top,
                width: knob,
                height: knob,
                child: _RotateKnob(
                  spriteHeight: spriteH,
                  gap: gap - knobDrop - artGap.top,
                  onRotate: onRotate,
                  onDragStart: onDragStart,
                  onDragEnd: onDragEnd,
                ),
              ),
          ],
        ),
      );
    }

    final orderedCrowd = crowd == null
        ? const <TogetherPreviewSprite>[]
        : (List<TogetherPreviewSprite>.of(crowd!)
          ..sort((a, b) {
            if (a.highlight == b.highlight) return 0;
            return a.highlight ? 1 : -1;
          }));

    /// [art]: the drawn characters (clipped to the background, no input).
    /// Otherwise: invisible hit area + selection outline + rotate knob, left
    /// unclipped so handles near the edge stay usable.
    List<Widget> spriteLayer({required bool art}) {
      final meSprite = Positioned(
        key: const ValueKey('together-me'),
        left: 4 + mePos.x,
        bottom: mePos.y,
        child: sprite(
          asset: me.assetPath,
          spriteW: meW,
          spriteH: meH,
          highlight: !art && highlightMe,
          onPan: art ? null : onMePan,
          onSelect: art ? null : onMeSelect,
          art: art,
        ),
      );
      final friendSprite = friend == null
          ? null
          : Positioned(
              key: const ValueKey('together-friend'),
              left: 4 + friendPos.x,
              bottom: friendPos.y,
              child: sprite(
                asset: friend!.assetPath,
                spriteW: friendW,
                spriteH: friendH,
                highlight: !art && highlightFriend,
                onPan: art ? null : onFriendPan,
                onSelect: art ? null : onFriendSelect,
                art: art,
              ),
            );
      if (crowd != null) {
        return [
          for (final person in orderedCrowd)
            Positioned(
              key: ValueKey('together-${person.keyId}'),
              left: 4 + person.x,
              bottom: person.y,
              child: sprite(
                asset: person.assetPath,
                spriteW: charW * person.scale,
                spriteH: charH * person.scale,
                highlight: !art && person.highlight,
                onPan: art ? null : person.onPan,
                onSelect: art ? null : person.onSelect,
                rotation: person.rotation,
                onRotate: art ? null : person.onRotate,
                art: art,
              ),
            ),
        ];
      }
      if (highlightMe && friendSprite != null) return [friendSprite, meSprite];
      return [meSprite, ?friendSprite];
    }

    final hasImage = bgAssetPath != null && bgAssetPath!.isNotEmpty;
    final rotatingText = highlightText && onTextRotate != null;
    const textKnob = 36.0;
    const textKnobGap = 6.0;
    const textKnobDrop = 8.0;
    final shownLabel = TogetherCheerLayout.wrapStyled(
      labelListenable?.value ?? label,
      labelStyle,
    );
    // Lines are fixed by the shared wrap width; only scale them to fit.
    final measure = TextPainter(
      text: TextSpan(
        text: shownLabel.isEmpty ? ' ' : shownLabel,
        style: labelStyle,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final rawW = measure.width;
    final rawH = measure.height;
    measure.dispose();
    final fit = rawW <= 0 || rawH <= 0
        ? 1.0
        : math.min(1.0, math.min(innerW / rawW, innerH / rawH));
    final textH = rawH * fit;
    final textTop = (innerH - textH) / 2;
    // Moving stays on the letters. Turning uses the same handle as a character.
    final cheer = panTarget(
      onPan: onTextPan,
      onSelect: onTextSelect,
      child: Transform.rotate(
        alignment: Alignment.center,
        angle: textRotation * math.pi / 180,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Stack(
            children: [
              _LiveCheerText(
                label: label,
                labelListenable: labelListenable,
                style: labelStyle,
              ),
              if (highlightText)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _PixelSelectPainter()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: hasImage
            ? Colors.transparent
            : (opacity <= 0.01 ? Colors.transparent : color),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (hasImage)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: RepaintBoundary(
                  child: _backgroundImage(bgAssetPath!, isPixel),
                ),
              ),
            ),
          Positioned(
            left: (width - innerW) / 2 + textX,
            top: (height - innerH) / 2 - textY,
            width: innerW,
            height: innerH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: cheer),
                if (rotatingText)
                  Positioned(
                    top: textTop - textKnobGap - textKnob + textKnobDrop,
                    left: (innerW - textKnob) / 2,
                    width: textKnob,
                    height: textKnob,
                    child: _RotateKnob(
                      spriteHeight: textH,
                      gap: textKnobGap - textKnobDrop,
                      onRotate: onTextRotate!,
                      onDragStart: onDragStart,
                      onDragEnd: onDragEnd,
                    ),
                  ),
              ],
            ),
          ),
          // Characters are clipped to the background exactly like the home
          // widget, so anything past the edge looks cut off here too.
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: spriteLayer(art: true),
                ),
              ),
            ),
          ),
          ...spriteLayer(art: false),
        ],
      ),
    );
  }
}

/// Cheer label that follows typing without rebuilding the rest of the preview.
class _LiveCheerText extends StatelessWidget {
  const _LiveCheerText({
    required this.label,
    required this.style,
    this.labelListenable,
  });

  final String label;
  final TextStyle style;
  final ValueNotifier<String>? labelListenable;

  @override
  Widget build(BuildContext context) {
    final listenable = labelListenable;
    if (listenable == null) return _text(label);
    return ValueListenableBuilder<String>(
      valueListenable: listenable,
      builder: (context, draft, _) => _text(draft),
    );
  }

  Widget _text(String value) {
    // Same line breaks as the home widget on every device.
    final shown = TogetherCheerLayout.wrapStyled(value, style);
    return Text(
      shown.isEmpty ? ' ' : shown,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
      style: style,
    );
  }
}

/// 1px dashed outline so the selected character reads as pixel art.
class _PixelSelectPainter extends CustomPainter {
  const _PixelSelectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()
      ..color = const Color(0xFF1A1A22)
      ..isAntiAlias = false;
    final light = Paint()
      ..color = const Color(0xFFFFF6E8)
      ..isAntiAlias = false;
    final w = size.width.floor();
    final h = size.height.floor();
    if (w < 2 || h < 2) return;
    void pixel(int x, int y, bool lightOn) {
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        lightOn ? light : dark,
      );
    }

    for (var x = 0; x < w; x++) {
      final lightOn = (x ~/ 2).isEven;
      pixel(x, 0, lightOn);
      pixel(x, h - 1, lightOn);
    }
    for (var y = 1; y < h - 1; y++) {
      final lightOn = (y ~/ 2).isEven;
      pixel(0, y, lightOn);
      pixel(w - 1, y, lightOn);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Drag handle shown above the selected character in the widget decorator.
class _RotateKnob extends StatefulWidget {
  const _RotateKnob({
    required this.spriteHeight,
    required this.gap,
    required this.onRotate,
    this.onDragStart,
    this.onDragEnd,
  });

  final double spriteHeight;
  final double gap;
  final ValueChanged<double> onRotate;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  @override
  State<_RotateKnob> createState() => _RotateKnobState();
}

class _RotateKnobState extends State<_RotateKnob> {
  /// Degrees from the sprite center to the finger.
  /// 0 is upright. The same angle turns the picture so the head points at the finger.
  double _degrees(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;
    final knob = box.localToGlobal(box.size.center(Offset.zero));
    final center = knob +
        Offset(0, box.size.height / 2 + widget.gap + widget.spriteHeight / 2);
    final delta = global - center;
    return math.atan2(delta.dx, -delta.dy) * 180 / math.pi;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        widget.onDragStart?.call();
        widget.onRotate(_degrees(details.globalPosition));
      },
      onPanUpdate: (details) {
        widget.onRotate(_degrees(details.globalPosition));
      },
      onPanEnd: (_) => widget.onDragEnd?.call(),
      onPanCancel: () => widget.onDragEnd?.call(),
      child: const Center(
        child: Icon(
          Icons.rotate_right_rounded,
          size: 22,
          color: Color(0xFF5C5348),
        ),
      ),
    );
  }
}

/// Keeps a character sprite fully inside the widget background.
abstract final class TogetherCharacterBounds {
  static ({double x, double y}) me({
    required double x,
    required double y,
    required double width,
    required double height,
    required double charW,
    required double charH,
    CharacterArtInsets art = CharacterArtInsets.none,
  }) {
    // Bound the drawn art, not the sprite box: the image is contained in a
    // 3:4 box and each character has its own transparent margins, so the
    // box edge kept a standing character away from the walls and floor.
    // Sprite left = 4 + x, bottom = y.
    final gap = art.gaps(charW, charH);
    final loX = -4 - gap.left;
    final maxX = width - 4 - charW + gap.right;
    final hiX = maxX < loX ? loX : maxX;
    final loY = -gap.bottom;
    final maxY = height - charH + gap.top;
    final hiY = maxY < loY ? loY : maxY;
    return (x: x.clamp(loX, hiX).toDouble(), y: y.clamp(loY, hiY).toDouble());
  }

  static ({double x, double y}) friend({
    required double x,
    required double y,
    required double width,
    required double height,
    required double charW,
    required double charH,
    CharacterArtInsets art = CharacterArtInsets.none,
  }) {
    return me(
      x: x,
      y: y,
      width: width,
      height: height,
      charW: charW,
      charH: charH,
      art: art,
    );
  }
}
