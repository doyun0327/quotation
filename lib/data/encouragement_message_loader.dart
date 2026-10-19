import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:quotation/l10n/locale_controller.dart';

enum EncouragementSlot {
  morning(prefix: 'morning_', hour: 8, minute: 0),
  lunch(prefix: 'lunch_', hour: 12, minute: 0),
  evening(prefix: 'evening_', hour: 20, minute: 0);

  const EncouragementSlot({
    required this.prefix,
    required this.hour,
    required this.minute,
  });

  final String prefix;
  final int hour;
  final int minute;
}

class EncouragementMessage {
  const EncouragementMessage({
    required this.day,
    required this.title,
    required this.body,
  });

  final int day;
  final String title;
  final String body;
}

abstract final class EncouragementMessageLoader {
  static final Map<String, List<EncouragementMessage>> _cache = {};

  static Future<List<EncouragementMessage>> load(
    EncouragementSlot slot, {
    String? languageId,
  }) async {
    final lang = languageId ?? localeController.language.id;
    final cacheKey = '${slot.name}:$lang';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final path = await _findAssetPath(slot, lang);
    if (path == null) {
      _cache[cacheKey] = const [];
      return _cache[cacheKey]!;
    }

    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _cache[cacheKey] = const [];
      return _cache[cacheKey]!;
    }

    _cache[cacheKey] = [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          EncouragementMessage(
            day: item['day'] is int
                ? item['day'] as int
                : int.tryParse('${item['day']}') ?? 0,
            title: _text(item['title']),
            body: _text(item['body']),
          ),
    ].where((m) => m.title.isNotEmpty && m.body.isNotEmpty).toList(
          growable: false,
        );
    return _cache[cacheKey]!;
  }

  static void clearCache() => _cache.clear();

  /// Deterministic daily pick (local calendar day + slot).
  static EncouragementMessage? pickForDate(
    DateTime date,
    EncouragementSlot slot,
    List<EncouragementMessage> pool,
  ) {
    if (pool.isEmpty) return null;
    final key =
        '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}:${slot.name}';
    return pool[Random(key.hashCode).nextInt(pool.length)];
  }

  static EncouragementMessage? pickRandom(List<EncouragementMessage> pool) {
    if (pool.isEmpty) return null;
    return pool[Random().nextInt(pool.length)];
  }

  static Future<String?> _findAssetPath(
    EncouragementSlot slot,
    String languageId,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    String? matchIn(String lang) {
      final matches = assets.where((asset) {
        if (!asset.startsWith('assets/quotes/$lang/')) return false;
        final name = asset.split('/').last;
        return name.startsWith(slot.prefix) && name.endsWith('.json');
      }).toList()
        ..sort();
      return matches.isEmpty ? null : matches.first;
    }

    return matchIn(languageId) ?? matchIn('ko');
  }

  static String _text(Object? value) =>
      value is String ? value.trim() : '';
}
