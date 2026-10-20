import 'package:flutter/material.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';

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
    this.charScale = 100,
    this.textScale = 100,
    this.bgColor = 0xFFFFF3E8,
    this.bgOpacity = 100,
    this.textColor = 0xFFF26B8A,
    this.shape = TogetherWidgetShape.square,
    this.onMePan,
    this.onFriendPan,
    this.onTextPan,
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
  final int charScale;
  final int textScale;
  final int bgColor;
  final int bgOpacity;
  final int textColor;
  final TogetherWidgetShape shape;
  final TogetherWidgetPanDelta? onMePan;
  final TogetherWidgetPanDelta? onFriendPan;
  final TogetherWidgetPanDelta? onTextPan;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  /// Canvas sized like a filled home-screen cell (screenWidth/4 × cells).
  static Size sizeForShape(
    TogetherWidgetShape shape, [
    TogetherWidgetSize widgetSize = TogetherWidgetSize.s42,
    double? cellDp,
  ]) {
    final cell = cellDp ?? 88.0;
    return Size(widgetSize.boxWFor(cell), widgetSize.boxHFor(cell));
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
    // Prefer ARGB alpha on the color (transparent swatch); fall back to legacy opacity %.
    final opacity = raw.a == 0
        ? 0.0
        : (raw.a < 1 ? raw.a : (bgOpacity / 100).clamp(0.0, 1.0));
    final color = raw.withValues(alpha: opacity);
    final borderColor = opacity <= 0.01
        ? const Color(0x66B0B8C6)
        : borderColorForBg(bgColor).withValues(alpha: opacity.clamp(0.35, 1.0));
    final charFactor = (charScale / 100).clamp(0.6, 1.6);
    final textFactor = (textScale / 100).clamp(0.6, 1.6);
    final cw = charW * charFactor;
    final ch = charH * charFactor;
    // Always rounded rectangle ("둥근 네모").
    final radius = isPixel ? 6.0 : 20.0;
    // Pixel body face is Galmuri (Korean); PressStart2P lacks Hangul glyphs.
    final labelStyle = AppTheme.body.copyWith(
      fontFamily: isPixel ? 'Galmuri' : null,
      fontSize: (isPixel ? 16.0 : 22.0) * textFactor,
      fontWeight: FontWeight.w900,
      color: Color(textColor),
      height: 1.2,
    );

    Widget panTarget({
      required Widget child,
      required TogetherWidgetPanDelta? onPan,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPan == null
            ? null
            : (_) {
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

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor,
          width: isPixel ? 2 : 1.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(textX, -textY),
              child: panTarget(
                onPan: onTextPan,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    label.trim().isEmpty ? ' ' : label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
              ),
            ),
          ),
          if (friend != null)
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: const Offset(-40, 0),
                child: isPixel
                    ? const DdayPixelIcon(
                        kind: DdayIconKind.heart,
                        size: 16,
                      )
                    : const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Color(0xFFF5A0B8),
                      ),
              ),
            ),
          Positioned(
            left: 4 + meX,
            bottom: meY,
            child: panTarget(
              onPan: onMePan,
              child: Image.asset(
                me.assetPath,
                width: cw,
                height: ch,
                fit: BoxFit.contain,
                filterQuality:
                    isPixel ? FilterQuality.none : FilterQuality.medium,
                isAntiAlias: !isPixel,
              ),
            ),
          ),
          if (friend != null)
            Positioned(
              right: 4 - friendX,
              bottom: friendY,
              child: panTarget(
                onPan: onFriendPan,
                child: Image.asset(
                  friend!.assetPath,
                  width: cw,
                  height: ch,
                  fit: BoxFit.contain,
                  filterQuality:
                      isPixel ? FilterQuality.none : FilterQuality.medium,
                  isAntiAlias: !isPixel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
