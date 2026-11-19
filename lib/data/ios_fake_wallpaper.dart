import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Each room keeps its own photo. Same id encoding as the room cards
  /// ("togetherCard_…"); TogetherWidget.swift builds the same keys.
  static String roomKey(String roomId) =>
      base64Url.encode(utf8.encode(roomId)).replaceAll('=', '');

  static String keyForRoom(IosFakeWallpaperSlot slot, String roomId) =>
      '${keyFor(slot)}_${roomKey(roomId)}';

  static String slotKeyForRoom(String roomId) =>
      '${keySlot}_${roomKey(roomId)}';

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
          await _store(cropped, keyFor(slot));
        } finally {
          cropped.dispose();
        }
      }
      await HomeWidget.saveWidgetData<String>(keySlot, 'top');
      await HomeWidgetSync.reloadAllIos();
      return ok;
    } finally {
      src.dispose();
    }
  }

  /// Picks a photo, crops the medium-widget band for [slot], writes it into
  /// the App Group via [HomeWidget.renderFlutterWidget].
  static Future<bool> pickAndSave(
    IosFakeWallpaperSlot slot, {
    String? roomId,
  }) async {
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
        // No room (first-visit intro): the shared photo every room without
        // its own uses.
        await _store(
          cropped,
          roomId == null ? keyFor(slot) : keyForRoom(slot, roomId),
        );
        await HomeWidget.saveWidgetData<String>(
          roomId == null ? keySlot : slotKeyForRoom(roomId),
          slot == IosFakeWallpaperSlot.top ? 'top' : 'mid',
        );
        // Every kind at once: "방 2"… and the add-widget gallery would
        // otherwise keep the old photo until the room cards are redrawn.
        await HomeWidgetSync.reloadAllIos();
        return true;
      } finally {
        cropped.dispose();
      }
    } finally {
      src.dispose();
    }
  }

  /// Renders [cropped] into the App Group under a new file name each time.
  ///
  /// home_widget always writes `{key}.png`, so a changed photo kept the old
  /// path: Flutter's image cache (and the widget) went on showing the first
  /// photo. A fresh name per save makes every reader load the new one.
  static Future<void> _store(ui.Image cropped, String key) async {
    final previous = await HomeWidget.getWidgetData<String>(key) ?? '';
    final base = await HomeWidget.renderFlutterWidget(
      RawImage(image: cropped, fit: BoxFit.fill),
      key: key,
      logicalSize: Size(cropped.width / 3.0, cropped.height / 3.0),
      pixelRatio: 3,
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final versioned = base.replaceFirst(RegExp(r'\.png$'), '_$stamp.png');
    var stored = base;
    try {
      await File(base).rename(versioned);
      stored = versioned;
    } on FileSystemException {
      // Keep the plain name; the widget still reads it.
    }
    await HomeWidget.saveWidgetData<String>(key, stored);
    if (previous.isNotEmpty && previous != stored && previous != base) {
      try {
        await File(previous).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
  }

  /// Drops [roomId]'s own transparent photo (both crops and the row choice)
  /// when the room is left; other rooms and the shared photo stay.
  static Future<void> forgetRoom(String roomId) async {
    if (!isIOS) return;
    try {
      await HomeWidget.setAppGroupId(HomeWidgetSync.appGroupId);
      for (final slot in IosFakeWallpaperSlot.values) {
        final key = keyForRoom(slot, roomId);
        final path = await HomeWidget.getWidgetData<String>(key) ?? '';
        if (path.isNotEmpty) {
          try {
            await File(path).delete();
          } on FileSystemException {
            // Already gone.
          }
        }
        await HomeWidget.saveWidgetData<String>(key, null);
      }
      await HomeWidget.saveWidgetData<String>(slotKeyForRoom(roomId), null);
    } catch (e) {
      debugPrint('forget wallpaper $roomId: $e');
    }
  }

  static const _introShownKey = 'ios_transparent_intro_shown';

  /// Example pictures for the intro popup (made from [blankHomeAsset]).
  static const exampleCaptureAsset =
      'assets/images/widgetbackground/ios_capture_example.png';
  static const exampleBeforeAsset =
      'assets/images/widgetbackground/ios_transparent_before.png';
  static const exampleAfterAsset =
      'assets/images/widgetbackground/ios_transparent_after.png';

  /// First Together visit on iPhone with no photo yet, shown once.
  static Future<bool> shouldShowIntro([String? roomId]) async {
    if (!isIOS) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_introShownKey) ?? false) return false;
    return await currentPath(roomId) == null;
  }

  static Future<void> markIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introShownKey, true);
  }

  /// The crop [roomId]'s widget uses now (its chosen row), or null if none.
  /// A room without its own photo uses the one registered before photos
  /// were per room.
  static Future<String?> currentPath([String? roomId]) async {
    if (!isIOS) return null;
    await HomeWidget.setAppGroupId(HomeWidgetSync.appGroupId);
    final own = roomId == null
        ? null
        : await _pathFor(
            slotKey: slotKeyForRoom(roomId),
            top: keyForRoom(IosFakeWallpaperSlot.top, roomId),
            mid: keyForRoom(IosFakeWallpaperSlot.mid, roomId),
          );
    return own ?? await _pathFor(slotKey: keySlot, top: keyTop, mid: keyMid);
  }

  static Future<String?> _pathFor({
    required String slotKey,
    required String top,
    required String mid,
  }) async {
    final slot = await HomeWidget.getWidgetData<String>(slotKey) ?? 'top';
    final order = slot == 'mid' ? [mid, top] : [top, mid];
    for (final key in order) {
      final path = await HomeWidget.getWidgetData<String>(key) ?? '';
      if (path.isNotEmpty && File(path).existsSync()) return path;
    }
    return null;
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
