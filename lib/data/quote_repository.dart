import 'package:flutter/material.dart';
import 'package:quotation/data/quote_asset_loader.dart';
import 'package:quotation/data/quote_bank.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/widgets/pixel_icons.dart';

abstract final class QuoteRepository {
  static final Map<String, List<Quote>> _overrides = {};
  static List<Quote> _gratitudeKo = const [];
  static List<Quote> _gratitudeEn = const [];
  static List<Quote> _loveKo = const [];
  static List<Quote> _loveEn = const [];
  static List<Quote> _fortuneKo = const [];
  static List<Quote> _fortuneEn = const [];
  static List<Quote> _famousKo = const [];
  static List<Quote> _famousEn = const [];
  static List<Quote> _courageKo = const [];
  static Map<String, List<Quote>> _japanese = const {};

  static List<MainCategory> categories = _buildCategories();

  static MainCategory byId(String id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => categories.first);

  static SubCategory? subById(String mainId, String subId) {
    final main = byId(mainId);
    for (final sub in main.subCategories) {
      if (sub.id == subId) return sub;
    }
    return null;
  }

  static List<Quote> quotesFor(String mainId, String subId) {
    final key = '$mainId:$subId';
    if (localeController.isJapanese) {
      final japanese = _japanese[key];
      if (japanese != null && japanese.isNotEmpty) return japanese;
      return const <Quote>[];
    }
    if (mainId == 'daily' && subId == 'gratitude') {
      final loaded = _byLanguage(_gratitudeKo, _gratitudeEn);
      if (loaded.isNotEmpty) return loaded;
    }
    if (mainId == 'daily' && subId == 'love') {
      final loaded = _byLanguage(_loveKo, _loveEn);
      if (loaded.isNotEmpty) return loaded;
    }
    if (mainId == 'literature' && subId == 'quotes') {
      final loaded = _byLanguage(_famousKo, _famousEn);
      if (loaded.isNotEmpty) return loaded;
    }
    if (localeController.isKorean &&
        mainId == 'comfort' &&
        subId == 'courage' &&
        _courageKo.isNotEmpty) {
      return _courageKo;
    }
    return _overrides[key] ?? quoteBank[key] ?? const <Quote>[];
  }

  /// Korean and English files stay on their own language.
  /// Japanese never falls through to the English file.
  static List<Quote> _byLanguage(List<Quote> korean, List<Quote> english) {
    switch (localeController.language) {
      case AppLanguage.korean:
        return korean;
      case AppLanguage.english:
        return english;
      case AppLanguage.japanese:
        return const [];
    }
  }

  /// Finds the deck that contains [quoteId], including loaded quote files.
  static ({MainCategory main, SubCategory sub, int index})? locateQuote(
    String quoteId, {
    String? categoryId,
    String? subId,
  }) {
    final id = quoteId.trim();
    if (id.isEmpty) return null;
    final preferred = <MainCategory>[];
    if (categoryId != null && categoryId.isNotEmpty) {
      preferred.add(byId(categoryId));
    }
    final rest = [
      for (final category in categories)
        if (!preferred.any((item) => item.id == category.id)) category,
    ];
    for (final main in [...preferred, ...rest]) {
      final subs = <SubCategory>[];
      if (subId != null &&
          subId.isNotEmpty &&
          preferred.isNotEmpty &&
          main.id == preferred.first.id) {
        final chosen = subById(main.id, subId);
        if (chosen != null) subs.add(chosen);
      }
      for (final sub in main.subCategories) {
        if (!subs.any((item) => item.id == sub.id)) subs.add(sub);
      }
      for (final sub in subs) {
        final quotes = quotesFor(main.id, sub.id);
        final index = quotes.indexWhere((quote) => quote.id == id);
        if (index >= 0) return (main: main, sub: sub, index: index);
      }
    }
    return null;
  }

  /// Fortune lines for the current language.
  static List<Quote> fortuneQuotesForLocale() {
    return _byLanguage(_fortuneKo, _fortuneEn);
  }

  /// Gratitude and love sentences for the current language.
  static List<Quote> dailyQuotesForLocale() {
    return [
      ...quotesFor('daily', 'gratitude'),
      ...quotesFor('daily', 'love'),
    ];
  }

  /// Reloads category snapshots after the app language changes.
  static void onLocaleChanged() {
    categories = _buildCategories();
  }

