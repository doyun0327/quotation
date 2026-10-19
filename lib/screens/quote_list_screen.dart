import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quotation/data/archive_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
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
  late final PageController _pageController;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
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
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final title = t.subCategoryTitle(widget.subCategory.id);
        final quotes = QuoteRepository.quotesFor(
          widget.mainCategory.id,
          widget.subCategory.id,
        );
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
          const Spacer(flex: 2),
          Row(
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
          const SizedBox(height: 28),
        ],
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
