import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quotation/data/home_widget_sync.dart';

/// Vertical placement of the systemMedium cell on a home screenshot.
enum IosFakeWallpaperSlot { top, mid }

/// Widgy-style fake transparent wallpaper for the iPhone Together widget.
///
/// WidgetKit cannot read the live Home Screen wallpaper. The user registers a
/// blank home screenshot; we crop the medium-widget region and share it through
/// the App Group so the extension can blur it under a clear card.
abstract final class IosFakeWallpaper {
  static const keyTop = 'togetherFakeWallpaperTop';
  static const keyMid = 'togetherFakeWallpaperMid';
  static const keySlot = 'togetherFakeWallpaperSlot';

  /// Soft blank home stand-in bundled for iPhone transparent testing.
  static const blankHomeAsset =
      'assets/images/widgetbackground/ios_blank_home.png';

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String keyFor(IosFakeWallpaperSlot slot) =>
      slot == IosFakeWallpaperSlot.top ? keyTop : keyMid;

  /// Medium Together card aspect (width / height), same as Galaxy / iOS PNG.
  static const cardAspect = 2.14;

  /// Seeds App Group crops from [blankHomeAsset].
  /// [force] rewrites even when a wallpaper is already registered.
  static Future<void> ensureDefault({bool force = false}) async {
    if (!isIOS) return;
    if (!force && await hasAny()) return;
    await seedFromAsset(blankHomeAsset);
  }

  /// Writes top + mid crops from a bundled (or absolute) image into App Group.
  static Future<bool> seedFromAsset(String assetPath) async {
    if (!isIOS) return false;
    final bytes = assetPath.startsWith('assets/')
        ? (await rootBundle.load(assetPath)).buffer.asUint8List()
        : await File(assetPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    try {
      await HomeWidget.setAppGroupId(HomeWidgetSync.appGroupId);
      var ok = true;
      for (final slot in IosFakeWallpaperSlot.values) {
        final cropped = await _cropForSlot(src, slot);
        if (cropped == null) {
          ok = false;
          continue;
        }
        try {
          await HomeWidget.renderFlutterWidget(
            RawImage(image: cropped, fit: BoxFit.fill),
            key: keyFor(slot),
            logicalSize: Size(cropped.width / 3.0, cropped.height / 3.0),
            pixelRatio: 3,
          );
        } finally {
          cropped.dispose();
        }
      }
      await HomeWidget.saveWidgetData<String>(keySlot, 'top');
      await HomeWidget.updateWidget(iOSName: HomeWidgetSync.iosTogetherName);
      return ok;
    } finally {
      src.dispose();
    }
  }

  /// Picks a photo, crops the medium-widget band for [slot], writes it into
  /// the App Group via [HomeWidget.renderFlutterWidget].
  static Future<bool> pickAndSave(IosFakeWallpaperSlot slot) async {
    if (!isIOS) return false;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return false;
    final bytes = await picked.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    try {
      final cropped = await _cropForSlot(src, slot);
      if (cropped == null) return false;
      try {
        await HomeWidget.setAppGroupId(HomeWidgetSync.appGroupId);
        await HomeWidget.renderFlutterWidget(
          RawImage(image: cropped, fit: BoxFit.fill),
          key: keyFor(slot),
          logicalSize: Size(
            cropped.width / 3.0,
            cropped.height / 3.0,
          ),
          pixelRatio: 3,
        );
        await HomeWidget.saveWidgetData<String>(
          keySlot,
          slot == IosFakeWallpaperSlot.top ? 'top' : 'mid',
        );
        await HomeWidget.updateWidget(iOSName: HomeWidgetSync.iosTogetherName);
        return true;
      } finally {
        cropped.dispose();
      }
    } finally {
      src.dispose();
    }
  }

  static Future<bool> hasAny() async {
    if (!isIOS) return false;
    await HomeWidget.setAppGroupId(HomeWidgetSync.appGroupId);
    for (final key in [keyTop, keyMid]) {
      final path = await HomeWidget.getWidgetData<String>(key) ?? '';
      if (path.isNotEmpty && File(path).existsSync()) return true;
    }
    return false;
  }

  /// Crops a landscape band matching the medium widget from a portrait
  /// home screenshot. [Slot.top] / [Slot.mid] pick vertical origin.
  static Future<ui.Image?> _cropForSlot(
    ui.Image src,
    IosFakeWallpaperSlot slot,
  ) async {
    final sw = src.width.toDouble();
    final sh = src.height.toDouble();
    if (sw < 8 || sh < 8) return null;

    // ~screen content width inside typical home padding.
    final cropW = sw * 0.90;
    final cropH = cropW / cardAspect;
    final left = (sw - cropW) / 2;
    final topFrac = slot == IosFakeWallpaperSlot.top ? 0.14 : 0.36;
    var top = sh * topFrac;
    if (top + cropH > sh) top = (sh - cropH).clamp(0.0, sh);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dest = Rect.fromLTWH(0, 0, cropW, cropH);
    final source = Rect.fromLTWH(left, top, cropW, cropH);
    canvas.drawImageRect(src, source, dest, Paint());
    final picture = recorder.endRecording();
    return picture.toImage(cropW.round(), cropH.round());
  }
}
