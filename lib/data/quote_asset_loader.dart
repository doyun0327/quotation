import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quotation/data/quote_models.dart';

abstract final class QuoteAssetLoader {
  static const christianKoPath =
      'assets/quotes/ko/bible_reflections_1000_audited.json';
  static const buddhismKoPath =
      'assets/quotes/ko/buddhist_reflections_1000.json';

  static Future<List<Quote>> loadChristianKo() => _loadList(
        path: christianKoPath,
        idPrefix: 'faith_christian_',
        authorOf: (item) {
          final reference = _text(item['reference']);
          return reference.isNotEmpty ? reference : '성경';
        },
      );

  static Future<List<Quote>> loadBuddhismKo() => _loadList(
        path: buddhismKoPath,
        idPrefix: 'faith_buddhism_',
        authorOf: (item) {
          final source = _text(item['source']);
          final chapter = _text(item['chapter']);
          final verse = _text(item['verse']);
          final parts = <String>[
            if (source.isNotEmpty) source,
            if (chapter.isNotEmpty || verse.isNotEmpty)
              [chapter, verse].where((p) => p.isNotEmpty).join(' '),
          ];
          if (parts.isEmpty) return '불교 경전';
          return parts.join(' · ');
        },
      );

  static Future<List<Quote>> _loadList({
    required String path,
    required String idPrefix,
    required String Function(Map<String, dynamic> item) authorOf,
  }) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          Quote(
            id: '$idPrefix${item['id']}',
            text: _text(item['text']),
            author: authorOf(item),
          ),
    ].where((q) => q.text.isNotEmpty).toList(growable: false);
  }

  static String _text(Object? value) =>
      value is String ? value.trim() : '';
}
