import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quotation/data/quote_models.dart';

/// How a deck's author line is built. Most files keep a plain author, or none.
enum _AuthorStyle { plain, scripture, buddhist, reference }

class _Deck {
  const _Deck(
    this.key, {
    this.ko,
    this.en,
    this.koAuthor = _AuthorStyle.plain,
    this.enAuthor = _AuthorStyle.plain,
  });

  final String key;
  final String? ko;
  final String? en;
  final _AuthorStyle koAuthor;
  final _AuthorStyle enAuthor;
}

abstract final class QuoteAssetLoader {
  static const christianKoPath =
      'assets/quotes/ko/bible_reflections_400.json';
  static const christianEnPath =
      'assets/quotes/en/christian_quotes_400_en.json';
  static const buddhismKoPath =
      'assets/quotes/ko/buddhist_reflections_1000.json';
  static const buddhismEnPath =
      'assets/quotes/en/buddhist_quotes_300_en.json';
  static const gratitudeKoPath =
      'assets/quotes/ko/dearly_gratitude_joy_quotes_500.json';
  static const gratitudeEnPath =
      'assets/quotes/en/dearly_gratitude_joy_quotes_500_en.json';
  static const loveKoPath =
      'assets/quotes/ko/dearly_love_relationship_quotes_400.json';
  static const loveEnPath =
      'assets/quotes/en/dearly_love_relationship_quotes_400_en.json';
  static const fortuneKoPath = 'assets/quotes/ko/todays_fortune_500_ko.json';
  static const fortuneEnPath = 'assets/quotes/en/todays_fortune_500_en.json';
  static const famousKoPath = 'assets/quotes/ko/famous_quotes_400_ko.json';
  static const famousEnPath = 'assets/quotes/en/famous_quotes_400_en.json';
  static const writersEnPath =
      'assets/quotes/en/literature_quotes_300_en.json';
  static const courageKoPath =
      'assets/quotes/ko/courage_challenge_quotes_400.json';
  static const courageEnPath =
      'assets/quotes/en/dearly_courage_challenge_400_en.json';
  static const tiredKoPath =
      'assets/quotes/ko/tired_day_comfort_quotes_300_ko.json';
  static const tiredEnPath =
      'assets/quotes/en/comfort_and_encouragement_400_en.json';
  static const selfKoPath =
      'assets/quotes/ko/dearly_self_esteem_self_love_400_clean.json';
  static const selfEnPath =
      'assets/quotes/en/dearly_self_esteem_self_love_400_en_clean.json';
  static const anxietyKoPath =
      'assets/quotes/ko/dearly_anxiety_worry_400.json';
  static const anxietyEnPath =
      'assets/quotes/en/dearly_anxiety_worry_400_en.json';
  static const lonelyKoPath =
      'assets/quotes/ko/dearly_loneliness_comfort_400.json';
  static const lonelyEnPath =
      'assets/quotes/en/dearly_loneliness_comfort_400_en.json';
  static const growthKoPath =
      'assets/quotes/ko/failure_growth_quotes_ko_300.json';
  static const growthEnPath =
      'assets/quotes/en/failure_growth_quotes_en_400.json';
  static const relationKoPath =
      'assets/quotes/ko/human_relationship_quotes_ko_400.json';
  static const relationEnPath =
      'assets/quotes/en/human_relationship_quotes_en_400.json';
  static const dreamKoPath =
      'assets/quotes/ko/dream_motivation_quotes_ko_400.json';
  static const dreamEnPath =
      'assets/quotes/en/dream_motivation_quotes_en_400.json';

  static const _decks = <_Deck>[
    _Deck('daily:gratitude', ko: gratitudeKoPath, en: gratitudeEnPath),
    _Deck('daily:love', ko: loveKoPath, en: loveEnPath),
    _Deck('comfort:tired', ko: tiredKoPath, en: tiredEnPath),
    _Deck('comfort:self', ko: selfKoPath, en: selfEnPath),
    _Deck('comfort:courage', ko: courageKoPath, en: courageEnPath),
    _Deck('comfort:anxiety', ko: anxietyKoPath, en: anxietyEnPath),
    _Deck('comfort:lonely', ko: lonelyKoPath, en: lonelyEnPath),
    _Deck('comfort:growth', ko: growthKoPath, en: growthEnPath),
    _Deck('comfort:relation', ko: relationKoPath, en: relationEnPath),
    _Deck('comfort:dream', ko: dreamKoPath, en: dreamEnPath),
    _Deck(
      'faith:buddhism',
      ko: buddhismKoPath,
      en: buddhismEnPath,
      koAuthor: _AuthorStyle.buddhist,
    ),
    _Deck(
      'faith:christian',
      ko: christianKoPath,
      en: christianEnPath,
      koAuthor: _AuthorStyle.scripture,
      enAuthor: _AuthorStyle.reference,
    ),
    _Deck('literature:quotes', ko: famousKoPath, en: famousEnPath),
    _Deck('literature:writers', en: writersEnPath),
  ];

