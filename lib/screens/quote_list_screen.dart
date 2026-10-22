import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quotation/data/archive_controller.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/archive_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/quote_backgrounds.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:share_plus/share_plus.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({
    super.key,
    required this.mainCategory,
    required this.subCategory,
    this.initialIndex = 0,
  });

  final MainCategory mainCategory;
  final SubCategory subCategory;
  final int initialIndex;

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final GlobalKey _shareKey = GlobalKey();
  final Random _random = Random();
  late final PageController _pageController;
  bool _sharing = false;
  List<Quote> _order = const [];
  String _orderKey = '';

  @override
  void initState() {
    super.initState();
    final source = QuoteRepository.quotesFor(
      widget.mainCategory.id,
      widget.subCategory.id,
    );
    _orderKey = _orderKeyFor(source);
    _order = _shuffled(source);
    _pageController = PageController(initialPage: _startPage(source));
  }

  String _orderKeyFor(List<Quote> source) {
    final head = source.isEmpty ? '' : source.first.id;
    final tail = source.isEmpty ? '' : source.last.id;
    return '${localeController.isKorean}:${source.length}:$head:$tail';
  }

  List<Quote> _shuffled(List<Quote> source) {
    final copy = List<Quote>.of(source);
    copy.shuffle(_random);
    return copy;
  }

  /// Keeps the quote the user opened (home bubble) after the deck is shuffled.
  int _startPage(List<Quote> source) {
    final index = widget.initialIndex;
    if (index <= 0 || index >= source.length || _order.isEmpty) return 0;
    final id = source[index].id;
    final found = _order.indexWhere((quote) => quote.id == id);
    return found < 0 ? 0 : found;
  }

  void _syncOrder(List<Quote> source) {
    final key = _orderKeyFor(source);
    if (key == _orderKey) return;
    _orderKey = key;
    _order = _shuffled(source);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/daily_word_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.current.share,
            style: AppTheme.body.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.ink,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _openReaderMenu(BuildContext context, String currentAsset) async {
    final t = AppStrings.current;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final maxHeight = media.size.height * 0.68;
        final palette = sheetContext.palette;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.readerTheme,
                  style: AppTheme.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: QuoteBackgrounds.current.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final asset = QuoteBackgrounds.current[index];
                      final selected = asset == currentAsset;
                      return GestureDetector(
                        onTap: () {
                          QuoteBackgrounds.selected.value = asset;
                          Navigator.of(sheetContext).pop();
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected ? palette.accent : palette.border,
                              width: selected ? 2.4 : 1,
                            ),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.asset(
                            asset,
                            fit: BoxFit.cover,
                            filterQuality: visualStyleController.isClean
                                ? FilterQuality.medium
                                : FilterQuality.none,
                            isAntiAlias: visualStyleController.isClean,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  t.readerCategories,
                  style: AppTheme.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 8),
                for (final main in QuoteRepository.categories) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 2),
                    child: Text(
                      t.mainCategoryTitle(main.id),
                      style: AppTheme.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  for (final sub in main.subCategories)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 2),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      minVerticalPadding: 0,
                      title: Text(
                        t.subCategoryTitle(sub.id),
                        style: AppTheme.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      trailing: !membershipController.canAccess(main.id)
                          ? const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: AppColors.muted,
                            )
                          : main.id == widget.mainCategory.id &&
                                  sub.id == widget.subCategory.id
                              ? Icon(
                                  Icons.check_rounded,
                                  color: palette.accent,
                                )
                              : null,
                      onTap: () => _openCategory(sheetContext, main, sub),
                    ),
                ],
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.favorite_rounded,
                    color: palette.accent,
                  ),
                  title: Text(
                    t.archiveTitle,
                    style: AppTheme.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openArchive(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCategory(
    BuildContext sheetContext,
    MainCategory main,
    SubCategory sub,
  ) {
    Navigator.of(sheetContext).pop();
    if (!mounted) return;
    if (!membershipController.canAccess(main.id)) {
      _showPremiumLock();
      return;
    }
    if (main.id == widget.mainCategory.id && sub.id == widget.subCategory.id) {
      return;
    }
    selectionController.selectSubCategory(main.id, sub.id);
    final freshMain = QuoteRepository.byId(main.id);
    final freshSub = QuoteRepository.subById(main.id, sub.id) ?? sub;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuoteListScreen(
          mainCategory: freshMain,
          subCategory: freshSub,
        ),
      ),
    );
  }

  void _openArchive(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ArchiveScreen(showBack: true),
      ),
    );
  }

  Future<void> _showPremiumLock() async {
    if (!mounted) return;
    final t = AppStrings.current;
    final palette = context.palette;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            t.premiumLockedTitle,
            style: AppTheme.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            t.premiumLockedBody,
            style: AppTheme.body.copyWith(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.premiumLockedDismiss),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                membershipController.setPremium(true);
              },
              child: Text(
                t.premiumLockedCta,
                style: AppTheme.body.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleHeart({
    required Quote quote,
    required String categoryTitle,
    required String subTitle,
  }) {
    final t = AppStrings.current;
    final nowSaved = archiveController.toggle(
      id: quote.id,
      text: quote.text,
      categoryId: widget.mainCategory.id,
      categoryTitle: categoryTitle,
      subCategoryTitle: subTitle,
      author: quote.author,
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowSaved ? t.savedToArchive : t.removedFromArchive,
          style: AppTheme.body.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        localeController,
        archiveController,
        visualStyleController,
        QuoteBackgrounds.selected,
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final title = t.subCategoryTitle(widget.subCategory.id);
        final source = QuoteRepository.quotesFor(
          widget.mainCategory.id,
          widget.subCategory.id,
        );
        _syncOrder(source);
        final quotes = _order;
        final categoryTitle = t.mainCategoryTitle(widget.mainCategory.id);
        final accent = widget.mainCategory.accent;
        final topInset = MediaQuery.paddingOf(context).top;
        final now = DateTime.now();
        final daySeed = now.difference(DateTime(now.year)).inDays;
        final backgroundAsset = QuoteBackgrounds.assetFor(seed: daySeed);
        final clean = visualStyleController.isClean;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Captured area: background + quote (no header)
                RepaintBoundary(
                  key: _shareKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          backgroundAsset,
                          key: ValueKey(backgroundAsset),
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: clean
                              ? FilterQuality.medium
                              : FilterQuality.none,
                          isAntiAlias: clean,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: clean
                                ? const Color(0xFFF3EDE4)
                                : const Color(0xFFE8F1FF),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: topInset + 48),
                        child: quotes.isEmpty
                            ? Center(
                                child: Text(
                                  t.noQuotes,
                                  style: AppTheme.body.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : PageView.builder(
                                controller: _pageController,
                                scrollDirection: Axis.vertical,
                                itemCount: quotes.length,
                                itemBuilder: (context, index) {
                                  final quote = quotes[index];
                                  final saved =
                                      archiveController.contains(quote.id);
                                  return _QuotePage(
                                    quote: quote,
                                    saved: saved,
                                    shareLabel: t.share,
                                    sharing: _sharing,
                                    onHeart: () => _toggleHeart(
                                      quote: quote,
                                      categoryTitle: categoryTitle,
                                      subTitle: title,
                                    ),
                                    onShare: _shareImage,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Header overlay — not included in share image
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 28,
                              color: AppColors.ink,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTheme.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 20,
                  child: SafeArea(
                    top: false,
                    child: _ReaderMenuButton(
                      label: t.readerMenu,
                      onTap: () => _openReaderMenu(context, backgroundAsset),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuotePage extends StatelessWidget {
  const _QuotePage({
    required this.quote,
    required this.saved,
    required this.shareLabel,
    required this.sharing,
    required this.onHeart,
    required this.onShare,
  });

  final Quote quote;
  final bool saved;
  final String shareLabel;
  final bool sharing;
  final VoidCallback onHeart;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            quote.text,
            textAlign: TextAlign.center,
            style: AppTheme.body.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.55,
              color: AppColors.ink,
            ),
          ),
          if (quote.author.trim().isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              '- ${quote.author}',
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
          const Spacer(flex: 2),
          Row(
            children: [
              const SizedBox(width: 52),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              _ActionButton(
                icon: saved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '',
                color: AppColors.heart,
                onTap: onHeart,
              ),
              const SizedBox(width: 28),
              _ActionButton(
                icon: Icons.ios_share_rounded,
                label: shareLabel,
                color: AppColors.ink,
                onTap: sharing ? null : onShare,
              ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _ReaderMenuButton extends StatelessWidget {
  const _ReaderMenuButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: label,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.menu_rounded,
              size: 26,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label.isEmpty ? 16 : 18,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
