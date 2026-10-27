import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quotation/data/quote_models.dart';

abstract final class QuoteAssetLoader {
  static const christianKoPath =
      'assets/quotes/ko/bible_reflections_1000_audited.json';
  static const buddhismKoPath =
      'assets/quotes/ko/buddhist_reflections_1000.json';
  static const gratitudeKoPath =
      'assets/quotes/ko/dearly_gratitude_joy_quotes_500.json';
  static const gratitudeEnPath =
      'assets/quotes/en/dearly_gratitude_joy_quotes_500_en.json';
  static const loveKoPath =
      'assets/quotes/ko/dearly_love_relationship_quotes_400.json';
  static const loveEnPath =
      'assets/quotes/en/dearly_love_relationship_quotes_400_en.json';
  static const fortuneKoPath =
      'assets/quotes/ko/todays_fortune_500_ko.json';
  static const fortuneEnPath =
      'assets/quotes/en/todays_fortune_500_en.json';
  static const famousKoPath =
      'assets/quotes/ko/famous_quotes_400_ko.json';
  static const famousEnPath =
      'assets/quotes/en/famous_quotes_400_en.json';
  static const courageKoPath =
      'assets/quotes/ko/courage_challenge_quotes_400.json';

  static Future<List<Quote>> loadChristianKo() => _loadList(
        path: christianKoPath,
        idPrefix: 'faith_christian_',
        authorOf: (item) {
          final reference = _text(item['reference']);
          return reference.isNotEmpty ? reference : '성경';
        },
      );

  /// Only the `text` field is shown. Author and category stay unused.
  static Future<List<Quote>> loadGratitude({required bool korean}) =>
      _loadList(
        path: korean ? gratitudeKoPath : gratitudeEnPath,
        idPrefix: korean ? 'daily_gratitude_ko_' : 'daily_gratitude_en_',
        authorOf: (_) => '',
      );

  /// Today's fortune lines. The files store the sentence in `fortune`.
  static Future<List<Quote>> loadFortune({required bool korean}) => _loadList(
        path: korean ? fortuneKoPath : fortuneEnPath,
        idPrefix: korean ? 'fortune_ko_' : 'fortune_en_',
        textKey: 'fortune',
        authorOf: (_) => '',
      );

  /// Only the `text` field is shown. Author and category stay unused.
  static Future<List<Quote>> loadLove({required bool korean}) => _loadList(
        path: korean ? loveKoPath : loveEnPath,
        idPrefix: korean ? 'daily_love_ko_' : 'daily_love_en_',
        authorOf: (_) => '',
      );

  /// Korean courage lines. The file stores each sentence in `lines`.
  static Future<List<Quote>> loadCourageKo() async {
    final raw = await rootBundle.loadString(courageKoPath);
    final decoded = jsonDecode(raw);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    if (items is! List) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>)
          Quote(
            id: 'comfort_courage_ko_${item['id']}',
            text: _lines(item),
            author: '',
          ),
    ].where((quote) => quote.text.isNotEmpty).toList(growable: false);
  }

  static String _lines(Map<String, dynamic> item) {
    final lines = item['lines'];
    if (lines is List) {
      final parts = [
        for (final line in lines)
          if (line is String && line.trim().isNotEmpty) line.trim(),
      ];
      if (parts.isNotEmpty) return parts.join('\n');
    }
    return _text(item['text']);
  }

  /// Famous quotes. Only `quote` and `author` are kept.
  static Future<List<Quote>> loadFamous({required bool korean}) => _loadList(
        path: korean ? famousKoPath : famousEnPath,
        idPrefix: korean ? 'famous_ko_' : 'famous_en_',
        textKey: 'quote',
        authorOf: (item) => _text(item['author']),
      );

  /// Japanese manuscripts in `assets/quotes/jp`, keyed by category.
  static const japanesePaths = <String, String>{
    'comfort:tired': 'assets/quotes/jp/japanese_tired_day_quotes_300_v2.json',
    'comfort:anxiety':
        'assets/quotes/jp/japanese_anxiety_worry_quotes_300_aa71b8.json',
    'comfort:self':
        'assets/quotes/jp/japanese_self_esteem_self_love_quotes_300.json',
    'comfort:courage':
        'assets/quotes/jp/japanese_courage_challenge_quotes_300.json',
    'comfort:lonely':
        'assets/quotes/jp/japanese_loneliness_comfort_quotes_300.json',
    'comfort:growth':
        'assets/quotes/jp/japanese_failure_growth_quotes_300.json',
    'comfort:relation':
        'assets/quotes/jp/japanese_human_relationship_quotes_300.json',
    'comfort:dream':
        'assets/quotes/jp/japanese_dream_motivation_quotes_300.json',
    'faith:buddhism': 'assets/quotes/jp/japanese_buddhism_quotes_300.json',
    'faith:christian': 'assets/quotes/jp/japanese_christian_quotes_300.json',
    'literature:quotes': 'assets/quotes/jp/japanese_famous_quotes_200.json',
    'literature:writers':
        'assets/quotes/jp/japanese_literary_book_quotes_300.json',
    'daily:love':
        'assets/quotes/jp/japanese_love_relationship_quotes_300.json',
    'daily:gratitude':
        'assets/quotes/jp/japanese_gratitude_joy_quotes_300_5ec9e4.json',
  };

  static Future<Map<String, List<Quote>>> loadJapanese() async {
    final entries = await Future.wait(
      japanesePaths.entries.map((entry) async {
        final quotes = await _loadList(
          path: entry.value,
          idPrefix: 'ja_${entry.key.replaceAll(':', '_')}_',
          authorOf: _japaneseAuthor,
        );
        return MapEntry(entry.key, quotes);
      }),
    );
    return Map.fromEntries(entries);
  }

  static String _japaneseAuthor(Map<String, dynamic> item) {
    final author = _text(item['author']);
    final book = _text(item['book']);
    if (author.isNotEmpty && book.isNotEmpty) return '$author · $book';
    return author;
  }

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
    String textKey = 'text',
  }) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          Quote(
            id: '$idPrefix${item['id']}',
            text: _text(item[textKey]),
            author: authorOf(item),
          ),
    ].where((q) => q.text.isNotEmpty).toList(growable: false);
  }

  static String _text(Object? value) =>
      value is String ? value.trim() : '';
}
