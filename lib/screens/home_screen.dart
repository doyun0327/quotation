import 'package:flutter/material.dart';
import 'package:quotation/data/archive_controller.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/shop_screen.dart';
import 'package:quotation/screens/quote_list_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/widgets/dashed_border.dart';
import 'package:quotation/widgets/character_widget_hint.dart';
import 'package:quotation/widgets/hamfoot_icon.dart';
import 'package:quotation/widgets/category_browse_section.dart';
import 'package:quotation/widgets/category_pixel_icon.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final DateTime _today = DateTime.now();

  void _showSnack(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.body.copyWith(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  void _openSubcategory(
    BuildContext context,
    MainCategory category,
    SubCategory sub,
  ) {
    selectionController.selectSubCategory(category.id, sub.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteListScreen(
          mainCategory: category,
          subCategory: sub,
        ),
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
      subCategoryId: subId,
      subCategoryTitle: subTitle,
      author: quote.author,
    );
    _showSnack(
      context,
      saved ? t.savedToArchive : t.removedFromArchive,
      duration: saved ? const Duration(seconds: 2) : null,
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
          themeController,
        ]),
        builder: (context, _) {
          final bubble = selectionController.bubbleQuote;
          final bubbleText = bubble?.text ?? AppStrings.current.homeGreeting;
          final bubbleId = bubble?.id ?? 'greeting_today';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 20),
                    _HomeQuoteCard(
                      date: _today,
                      message: bubbleText,
                      isSaved: archiveController.contains(bubbleId),
                      onDateTap: selectionController.reshuffle,
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
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: CategoryBrowseSection(
                    onSubcategoryTap: (category, sub) =>
                        _openSubcategory(context, category, sub),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  /// Brand lockup stays pixel and at a fixed size.
  static const _title = TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 18,
    color: AppColors.ink,
    height: 1.4,
  );

  static const _subtitle = TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 8,
    color: AppColors.muted,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.brandTitle,
          textScaler: TextScaler.noScaling,
          style: _title,
        ),
        const SizedBox(height: 8),
        Text(
          t.brandSubtitle,
          textScaler: TextScaler.noScaling,
          style: _subtitle,
        ),
      ],
    );
  }
}

class _HomeQuoteCard extends StatefulWidget {
  const _HomeQuoteCard({
    required this.date,
    required this.message,
    required this.isSaved,
    this.onDateTap,
    this.onCharacterTap,
    this.onHeartTap,
    this.onMessageTap,
  });

  final DateTime date;
  final String message;
  final bool isSaved;
  final VoidCallback? onDateTap;
  final VoidCallback? onCharacterTap;
  final VoidCallback? onHeartTap;
  final VoidCallback? onMessageTap;

  @override
  State<_HomeQuoteCard> createState() => _HomeQuoteCardState();
}

class _HomeQuoteCardState extends State<_HomeQuoteCard> {
  static const _tapHintKey = 'character_tap_hint_dismissed';

  bool _showTapHint = false;

  @override
  void initState() {
    super.initState();
    _loadTapHint();
  }

  Future<void> _loadTapHint() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _showTapHint = prefs.getBool(_tapHintKey) != true);
  }

  Future<void> _openCharacter() async {
    if (_showTapHint) {
      setState(() => _showTapHint = false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tapHintKey, true);
    }
    widget.onCharacterTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final frame = CategorySky.border(context.palette);

    return LayoutBuilder(
      builder: (context, constraints) {
        final row = constraints.maxWidth - 20 - 8;
        final textWidth = row * 60 / 100 - 14 - 12;
        return _quoteCard(frame, textWidth);
      },
    );
  }

  Widget _quoteCard(Color frame, double textWidth) {
    final date = widget.date;
    final dateLabel = '${date.year}. ${date.month}. ${date.day}';
    return DashedBorder(
      color: frame,
      strokeWidth: 1.6,
      dashLength: 5,
      gapLength: 3.5,
      radius: 18,
      padding: const EdgeInsets.all(10),
      backgroundColor: AppColors.card,
      alwaysDashed: true,
      child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 40,
                child: _HomeFrame(
                  color: frame,
                  child: GestureDetector(
                    onTap: _openCharacter,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                characterController.assetPath,
                                height: 124,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                                isAntiAlias: false,
                              ),
                            ),
                            if (_showTapHint) const _CharacterTapHint(),
                          ],
                        ),
                        ListenableBuilder(
                          listenable: authController,
                          builder: (context, _) {
                            final name = authController.nickname?.trim() ?? '';
                            if (name.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTheme.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF3C4C60),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 60,
                child: Column(
                  children: [
                    _HomeFrame(
                      color: frame,
                      child: GestureDetector(
                        onTap: widget.onDateTap,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              dateLabel,
                              style: AppTheme.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8EA0B5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HomeFrame(
                      color: frame,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: widget.onMessageTap,
                              behavior: HitTestBehavior.opaque,
                              child: _CappedQuoteText(
                                message: widget.message,
                                textWidth: textWidth,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.onHeartTap,
                                  customBorder: const CircleBorder(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: HamfootIcon(
                                      size: 22,
                                      active: widget.isSaved,
                                      color: context.palette.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

/// Quote body on the home card. Grows with the text up to eight lines,
/// the height of the card in the reference layout, then scrolls inside.
class _CappedQuoteText extends StatefulWidget {
  const _CappedQuoteText({
    required this.message,
    required this.textWidth,
  });

  final String message;
  final double textWidth;

  @override
  State<_CappedQuoteText> createState() => _CappedQuoteTextState();
}

class _CappedQuoteTextState extends State<_CappedQuoteText> {
  static const _maxLines = 8;
  static const _minHeight = 72.0;

  static const _style = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: Color(0xFF3C4C60),
  );

  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _CappedQuoteText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.body.merge(_style);
    final width = widget.textWidth;
    final painter = TextPainter(
      text: TextSpan(text: widget.message, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width > 0 ? width : 100);
    final lineCap = painter.preferredLineHeight * _maxLines;
    final cap = lineCap < _minHeight ? _minHeight : lineCap;
    final textHeight = painter.height;
    painter.dispose();
    final viewHeight = textHeight < _minHeight
        ? _minHeight
        : (textHeight > cap ? cap : textHeight);
    final scrolls = textHeight > cap + 1;

    return SizedBox(
      height: viewHeight,
      child: Scrollbar(
        controller: _scroll,
        thumbVisibility: scrolls,
        thickness: 3,
        radius: const Radius.circular(2),
        child: SingleChildScrollView(
          controller: _scroll,
          physics: scrolls
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: Text(widget.message, style: style),
        ),
      ),
    );
  }
}

class _HomeFrame extends StatelessWidget {
  const _HomeFrame({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: color,
      strokeWidth: 1.4,
      dashLength: 5,
      gapLength: 3.5,
      radius: 14,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.card,
      alwaysDashed: true,
      child: child,
    );
  }
}

class _CharacterTapHint extends StatefulWidget {
  const _CharacterTapHint();

  @override
  State<_CharacterTapHint> createState() => _CharacterTapHintState();
}

class _CharacterTapHintState extends State<_CharacterTapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedBuilder(
      animation: Listenable.merge([_bounce, localeController]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -5 * _bounce.value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.accent, width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                AppStrings.current.characterTapHint,
                style: AppTheme.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
