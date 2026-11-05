import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectionController extends ChangeNotifier {
  SelectionController() {
    membershipController.addListener(_onMembershipChanged);
    _restoreFuture = _restoreBubble();
    _ensureDailyFortune();
    _scheduleRotate();
    _lifecycle = AppLifecycleListener(onResume: ensureBubbleFresh);
  }

  /// Matches the home-widget hourly rotation — fresh without feeling noisy.
  static const rotateInterval = Duration(hours: 1);

  static const _prefsQuoteId = 'home_bubble_quote_id';
  static const _prefsQuoteAt = 'home_bubble_quote_at_ms';

  final _random = Random();
  String _mainCategoryId = MembershipController.freeCategoryId;
  String? _subCategoryId;
  Quote? _bubbleQuote;
  DateTime? _bubbleAt;
  Quote? _fortuneQuote;
  String? _fortuneDayKey;
  Timer? _rotateTimer;
  AppLifecycleListener? _lifecycle;
  bool _restoring = false;
  late final Future<void> _restoreFuture;

  String get mainCategoryId => _mainCategoryId;
  String? get subCategoryId => _subCategoryId;
  Quote? get bubbleQuote => _bubbleQuote;

  Quote? get fortuneQuote {
    _ensureDailyFortune();
    return _fortuneQuote;
  }

  MainCategory get mainCategory => QuoteRepository.byId(_mainCategoryId);

  List<Quote> get _fallbackBubble => [
        Quote(
          id: 'fallback',
          text: AppStrings.current.doingWell,
        ),
      ];

  List<Quote> get _fallbackFortune => [
        Quote(
          id: 'fortune_fallback',
          text: AppStrings.current.fortuneFallbackLine,
        ),
      ];

  /// Public pool used by the home widget hourly rotation.
  List<Quote> get bubblePoolQuotes => _bubblePool;

  /// Quotes from every category the user can open (free + premium unlock).
  List<Quote> get _bubblePool {
    final quotes = <Quote>[];
    for (final main in QuoteRepository.categories) {
      if (!membershipController.canAccess(main.id)) continue;
      for (final sub in main.subCategories) {
        quotes.addAll(QuoteRepository.quotesFor(main.id, sub.id));
      }
    }
    return quotes.isEmpty ? _fallbackBubble : quotes;
  }

  /// One line from the language's fortune file.
  List<Quote> get _fortunePool {
    final loaded = QuoteRepository.fortuneQuotesForLocale();
    return loaded.isEmpty ? _fallbackFortune : loaded;
  }

  String get _todayKey {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  bool get _bubbleExpired {
    final at = _bubbleAt;
    if (at == null || _bubbleQuote == null) return true;
    return DateTime.now().difference(at) >= rotateInterval;
  }

  void _onMembershipChanged() {
    if (!membershipController.hasPremiumContent &&
        !membershipController.canAccess(_mainCategoryId)) {
      _mainCategoryId = MembershipController.freeCategoryId;
      _subCategoryId = null;
    }
    // Premium unlock grows the pool; pick again so locked lines drop out.
    _refreshBubble(force: true);
    notifyListeners();
  }

  /// Browse navigation only — does not lock the home bubble to one category.
  void selectMainCategory(String id) {
    _mainCategoryId = id;
    _subCategoryId = null;
    notifyListeners();
  }

  void selectSubCategory(String mainId, String subId) {
    _mainCategoryId = mainId;
    _subCategoryId = subId;
    notifyListeners();
  }

  Future<void> _restoreBubble() async {
    _restoring = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_prefsQuoteId);
      final atMs = prefs.getInt(_prefsQuoteAt);
      if (id != null && id.isNotEmpty && atMs != null) {
        final located = QuoteRepository.locateQuote(id);
        if (located != null &&
            membershipController.canAccess(located.main.id)) {
          final quotes = QuoteRepository.quotesFor(
            located.main.id,
            located.sub.id,
          );
          _bubbleQuote = quotes[located.index];
          _bubbleAt = DateTime.fromMillisecondsSinceEpoch(atMs);
          _mainCategoryId = located.main.id;
          _subCategoryId = located.sub.id;
        }
      }
    } catch (_) {
      // First launch / prefs failure — fall through to a fresh pick.
    } finally {
      _restoring = false;
    }
    ensureBubbleFresh();
    notifyListeners();
  }

  Future<void> _persistBubble() async {
    final quote = _bubbleQuote;
    final at = _bubbleAt;
    if (quote == null || at == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsQuoteId, quote.id);
      await prefs.setInt(_prefsQuoteAt, at.millisecondsSinceEpoch);
    } catch (_) {}
  }

  void _refreshBubble({bool force = false}) {
    if (_restoring && !force) return;
    final pool = _bubblePool;
    if (pool.isEmpty) return;

    Quote next = pool[_random.nextInt(pool.length)];
    // Skip an immediate repeat when the pool has more than one line.
    if (pool.length > 1 && next.id == _bubbleQuote?.id) {
      next = pool[_random.nextInt(pool.length)];
      if (next.id == _bubbleQuote?.id) {
        final others = [for (final q in pool) if (q.id != next.id) q];
        if (others.isNotEmpty) {
          next = others[_random.nextInt(others.length)];
        }
      }
    }

    _bubbleQuote = next;
    _bubbleAt = DateTime.now();
    final located = QuoteRepository.locateQuote(next.id);
    if (located != null) {
      _mainCategoryId = located.main.id;
      _subCategoryId = located.sub.id;
    }
    unawaited(_persistBubble());
  }

  /// Picks a new line when the hour is up (app open or back from background).
  void ensureBubbleFresh() {
    if (!_bubbleExpired) return;
    _refreshBubble(force: true);
    notifyListeners();
    _scheduleRotate();
  }

  void _scheduleRotate() {
    _rotateTimer?.cancel();
    final at = _bubbleAt ?? DateTime.now();
    final left = rotateInterval - DateTime.now().difference(at);
    final wait = left.isNegative ? Duration.zero : left;
    _rotateTimer = Timer(wait + const Duration(milliseconds: 200), () {
      ensureBubbleFresh();
    });
  }

  void _ensureDailyFortune() {
    final cacheKey = '$_todayKey:${localeController.language.id}';
    if (_fortuneDayKey == cacheKey && _fortuneQuote != null) return;

    final pool = _fortunePool;
    // Same calendar day and language → same fortune.
    final index = Random(cacheKey.hashCode).nextInt(pool.length);
    _fortuneQuote = pool[index];
    _fortuneDayKey = cacheKey;
  }

  void reshuffle() {
    _refreshBubble(force: true);
    notifyListeners();
    _scheduleRotate();
  }

  /// Call after [QuoteRepository.initialize] so the daily fortune uses loaded quotes.
  Future<void> syncAfterQuotesReady() async {
    await _restoreFuture;
    _fortuneDayKey = null;
    _ensureDailyFortune();
    // Keep a still-fresh restored line; otherwise pick from the loaded pool.
    if (_bubbleExpired) {
      _refreshBubble(force: true);
    } else if (_bubbleQuote != null) {
      final located = QuoteRepository.locateQuote(_bubbleQuote!.id);
      if (located == null ||
          !membershipController.canAccess(located.main.id)) {
        _refreshBubble(force: true);
      } else {
        _mainCategoryId = located.main.id;
        _subCategoryId = located.sub.id;
      }
    } else {
      _refreshBubble(force: true);
    }
    notifyListeners();
    _scheduleRotate();
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _lifecycle?.dispose();
    membershipController.removeListener(_onMembershipChanged);
    super.dispose();
  }
}

final selectionController = SelectionController();
