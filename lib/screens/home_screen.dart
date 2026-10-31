import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Opaque bounds of a character image, as fractions of its size.
typedef _ArtInk = ({
  double aspect,
  double left,
  double top,
  double right,
  double bottom,
});

class _HomeQuoteCardState extends State<_HomeQuoteCard> {
  static const _tapHintKey = 'character_tap_hint_dismissed';

  /// Character plus name tag height as a share of the quote box height.
  static const _groupShare = 0.75;

  /// How far the body always reaches into the box, in logical pixels.
  static const _overlap = 22.0;

  /// Bounds of the default character, used until an image is measured.
  static const _fallbackInk = (
    aspect: 1.0,
    left: 0.24,
    top: 0.2,
    right: 0.745,
    bottom: 0.875,
  );

  static final _inkCache = <String, _ArtInk>{};

  bool _showTapHint = false;
  String? _measuring;

  @override
  void initState() {
    super.initState();
    _loadTapHint();
  }

  /// Measures the opaque bounds once per image, so every character is drawn
  /// at the same body height and lines up with the box and the name tag,
  /// whatever transparent margin the image has.
  Future<void> _measureInk(String path) async {
    if (_inkCache.containsKey(path) || _measuring == path) return;
    _measuring = path;
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 128,
      );
      final image = (await codec.getNextFrame()).image;
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = image.width;
      final h = image.height;
      image.dispose();
      codec.dispose();
      if (bytes == null || w == 0 || h == 0) return;
      var minX = w, minY = h, maxX = -1, maxY = -1;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (bytes.getUint8((y * w + x) * 4 + 3) > 10) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }
      if (maxX < 0) return;
      _inkCache[path] = (
        aspect: h / w,
        left: minX / w,
        top: minY / h,
        right: (maxX + 1) / w,
        bottom: (maxY + 1) / h,
      );
      if (mounted) setState(() {});
    } catch (_) {
      // Keep the fallback bounds.
    } finally {
      if (_measuring == path) _measuring = null;
    }
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
      builder: (context, constraints) =>
          _quoteCard(context, frame, constraints.maxWidth),
    );
  }

  /// Character stands on the left, in front of the quote box, overlapping
  /// its left edge. The box is five quote lines tall and the body is three
  /// quarters of that for every character.
  Widget _quoteCard(BuildContext context, Color frame, double width) {
    final date = widget.date;
    final dateLabel = '${date.year}. ${date.month}. ${date.day}';
    final path = characterController.assetPath;
    final ink = _inkCache[path] ?? _fallbackInk;
    if (!_inkCache.containsKey(path)) _measureInk(path);

    const padTop = 8.0;
    const padBottom = 12.0;
    const dateRow = 30.0; // paw button: 22 icon + 4 padding on each side
    const dateGap = 6.0;
    final textHeight = _CappedQuoteText.heightFor(context);
    final boxHeight = padTop + dateRow + dateGap + textHeight + padBottom;
    final boxLeft = width * 0.21;

    const tagHeight = 26.0;
    const tagGap = 2.0;
    // Scale so body + name tag take exactly [_groupShare] of the box height.
    final bodyHeight = boxHeight * _groupShare - tagGap - tagHeight;
    final drawnH = bodyHeight / (ink.bottom - ink.top);
    final drawnW = drawnH / ink.aspect;
    final bodyWidth = drawnW * (ink.right - ink.left);
    // Right side always reaches [_overlap] into the box; wide bodies start
    // at the left edge instead.
    final bodyLeft =
        (boxLeft + _overlap - bodyWidth).clamp(0.0, width).toDouble();
    final bodyRight = bodyLeft + bodyWidth;

    final groupHeight = bodyHeight + tagGap + tagHeight;
    // Name tag bottom sits on the box's bottom line.
    final bodyTop = (boxHeight - groupHeight).clamp(0.0, boxHeight);

    final textInset = (bodyRight - boxLeft + 8).clamp(12.0, width).toDouble();
    final textWidth = width - boxLeft - textInset - 8;

    final box = _HomeFrame(
      color: frame,
      child: SizedBox(
        height: boxHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(textInset, padTop, 8, padBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date and favorite share the top line of the quote box.
              SizedBox(
                height: dateRow,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onDateTap,
                        behavior: HitTestBehavior.opaque,
                        child: Align(
                          alignment: Alignment.centerLeft,
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
                    Material(
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
                  ],
                ),
              ),
              const SizedBox(height: dateGap),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onMessageTap,
                  behavior: HitTestBehavior.opaque,
                  child: _CappedQuoteText(
                    message: widget.message,
                    textWidth: textWidth,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final accent = context.palette.accent;
    final tagCenter = bodyLeft + bodyWidth / 2;
    // Centered under the body; never past its right side, so a long name
    // cannot reach the quote text.
    final tagMax = ((bodyRight + 4 - tagCenter) * 2).clamp(56.0, width);

    return SizedBox(
      height: boxHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: boxLeft,
            right: 0,
            top: 0,
            bottom: 0,
            child: box,
          ),
          // Image placed so its opaque body lands on the computed bounds.
          Positioned(
            left: bodyLeft - drawnW * ink.left,
            top: bodyTop - drawnH * ink.top,
            width: drawnW,
            height: drawnH,
            child: GestureDetector(
              onTap: _openCharacter,
              behavior: HitTestBehavior.translucent,
              child: Image.asset(
                path,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
          ),
          if (_showTapHint)
            Positioned(
              left: tagCenter - 80,
              width: 160,
              top: bodyTop + bodyHeight - 28,
              child: const Center(child: _CharacterTapHint()),
            ),
          Positioned(
            left: tagCenter - tagMax / 2,
            width: tagMax,
            top: bodyTop + bodyHeight + tagGap,
            child: Center(
              child: ListenableBuilder(
                listenable: authController,
                builder: (context, _) {
                  final name = authController.nickname?.trim() ?? '';
                  if (name.isEmpty) return const SizedBox.shrink();
                  // Sticker-style tag in front of the box, like the character.
                  return GestureDetector(
                    onTap: _openCharacter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.55),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
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
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quote body on the home card. Always five lines tall; longer quotes
/// scroll inside the box.
class _CappedQuoteText extends StatefulWidget {
  const _CappedQuoteText({
    required this.message,
    required this.textWidth,
  });

  final String message;
  final double textWidth;

  static const maxLines = 5;

  static const _style = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: Color(0xFF3C4C60),
  );

  static TextStyle style() => AppTheme.body.merge(_style);

  /// Height of [maxLines] lines with the user's text size.
  static double heightFor(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: style()),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final line = painter.preferredLineHeight;
    painter.dispose();
    return line * maxLines;
  }

  @override
  State<_CappedQuoteText> createState() => _CappedQuoteTextState();
}

class _CappedQuoteTextState extends State<_CappedQuoteText> {
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
    final style = _CappedQuoteText.style();
    final width = widget.textWidth;
    final painter = TextPainter(
      text: TextSpan(text: widget.message, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width > 0 ? width : 100);
    final textHeight = painter.height;
    painter.dispose();
    final scrolls = textHeight > _CappedQuoteText.heightFor(context) + 1;

    return Scrollbar(
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
