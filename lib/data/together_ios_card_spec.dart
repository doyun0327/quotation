import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/together_bubble.dart';
import 'package:quotation/data/together_cheer_layout.dart';
import 'package:quotation/data/together_crowd_layout.dart';
import 'package:quotation/data/together_link.dart';
import 'package:quotation/data/widget_fonts.dart';

/// Layout of one iPhone Together card as plain draw commands, drawn natively
/// by the widget extension (TogetherCardRenderer.swift).
///
/// Why: iOS turns the GPU off for apps in the background, and Flutter then
/// postpones every picture until the app is opened again. A friend's edit
/// arrives as a background push, so a Flutter-drawn card only updated after
/// the notification was tapped. Measuring text needs no GPU, so everything
/// is laid out here and the widget only draws it.
///
/// Mirrors [TogetherIosSnapshot]; keep the two in step.
abstract final class TogetherIosCardSpec {
  static const _galmuriAsset = 'assets/fonts/Galmuri11.ttf';

  /// Builds the spec and copies the images and fonts it needs into the app
  /// group. Returns the JSON, or null when a required file could not be
  /// copied (the caller then keeps the previous card).
  static Future<String?> build({
    required Size box,
    required double corner,
    required String label,
    required bool isPixel,
    required int textColor,
    required int textScale,
    required double textX,
    required double textY,
    required double textRotation,
    required WidgetFont textFont,
    required String bgAsset,
    required List<TogetherPlaced> placed,
    required double charW,
    required double charH,
    List<TogetherBubble> bubbles = const [],
    String link = '',
  }) async {
    final width = box.width;
    final height = box.height;
    final out = <String, Object?>{
      'v': 1,
      'w': width,
      'h': height,
      'pixel': isPixel,
    };

    // Background.
    final bgPath = bgAsset.trim();
    if (bgPath.isNotEmpty) {
      final isFile = !bgPath.startsWith('assets/');
      final file = await _sharedImage(bgPath);
      if (file == null) return null;
      out['bg'] = {'file': file, 'fit': isFile ? 'cover' : 'fill'};
    }

    // Cheer text: pre-wrapped lines, shrunk into the inner box (FittedBox).
    final radius = corner.clamp(0.0, 40.0);
    final inner = TogetherCheerLayout.innerSize(width, height, radius);
    final labelStyle = TogetherCheerLayout.style(
      isPixel: isPixel,
      textScale: textScale.toDouble(),
      font: textFont,
    );
    final text = label.trim().isEmpty ? ' ' : label;
    final measured = _measure(text, labelStyle, center: true);
    final fit = math.min(
      1.0,
      math.min(inner.width / measured.width, inner.height / measured.height),
    );
    final labelFamily = await _fontFor(
      textFont.asset ?? (isPixel ? _galmuriAsset : null),
    );
    out['label'] = {
      'text': text,
      'cx': (width - inner.width) / 2 + textX + inner.width / 2,
      'cy': (height - inner.height) / 2 - textY + inner.height / 2,
      'w': measured.width * fit,
      'h': measured.height * fit,
      'size': (labelStyle.fontSize ?? 22) * fit,
      'lineHeight': labelStyle.height ?? 1.2,
      'kern': (labelStyle.letterSpacing ?? 0) * fit,
      // Flutter fakes bold for w900 on a one-weight file; the system font
      // has a real Black weight.
      'weight': (labelStyle.fontWeight ?? FontWeight.w400).value,
      'font': labelFamily,
      'color': textColor,
      'rot': textRotation,
    };

    // Link pictures between neighbours.
    final style = TogetherLink.styleFor(link);
    if (link != TogetherLink.none && style != null) {
      final file = await _sharedImage(style.asset);
      if (file != null) {
        final boxes = [
          for (final slot in placed)
            TogetherLink.box(
              x: slot.x,
              y: slot.y,
              width: charW * slot.scale,
              height: charH * slot.scale,
              cardHeight: height,
            ),
        ];
        out['link'] = {
          'file': file,
          'rects': [
            for (final r in TogetherLink.rects(
              boxes,
              style.aspect,
              heightScale: style.heightScale,
            ))
              [r.left, r.top, r.width, r.height],
          ],
        };
      }
    }

    // Characters: left = 4 + x, bottom = y, contained and rotated.
    final chars = <Map<String, Object?>>[];
    for (final slot in placed) {
      final file = await _sharedImage(
        AppCharacter.byId(slot.characterId).assetPath,
      );
      if (file == null) continue;
      final w = charW * slot.scale;
      final h = charH * slot.scale;
      chars.add({
        'file': file,
        'x': 4 + slot.x,
        'y': height - slot.y - h,
        'w': w,
        'h': h,
        'rot': slot.rotation,
        'sharp': isPixel && slot.rotation % 90 == 0,
      });
    }
    out['chars'] = chars;

    // Speech bubbles: drawn at their natural size, then stretched to [w]x[h].
    if (bubbles.isNotEmpty) {
      final bubbleFamily = await _fontFor(textFont.asset ?? _galmuriAsset);
      final list = <Map<String, Object?>>[];
      for (final bubble in bubbles) {
        final natural = TogetherBubbleLayout.size(
          bubble.text,
          isPixel: isPixel,
          font: textFont,
        );
        final target = TogetherBubbleLayout.size(
          bubble.text,
          isPixel: isPixel,
          font: textFont,
          scale: bubble.scale,
        );
        final topLeft =
            TogetherBubbleLayout.topLeft(bubble, target, width, height);
        list.add({
          'text': bubble.text.isEmpty ? ' ' : bubble.text,
          'x': topLeft.dx,
          'y': topLeft.dy,
          'w': target.width,
          'h': target.height,
          'nw': natural.width,
          'nh': natural.height,
          'rot': bubble.rotation,
          'tail': bubble.tail == TogetherBubbleTail.left ? 'left' : 'right',
          'color': bubble.textColorOn(textColor).toARGB32(),
        });
      }
      out['bubbles'] = {
        'font': bubbleFamily,
        'size': TogetherBubbleLayout.fontSize,
        'lineHeight': TogetherBubbleLayout.lineHeight,
        'padX': TogetherBubbleLayout.padX,
        'padY': TogetherBubbleLayout.padY,
        'tailW': TogetherBubbleLayout.tailW,
        'tailH': TogetherBubbleLayout.tailH,
        'tailInset': TogetherBubbleLayout.tailInset,
        'border': TogetherBubbleLayout.border,
        'fill': TogetherBubbleLayout.fill.toARGB32(),
        'ink': TogetherBubbleLayout.ink.toARGB32(),
        'items': list,
      };
    }
    return jsonEncode(out);
  }

