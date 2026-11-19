import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quotation/data/ios_fake_wallpaper.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// iPhone "투명" widget setup: a home screen photo stands in for the real
/// wallpaper, which WidgetKit cannot read (see [IosFakeWallpaper]).
abstract final class IosTransparentGuide {
  /// Shows the intro once, on the first Together visit, while no photo is
  /// registered. Returns true when a photo was registered from it.
  static bool _checking = false;

  static Future<bool> maybeShowIntro(BuildContext context) async {
    if (_checking) return false;
    _checking = true;
    try {
      return await _maybeShowIntro(context);
    } finally {
      _checking = false;
    }
  }

  static Future<bool> _maybeShowIntro(BuildContext context) async {
    if (!await IosFakeWallpaper.shouldShowIntro()) return false;
    if (!context.mounted) return false;
    await IosFakeWallpaper.markIntroShown();
    if (!context.mounted) return false;
    return showIntro(context);
  }

  /// Popup with the capture example and a before/after comparison.
  /// Returns true when a photo was registered.
  static Future<bool> showIntro(BuildContext context, {String? roomId}) async {
    final t = AppStrings.current;
    final register = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        return AlertDialog(
          backgroundColor: AppColors.background,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: Text(
            t.iosTransparentIntroTitle,
            style: AppTheme.body.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.iosTransparentIntroBody,
                  style: AppTheme.body.copyWith(fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 16),
                const _Example(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.iosTransparentLater),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: palette.accent),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.iosTransparentRegister),
            ),
          ],
        );
      },
    );
    if (register != true || !context.mounted) return false;
    return pickAndRegister(context, roomId: roomId);
  }

  /// Picks the widget row, then a photo from the album, and saves its
  /// widget-sized crop. A new photo replaces the old one. With [roomId] the
  /// photo is that room's own; without, it is the shared default.
  static Future<bool> pickAndRegister(
    BuildContext context, {
    String? roomId,
  }) async {
    final t = AppStrings.current;
    final slot = await showModalBottomSheet<IosFakeWallpaperSlot>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.iosFakeWallpaperNextTitle,
                  style: AppTheme.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.iosFakeWallpaperNextBody,
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, IosFakeWallpaperSlot.top),
                  child: Text(t.iosFakeWallpaperTop),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, IosFakeWallpaperSlot.mid),
                  child: Text(t.iosFakeWallpaperMid),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (slot == null || !context.mounted) return false;
    final ok = await IosFakeWallpaper.pickAndSave(slot, roomId: roomId);
    if (!context.mounted) return ok;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t.iosFakeWallpaperDone : t.iosFakeWallpaperFailed),
        duration: const Duration(seconds: 3),
      ),
    );
    return ok;
  }
}

class _Example extends StatelessWidget {
  const _Example();

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;
    final caption = AppTheme.body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      // The phone on the left is sized to the before/after pair on the
      // right, so both columns end at the same height.
      // Not a LayoutBuilder: AlertDialog measures its content's intrinsic
      // size, which LayoutBuilder cannot report. The width is known instead:
      // screen − dialog inset (20×2) − content padding (24×2) − this box (12×2).
      child: Builder(
        builder: (context) {
          final dialogW = math.min(
            MediaQuery.sizeOf(context).width - 40,
            560.0,
          );
          const gap = 10.0;
          const captionH = 18.0; // caption line + its 4dp spacing
          const pairAspect = 720 / 420; // before/after pictures
          const phoneAspect = 456 / 950; // capture example
          // Right column: caption, picture, 10dp, caption, picture.
          // Left column: caption + phone, ending at the same height, with the
          // phone exactly as wide as its column. Solving for the widths:
          //   phoneH = captionH + 10 + 2 * rightW / pairAspect
          //   leftW  = phoneH * phoneAspect = total - rightW
          final total = dialogW - 48 - 24 - gap;
          final rightW =
              (total - phoneAspect * (captionH + 10)) /
              (1 + 2 * phoneAspect / pairAspect);
          final leftW = total - rightW;
          final pictureH = rightW / pairAspect;
          final phoneH = captionH + 10 + 2 * pictureH;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: leftW,
                child: Column(
                  children: [
                    SizedBox(
                      height: captionH,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          t.iosTransparentCaptureHint,
                          textAlign: TextAlign.center,
                          style: caption.copyWith(color: palette.accent),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: phoneH,
                      child: Image.asset(
                        IosFakeWallpaper.exampleCaptureAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: gap),
              SizedBox(
                width: rightW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: captionH,
                      child: Text(t.iosTransparentBefore, style: caption),
                    ),
                    SizedBox(
                      height: pictureH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          IosFakeWallpaper.exampleBeforeAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: captionH,
                      child: Text(t.iosTransparentAfter, style: caption),
                    ),
                    SizedBox(
                      height: pictureH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          IosFakeWallpaper.exampleAfterAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Decorate screen, under the backgrounds while "투명" is picked (iPhone):
/// the registered photo as the widget will use it, and a Change button.
class IosTransparentSetting extends StatelessWidget {
  const IosTransparentSetting({
    super.key,
    required this.photoPath,
    required this.onChange,
  });

  final String? photoPath;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;
    final path = photoPath;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 96,
              height: 96 / IosFakeWallpaper.cardAspect,
              child: path == null
                  ? const ColoredBox(color: Colors.white)
                  : Image.file(
                      File(path),
                      // The file is replaced in place; the key forces a reload.
                      key: ValueKey('$path|${_stamp(path)}'),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.iosTransparentSettingTitle,
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (path == null) ...[
                  const SizedBox(height: 2),
                  Text(
                    t.iosTransparentNone,
                    style: AppTheme.body.copyWith(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onChange,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.accent,
              side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              path == null ? t.iosTransparentRegister : t.iosTransparentChange,
              style: AppTheme.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int _stamp(String path) {
    try {
      return File(path).lastModifiedSync().millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }
}