  static Future<void> initialize() async {
    try {
      final results = await Future.wait<Object>([
        QuoteAssetLoader.loadChristianKo(),
        QuoteAssetLoader.loadBuddhismKo(),
        QuoteAssetLoader.loadGratitude(korean: true),
        QuoteAssetLoader.loadGratitude(korean: false),
        QuoteAssetLoader.loadLove(korean: true),
        QuoteAssetLoader.loadLove(korean: false),
        QuoteAssetLoader.loadFortune(korean: true),
        QuoteAssetLoader.loadFortune(korean: false),
        QuoteAssetLoader.loadFamous(korean: true),
        QuoteAssetLoader.loadFamous(korean: false),
        QuoteAssetLoader.loadCourageKo(),
        QuoteAssetLoader.loadJapanese(),
      ]);
      final christian = results[0] as List<Quote>;
      final buddhism = results[1] as List<Quote>;
      _gratitudeKo = results[2] as List<Quote>;
      _gratitudeEn = results[3] as List<Quote>;
      _loveKo = results[4] as List<Quote>;
      _loveEn = results[5] as List<Quote>;
      _fortuneKo = results[6] as List<Quote>;
      _fortuneEn = results[7] as List<Quote>;
      _famousKo = results[8] as List<Quote>;
      _famousEn = results[9] as List<Quote>;
      _courageKo = results[10] as List<Quote>;
      _japanese = results[11] as Map<String, List<Quote>>;
      var changed = false;

      if (christian.isNotEmpty) {
        _overrides['faith:christian'] = christian;
        changed = true;
      }
      if (buddhism.isNotEmpty) {
        _overrides['faith:buddhism'] = buddhism;
        changed = true;
      }
      if (changed ||
          _gratitudeKo.isNotEmpty ||
          _gratitudeEn.isNotEmpty ||
          _loveKo.isNotEmpty ||
          _loveEn.isNotEmpty ||
          _famousKo.isNotEmpty ||
          _famousEn.isNotEmpty ||
          _courageKo.isNotEmpty ||
          _japanese.isNotEmpty) {
        categories = _buildCategories();
      }
    } catch (_) {
      // Keep quote_bank fallback when asset load fails.
    }
  }
}

List<MainCategory> _buildCategories() => [
      _buildDaily(),
      _buildComfort(),
      _buildFaith(),
      _buildLiterature(),
    ];

MainCategory _buildComfort() => MainCategory(
      id: 'comfort',
      title: '위로와 응원',
      lines: ['지친 마음에', '따뜻한 한마디'],
      bannerText: '지금, 네 마음에 따뜻한 위로를 보낼게요.',
      background: const Color(0xFFFFF0F2),
      accent: const Color(0xFFE86B7A),
      border: const Color(0xFFF0A8B4),
      bannerColor: const Color(0xFFFFE8EE),
      pixelIcon: PixelIconKind.heart,
      subCategories: [
        SubCategory(
          id: 'tired',
          title: '지친 하루',
          subtitle: '힘든 하루를 보낸 나에게',
          bannerText: '오늘도 수고한 너에게 따뜻한 문장을 전해요.',
          icon: Icons.cloud_rounded,
          iconColor: const Color(0xFF6BA3E0),
          iconBackground: const Color(0xFFE3F0FF),
          quotes: QuoteRepository.quotesFor('comfort', 'tired'),
        ),
        SubCategory(
          id: 'self',
          title: '자존감과 자기 사랑',
          subtitle: '나 자신을 아끼고 싶을 때',
          bannerText: '너를 가장 먼저 아껴주는 사람이 되어봐.',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFE86B7A),
          iconBackground: const Color(0xFFFFE8EE),
          quotes: QuoteRepository.quotesFor('comfort', 'self'),
        ),
        SubCategory(
          id: 'courage',
          title: '용기와 도전',
          subtitle: '새로운 시작이 두려울 때',
          bannerText: '작은 한 걸음도 멋진 시작이야.',
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFE0A04A),
          iconBackground: const Color(0xFFFFF3DF),
          quotes: QuoteRepository.quotesFor('comfort', 'courage'),
        ),
        SubCategory(
          id: 'anxiety',
          title: '불안과 걱정',
          subtitle: '미래가 걱정되고 마음이 복잡할 때',
          bannerText: '지금 이 순간만 천천히 바라보자.',
          icon: Icons.ac_unit_rounded,
          iconColor: const Color(0xFF7BB3E8),
          iconBackground: const Color(0xFFEAF4FF),
          quotes: QuoteRepository.quotesFor('comfort', 'anxiety'),
        ),
        SubCategory(
          id: 'lonely',
          title: '외로움과 위로',
          subtitle: '누군가에게 위로받고 싶을 때',
          bannerText: '혼자가 아니야. 여기 따뜻한 말이 있어.',
          icon: Icons.nightlight_round,
          iconColor: const Color(0xFF7C8BC4),
          iconBackground: const Color(0xFFEEF0FF),
          quotes: QuoteRepository.quotesFor('comfort', 'lonely'),
        ),
        SubCategory(
          id: 'growth',
          title: '실패와 성장',
          subtitle: '실수했거나 다시 일어서고 싶을 때',
          bannerText: '넘어짐도 성장의 일부야.',
          icon: Icons.eco_rounded,
          iconColor: const Color(0xFF5AAA6A),
          iconBackground: const Color(0xFFE8F6EB),
          quotes: QuoteRepository.quotesFor('comfort', 'growth'),
        ),
        SubCategory(
          id: 'relation',
          title: '인간관계',
          subtitle: '친구, 가족, 사람 때문에 힘들 때',
          bannerText: '관계는 천천히, 진심으로 가꿔가면 돼.',
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFFD088B0),
          iconBackground: const Color(0xFFFCEAF3),
          quotes: QuoteRepository.quotesFor('comfort', 'relation'),
        ),
        SubCategory(
          id: 'dream',
          title: '꿈과 동기부여',
          subtitle: '목표를 향해 나아가고 싶을 때',
          bannerText: '네 꿈은 여전히 반짝이고 있어.',
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFE0A04A),
          iconBackground: const Color(0xFFFFF4DF),
          quotes: QuoteRepository.quotesFor('comfort', 'dream'),
        ),
      ],
    );

