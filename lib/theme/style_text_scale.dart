import 'package:flutter/widgets.dart';
import 'package:quotation/theme/font_scale_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';

/// Keeps the letters the same size in the pixel and the clean look.
///
/// The pixel font (Galmuri) draws wider and taller letters than the phone's
/// own font at the same font size: about 9% wider in Korean and up to 14%
/// taller in Latin letters. So the same "보통" size looked smaller as soon as
/// the clean look was picked. In the clean look every text is scaled up by
/// [cleanBoost] on top of the size chosen in Settings.
abstract final class StyleTextScale {
  static const cleanBoost = 1.1;

  /// The text scale for the whole app.
  static double get appScale =>
      fontScaleController.scale *
      (visualStyleController.isClean ? cleanBoost : 1.0);

  /// For screens that always draw in the pixel font, also in the clean look
  /// (the widget decorator): their letters already are pixel-sized, so the
  /// boost is taken off again there.
  static Widget pixelOnly(BuildContext context, Widget child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(fontScaleController.scale),
      ),
      child: child,
    );
  }
}