  /// Category decks keyed as `mainId:subId`, split by language.
  /// A missing file is omitted so the caller can keep its own fallback.
  static Future<
      ({
        Map<String, List<Quote>> korean,
        Map<String, List<Quote>> english,
      })> loadCategoryDecks() async {
    final korean = <String, List<Quote>>{};
    final english = <String, List<Quote>>{};
    await Future.wait(_decks.map((deck) async {
      final ko = await _loadDeck(
        deck.ko,
        idPrefix: '${deck.key.replaceAll(':', '_')}_ko_',
        authorStyle: deck.koAuthor,
      );
      final en = await _loadDeck(
        deck.en,
        idPrefix: '${deck.key.replaceAll(':', '_')}_en_',
        authorStyle: deck.enAuthor,
      );
      if (ko.isNotEmpty) korean[deck.key] = ko;
      if (en.isNotEmpty) english[deck.key] = en;
    }));
    return (korean: korean, english: english);
  }

  /// Today's fortune lines. The files store the sentence in `fortune`.
  static Future<List<Quote>> loadFortune({required bool korean}) => _loadList(
        path: korean ? fortuneKoPath : fortuneEnPath,
        idPrefix: korean ? 'fortune_ko_' : 'fortune_en_',
        textKey: 'fortune',
        authorOf: (_) => '',
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
    'faith:christian': 'assets/quotes/jp/japanese_christian_quotes_400.json',
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

  static Future<List<Quote>> _loadDeck(
    String? path, {
    required String idPrefix,
    required _AuthorStyle authorStyle,
  }) async {
    if (path == null) return const [];
    try {
      return await _loadList(
        path: path,
        idPrefix: idPrefix,
        authorOf: switch (authorStyle) {
          _AuthorStyle.plain => _plainAuthor,
          _AuthorStyle.scripture => _scriptureAuthor,
          _AuthorStyle.buddhist => _buddhistAuthor,
          _AuthorStyle.reference => _referenceAuthor,
        },
      );
    } catch (_) {
      return const [];
    }
  }

  static String _japaneseAuthor(Map<String, dynamic> item) {
    final reference = _text(item['reference']);
    if (reference.isNotEmpty) return reference;
    final author = _text(item['author']);
    final book = _text(item['book']);
    if (author.isNotEmpty && book.isNotEmpty) return '$author · $book';
    return author;
  }

  static String _plainAuthor(Map<String, dynamic> item) {
    final author = _text(item['author']);
    if (author.isEmpty ||
        author == 'Dearly' ||
        author == 'Original literary-style reflection') {
      return '';
    }
    return author;
  }

  static String _scriptureAuthor(Map<String, dynamic> item) {
    final reference = _text(item['reference']);
    return reference.isNotEmpty ? reference : '성경';
  }

  static String _referenceAuthor(Map<String, dynamic> item) {
    return _text(item['reference']);
  }

  static String _buddhistAuthor(Map<String, dynamic> item) {
    final source = _text(item['source']);
    final chapter = _text(item['chapter']);
    final verse = _text(item['verse']);
    final parts = <String>[
      if (source.isNotEmpty) source,
      if (chapter.isNotEmpty || verse.isNotEmpty)
        [chapter, verse].where((part) => part.isNotEmpty).join(' '),
    ];
    if (parts.isEmpty) return '불교 경전';
    return parts.join(' · ');
  }

  static Future<List<Quote>> _loadList({
    required String path,
    required String idPrefix,
    required String Function(Map<String, dynamic> item) authorOf,
    String? textKey,
  }) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    final items = _asItemList(decoded);
    if (items.isEmpty) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>)
          Quote(
            id: '$idPrefix${item['id']}',
            text: _quoteText(item, textKey: textKey),
            author: authorOf(item),
          )
        else if (item is Map)
          Quote(
            id: '$idPrefix${item['id']}',
            text: _quoteText(Map<String, dynamic>.from(item), textKey: textKey),
            author: authorOf(Map<String, dynamic>.from(item)),
          ),
    ].where((quote) => quote.text.isNotEmpty).toList(growable: false);
  }

  static List<dynamic> _asItemList(Object? decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final items = decoded['items'];
      if (items is List) return items;
    }
    return const [];
  }

  /// `lines` (joined), then [textKey], then `text`, then `quote`.
  static String _quoteText(
    Map<String, dynamic> item, {
    String? textKey,
  }) {
    final lines = item['lines'];
    if (lines is List) {
      final parts = [
        for (final line in lines)
          if (line is String && line.trim().isNotEmpty) line.trim(),
      ];
      if (parts.isNotEmpty) return parts.join('\n');
    }
    if (textKey != null) {
      final keyed = _text(item[textKey]);
      if (keyed.isNotEmpty) return keyed;
    }
    final text = _text(item['text']);
    if (text.isNotEmpty) return text;
    return _text(item['quote']);
  }

  static String _text(Object? value) => value is String ? value.trim() : '';
}