MainCategory _buildFaith() => MainCategory(
      id: 'faith',
      title: '종교와 지혜',
      lines: ['불교 · 천주교', '개신교 · 가르침'],
      bannerText: '고요한 마음이 필요할 때, 지혜의 말을 건네줄게요.',
      background: const Color(0xFFEEF5FF),
      accent: const Color(0xFF5B8DEF),
      border: const Color(0xFFA8C4F0),
      bannerColor: const Color(0xFFE8F1FF),
      pixelIcon: PixelIconKind.church,
      subCategories: [
        SubCategory(
          id: 'buddhism',
          title: '불교',
          subtitle: '마음에 고요를 담고 싶을 때',
          bannerText: '집착을 내려놓고 숨을 고르자.',
          icon: Icons.self_improvement_rounded,
          iconColor: const Color(0xFF5B8DEF),
          iconBackground: const Color(0xFFE8F1FF),
          quotes: QuoteRepository.quotesFor('faith', 'buddhism'),
        ),
        SubCategory(
          id: 'christian',
          title: '기독교',
          subtitle: '믿음과 소망이 필요할 때',
          bannerText: '따뜻한 위로가 네 마음에 닿기를.',
          icon: Icons.church_rounded,
          iconColor: const Color(0xFF6C8CFF),
          iconBackground: const Color(0xFFEEF0FF),
          quotes: QuoteRepository.quotesFor('faith', 'christian'),
        ),
      ],
    );

MainCategory _buildLiterature() => MainCategory(
      id: 'literature',
      title: '명언과 문학',
      lines: ['유명인의 명언', '작가의 문장'],
      bannerText: '오래 남는 문장으로 마음에 불을 밝혀줄게요.',
      background: const Color(0xFFFFF7E8),
      accent: const Color(0xFFE0A04A),
      border: const Color(0xFFE8C48A),
      bannerColor: const Color(0xFFFFF1DC),
      pixelIcon: PixelIconKind.book,
      subCategories: [
        SubCategory(
          id: 'quotes',
          title: '유명인 명언',
          subtitle: '삶을 비추는 한마디',
          bannerText: '짧은 문장, 긴 울림.',
          icon: Icons.format_quote_rounded,
          iconColor: const Color(0xFFE0A04A),
          iconBackground: const Color(0xFFFFF1DC),
          quotes: QuoteRepository.quotesFor('literature', 'quotes'),
        ),
        SubCategory(
          id: 'writers',
          title: '작가의 문장',
          subtitle: '책 속에서 건진 위로',
          bannerText: '문학이 건네는 따뜻한 손길.',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFFC4894A),
          iconBackground: const Color(0xFFFFF4E8),
          quotes: QuoteRepository.quotesFor('literature', 'writers'),
        ),
      ],
    );

MainCategory _buildDaily() => MainCategory(
      id: 'daily',
      title: '행복한 일상',
      lines: ['사랑, 관계, 감사', '매일의 작은 기쁨'],
      bannerText: '평범한 하루 속 반짝임을 함께 찾아봐요.',
      background: const Color(0xFFEEF8F0),
      accent: const Color(0xFF5AAA6A),
      border: const Color(0xFFA8D0B0),
      bannerColor: const Color(0xFFE8F6EB),
      pixelIcon: PixelIconKind.sprout,
      subCategories: [
        SubCategory(
          id: 'gratitude',
          title: '감사와 기쁨',
          subtitle: '작은 행복을 발견하고 싶을 때',
          bannerText: '오늘도 고마운 일이 분명 있어.',
          icon: Icons.emoji_emotions_rounded,
          iconColor: const Color(0xFF5AAA6A),
          iconBackground: const Color(0xFFE8F6EB),
          quotes: QuoteRepository.quotesFor('daily', 'gratitude'),
        ),
        SubCategory(
          id: 'love',
          title: '사랑과 관계',
          subtitle: '마음이 따뜻해지고 싶을 때',
          bannerText: '사랑은 가까운 곳에서 피어나.',
          icon: Icons.volunteer_activism_rounded,
          iconColor: const Color(0xFFE86B7A),
          iconBackground: const Color(0xFFFFE8EE),
          quotes: QuoteRepository.quotesFor('daily', 'love'),
        ),
      ],
    );