  static Size _measure(String text, TextStyle style, {bool center = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: center ? TextAlign.center : TextAlign.left,
      textScaler: TextScaler.noScaling,
    )..layout();
    final size = painter.size;
    painter.dispose();
    return Size(math.max(size.width, 1), math.max(size.height, 1));
  }

  /// App-group file for a font asset, or null for the system font.
  static Future<String?> _fontFor(String? asset) async {
    if (asset == null) return null;
    return _shared(asset, 'ttf');
  }

  static Future<String?> _sharedImage(String path) => _shared(path, 'png');

  /// Copies [path] (a Flutter asset or a local file) into the app group once
  /// and returns the copy's absolute path. Files are keyed by their path and
  /// modification time, so a replaced album photo is copied again.
  static Future<String?> _shared(String path, String ext) async {
    try {
      final isAsset = path.startsWith('assets/');
      var id = path;
      if (!isAsset) {
        final file = File(path);
        if (!file.existsSync()) return null;
        id = '$path|${file.lastModifiedSync().millisecondsSinceEpoch}';
      }
      final key =
          'tcs_${base64Url.encode(utf8.encode(id)).replaceAll('=', '')}';
      // Long keys are fine for files but not for the UserDefaults index.
      final shortKey = key.length > 120 ? key.substring(key.length - 120) : key;
      final existing = await HomeWidget.getWidgetData<String>(shortKey) ?? '';
      if (existing.isNotEmpty && File(existing).existsSync()) return existing;
      final Uint8List bytes = isAsset
          ? (await rootBundle.load(path)).buffer.asUint8List()
          : await File(path).readAsBytes();
      return await HomeWidget.saveFile(shortKey, bytes, extension: ext);
    } catch (_) {
      return null;
    }
  }
}
