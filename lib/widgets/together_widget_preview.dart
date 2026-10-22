import 'package:flutter/material.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/together_cheer_layout.dart';

typedef TogetherWidgetPanDelta = void Function(double dx, double dy);

/// Shared preview for the Together home widget (solo / duo).
class TogetherWidgetPreview extends StatelessWidget {
  const TogetherWidgetPreview({
    super.key,
    required this.width,
    required this.height,
    required this.charW,
    required this.charH,
    required this.label,
    required this.me,
    required this.friend,
    required this.meX,
    required this.meY,
    required this.friendX,
    required this.friendY,
    required this.isPixel,
    this.textX = 0,
    this.textY = 0,
    this.meScale = 100,
    this.friendScale = 100,
    this.textScale = 100,
    this.bgColor = 0xFFFFF3E8,
    this.bgOpacity = 100,
    this.bgAssetPath,
    this.textColor = 0xFFF26B8A,
    this.shape = TogetherWidgetShape.square,
    this.cornerRadius,
    this.onMePan,
    this.onFriendPan,
    this.onTextPan,
    this.onTextSelect,
    this.highlightText = false,
    this.onMeSelect,
    this.onFriendSelect,
    this.highlightMe = false,
    this.highlightFriend = false,
    this.onDragStart,
    this.onDragEnd,
  });

  final double width;
  final double height;
  final double charW;
  final double charH;
  final String label;
  final AppCharacter me;
  final AppCharacter? friend;
  final double meX;
  final double meY;
  final double friendX;
  final double friendY;
  final double textX;
  final double textY;
  final bool isPixel;
  final int meScale;
  final int friendScale;
  final int textScale;
  final int bgColor;
  final int bgOpacity;
  /// Image theme path; when set, used instead of solid/mosaic fill.
  final String? bgAssetPath;
  final int textColor;
  final TogetherWidgetShape shape;
  /// Matches Android system widget corner when provided.
  final double? cornerRadius;
  final TogetherWidgetPanDelta? onMePan;
  final TogetherWidgetPanDelta? onFriendPan;
  final TogetherWidgetPanDelta? onTextPan;
  final VoidCallback? onTextSelect;
  final bool highlightText;
  final VoidCallback? onMeSelect;
  final VoidCallback? onFriendSelect;
  final bool highlightMe;
  final bool highlightFriend;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

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
        return host;
      }
      final cellW = host.width / forSize.cellsW;
      final cellH = host.height / forSize.cellsH;
      return Size(cellW * widgetSize.cellsW, cellH * widgetSize.cellsH);
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
      DdayController.scaleMax / 100,
    );
    final friendFactor = (friendScale / 100).clamp(
      DdayController.scaleMin / 100,
      DdayController.scaleMax / 100,
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
    );
    final friendPos = TogetherCharacterBounds.me(
      x: friendX,
      y: friendY,
      width: width,
      height: height,
      charW: friendW,
      charH: friendH,
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
    ).copyWith(color: Color(textColor));

    Widget panTarget({
      required Widget child,
      required TogetherWidgetPanDelta? onPan,
      VoidCallback? onSelect,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
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
    }) {
      return panTarget(
        onPan: onPan,
        onSelect: onSelect,
        child: SizedBox(
          width: spriteW,
          height: spriteH,
          child: Stack(
            children: [
              Image.asset(
                asset,
                width: spriteW,
                height: spriteH,
                fit: BoxFit.contain,
                filterQuality:
                    isPixel ? FilterQuality.none : FilterQuality.medium,
                isAntiAlias: !isPixel,
              ),
              if (highlight)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _PixelSelectPainter()),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final meSprite = Positioned(
      key: const ValueKey('together-me'),
      left: 4 + mePos.x,
      bottom: mePos.y,
      child: sprite(
        asset: me.assetPath,
        spriteW: meW,
        spriteH: meH,
        highlight: highlightMe,
        onPan: onMePan,
        onSelect: onMeSelect,
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
              highlight: highlightFriend,
              onPan: onFriendPan,
              onSelect: onFriendSelect,
            ),
          );

    final hasImage = bgAssetPath != null && bgAssetPath!.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: hasImage
            ? Colors.transparent
            : (opacity <= 0.01 ? Colors.transparent : color),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (hasImage)
            Positioned.fill(
              child: RepaintBoundary(
                child: Image.asset(
                  bgAssetPath!,
                  fit: BoxFit.fill,
                  filterQuality:
                      isPixel ? FilterQuality.none : FilterQuality.medium,
                  isAntiAlias: !isPixel,
                ),
              ),
            ),
          Positioned(
            left: (width - innerW) / 2 + textX,
            top: (height - innerH) / 2 - textY,
            width: innerW,
            height: innerH,
            child: panTarget(
              onPan: onTextPan,
              onSelect: onTextSelect,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: innerW),
                  child: Stack(
                    children: [
                      Text(
                        label.trim().isEmpty ? ' ' : label,
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
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
            ),
          ),
          if (highlightMe && friendSprite != null) ...[
            friendSprite,
            meSprite,
          ] else ...[
            meSprite,
            ?friendSprite,
          ],
        ],
      ),
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

/// Keeps a character sprite fully inside the widget background.
abstract final class TogetherCharacterBounds {
  static ({double x, double y}) me({
    required double x,
    required double y,
    required double width,
    required double height,
    required double charW,
    required double charH,
  }) {
    final maxX = width - 4 - charW;
    final hiX = maxX < -4 ? -4.0 : maxX;
    final maxY = height - charH;
    final hiY = maxY < 0 ? 0.0 : maxY;
    return (x: x.clamp(-4.0, hiX).toDouble(), y: y.clamp(0.0, hiY).toDouble());
  }

  static ({double x, double y}) friend({
    required double x,
    required double y,
    required double width,
    required double height,
    required double charW,
    required double charH,
  }) {
    return me(
      x: x,
      y: y,
      width: width,
      height: height,
      charW: charW,
      charH: charH,
    );
  }
}
