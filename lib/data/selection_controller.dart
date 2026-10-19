import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';

class SelectionController extends ChangeNotifier {
  SelectionController() {
    membershipController.addListener(_onMembershipChanged);
    _refreshBubble();
    _ensureDailyFortune();
  }

  final _random = Random();
  String _mainCategoryId = MembershipController.freeCategoryId;
  String? _subCategoryId;
  Quote? _bubbleQuote;
  Quote? _fortuneQuote;
  String? _fortuneDayKey;

  String get mainCategoryId => _mainCategoryId;
  String? get subCategoryId => _subCategoryId;
  Quote? get bubbleQuote => _bubbleQuote;
  Quote? get fortuneQuote {
    _ensureDailyFortune();
    return _fortuneQuote;
  }

  MainCategory get mainCategory => QuoteRepository.byId(_mainCategoryId);

  List<Quote> get _fallbackBubble => const [
        Quote(id: 'fallback', text: '오늘도 잘하고 있어.'),
      ];

  List<Quote> get _fallbackFortune => const [
        Quote(id: 'fortune_fallback', text: '오늘도 좋은 일이 생길 거예요.'),
      ];

  /// Public pool used by the home widget hourly rotation.
  List<Quote> get bubblePoolQuotes => _bubblePool;

  /// Quotes available for the speech bubble (respects free/premium).
  List<Quote> get _bubblePool {
    if (!membershipController.isPremium) {
      final daily = QuoteRepository.byId(MembershipController.freeCategoryId)
          .allQuotes;
      return daily.isEmpty ? _fallbackBubble : daily;
    }

    if (_subCategoryId != null) {
      final sub = QuoteRepository.subById(_mainCategoryId, _subCategoryId!);
      if (sub != null && sub.quotes.isNotEmpty) return sub.quotes;
    }
    final all = mainCategory.allQuotes;
    return all.isEmpty ? _fallbackBubble : all;
  }

  /// Fortune pool: free → daily only; premium → all categories.
  List<Quote> get _fortunePool {
    if (!membershipController.isPremium) {
      final daily = QuoteRepository.byId(MembershipController.freeCategoryId)
          .allQuotes;
      return daily.isEmpty ? _fallbackFortune : daily;
    }

    final all = [
      for (final category in QuoteRepository.categories) ...category.allQuotes,
    ];
    return all.isEmpty ? _fallbackFortune : all;
  }

  String get _todayKey {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  void _onMembershipChanged() {
    if (!membershipController.isPremium &&
        !membershipController.canAccess(_mainCategoryId)) {
      _mainCategoryId = MembershipController.freeCategoryId;
      _subCategoryId = null;
    }
    _fortuneDayKey = null;
    _ensureDailyFortune();
    _refreshBubble();
    notifyListeners();
  }

  void selectMainCategory(String id) {
    _mainCategoryId = id;
    _subCategoryId = null;
    _refreshBubble();
    notifyListeners();
  }

  void selectSubCategory(String mainId, String subId) {
    _mainCategoryId = mainId;
    _subCategoryId = subId;
    _refreshBubble();
    notifyListeners();
  }

  void _refreshBubble() {
    final pool = _bubblePool;
    _bubbleQuote = pool[_random.nextInt(pool.length)];
  }

  void _ensureDailyFortune() {
    final dayKey = _todayKey;
    final membershipKey =
        membershipController.isPremium ? 'premium' : 'free';
    final cacheKey = '$dayKey:$membershipKey';
    if (_fortuneDayKey == cacheKey && _fortuneQuote != null) return;

    final pool = _fortunePool;
    // Same calendar day + membership tier → same fortune.
    final index = Random(cacheKey.hashCode).nextInt(pool.length);
    _fortuneQuote = pool[index];
    _fortuneDayKey = cacheKey;
  }

  void reshuffle() {
    _refreshBubble();
    notifyListeners();
  }

  /// Call after [QuoteRepository.initialize] so the daily fortune uses loaded quotes.
  void syncAfterQuotesReady() {
    _fortuneDayKey = null;
    _ensureDailyFortune();
    _refreshBubble();
    notifyListeners();
  }
}

final selectionController = SelectionController();
