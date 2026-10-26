import 'package:flutter/material.dart';

class HamfootIcon extends StatelessWidget {
  const HamfootIcon({
    super.key,
    required this.size,
    this.active = true,
    this.color,
  });

  static const asset = 'assets/images/like/hamfoot.png';

  final double size;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
    );
    final tint = color;
    if (tint != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        child: image,
      );
    }
    if (!active) {
      return Opacity(opacity: 0.35, child: image);
    }
    return image;
  }
}
