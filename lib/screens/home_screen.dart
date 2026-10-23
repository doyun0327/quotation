import 'package:flutter/material.dart';
import 'package:quotation/data/archive_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/category_detail_screen.dart';
import 'package:quotation/screens/shop_screen.dart';
import 'package:quotation/screens/quote_list_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/character_widget_hint.dart';
import 'package:quotation/widgets/category_browse_section.dart';
import 'package:quotation/widgets/pixel_calendar.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/speech_bubble.dart';
import 'package:quotation/widgets/todays_word_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final DateTime _today = DateTime.now();

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.body.copyWith(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
    );
  }

  void _openCategory(BuildContext context, MainCategory category) {
    if (!membershipController.canAccess(category.id)) {
      return;
    }
    selectionController.selectMainCategory(category.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailScreen(category: category),
      ),
    );
  }

  void _toggleQuote(BuildContext context, Quote quote) {
    final category = selectionController.mainCategory;
    final subId = selectionController.subCategoryId;
    final t = AppStrings.current;
    final subTitle = subId == null ? null : t.subCategoryTitle(subId);

    final saved = archiveController.toggle(
      id: quote.id,
      text: quote.text,
      categoryId: category.id,
      categoryTitle: t.mainCategoryTitle(category.id),
      subCategoryTitle: subTitle,
      author: quote.author,
    );
    _showSnack(
      context,
      saved ? t.savedToArchive : t.removedFromArchive,
    );
  }

  void _openBubbleDetail(BuildContext context, Quote quote) {
    final main = selectionController.mainCategory;
    final subId = selectionController.subCategoryId;
    SubCategory? sub =
        subId == null ? null : QuoteRepository.subById(main.id, subId);

    if (sub == null || !sub.quotes.any((q) => q.id == quote.id)) {
      for (final candidate in main.subCategories) {
        if (candidate.quotes.any((q) => q.id == quote.id)) {
          sub = candidate;
          break;
        }
      }
    }
    sub ??= main.subCategories.isEmpty ? null : main.subCategories.first;
    if (sub == null || sub.quotes.isEmpty) return;

    final quotes = QuoteRepository.quotesFor(main.id, sub.id);
    final index = quotes.indexWhere((q) => q.id == quote.id);

    selectionController.selectSubCategory(main.id, sub.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteListScreen(
          mainCategory: main,
          subCategory: sub!,
          initialIndex: index < 0 ? 0 : index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          archiveController,
          selectionController,
          localeController,
          membershipController,
          characterController,
        ]),
        builder: (context, _) {
          final bubble = selectionController.bubbleQuote;
          final fortune = selectionController.fortuneQuote;
          final bubbleText = bubble?.text ??
              (localeController.isKorean
                  ? '안녕, 오늘도 잘하고 있어.'
                  : "Hi, you're doing well today.");
          final bubbleId = bubble?.id ?? 'greeting_today';
          final fortuneText = fortune?.text ??
              (localeController.isKorean
                  ? '오늘도 좋은 일이 생길 거예요.'
                  : 'Something good is waiting today.');

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  date: _today,
                  onShuffle: selectionController.reshuffle,
                ),
                const SizedBox(height: 20),
                _CharacterHero(
                  message: bubbleText,
                  isSaved: archiveController.contains(bubbleId),
                  onCharacterTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ShopScreen(asSettings: true),
                      ),
                    );
                  },
                  onHeartTap: () {
                    if (bubble != null) {
                      _toggleQuote(context, bubble);
                    }
                  },
                  onMessageTap: () {
                    if (bubble != null) {
                      _openBubbleDetail(context, bubble);
                    }
                  },
                ),
                const CharacterWidgetHintBanner(),
                const SizedBox(height: 20),
                TodaysWordCard(
                  date: _today,
                  text: fortuneText,
                ),
                const SizedBox(height: 18),
                CategoryBrowseSection(
                  onCategoryTap: (category) => _openCategory(context, category),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.date,
    this.onShuffle,
  });

  final DateTime date;
  final VoidCallback? onShuffle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.current.brandTitle,
                style: AppTheme.pixel.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.current.brandSubtitle,
                style: AppTheme.pixel.copyWith(
                  fontSize: 8,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onShuffle,
          child: PixelCalendar(date: date),
        ),
      ],
    );
  }
}

class _CharacterHero extends StatelessWidget {
  const _CharacterHero({
    required this.message,
    required this.isSaved,
    this.onCharacterTap,
    this.onHeartTap,
    this.onMessageTap,
  });

  final String message;
  final bool isSaved;
  final VoidCallback? onCharacterTap;
  final VoidCallback? onHeartTap;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    // Character stays at the bottom. The bubble grows upward with the quote.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
          // Trim a little empty layout on the character's right so the bubble
          // can grow left without covering the sprite.
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.94,
              child: GestureDetector(
                onTap: onCharacterTap,
                child: Image.asset(
                  characterController.assetPath,
                  height: 148,
                  filterQuality: visualStyleController.isClean
                      ? FilterQuality.medium
                      : FilterQuality.none,
                  isAntiAlias: visualStyleController.isClean,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: SpeechBubble(
                message: message,
                isSaved: isSaved,
                onHeartTap: onHeartTap,
                onMessageTap: onMessageTap,
              ),
            ),
          ),
        ],
    );
  }
}
