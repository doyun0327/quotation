import 'package:flutter/material.dart';
import 'package:quotation/data/archive_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/dashed_border.dart';

class SearchableQuote {
  const SearchableQuote({
    required this.quote,
    required this.categoryId,
    required this.categoryTitle,
    required this.subCategoryTitle,
    required this.subCategoryId,
  });

  final Quote quote;
  final String categoryId;
  final String categoryTitle;
  final String subCategoryTitle;
  final String subCategoryId;
}

class QuoteSearchScreen extends StatefulWidget {
  const QuoteSearchScreen({
    super.key,
    required this.title,
    required this.accent,
    required this.items,
  });

  final String title;
  final Color accent;
  final List<SearchableQuote> items;

  static List<SearchableQuote> fromMainCategory(MainCategory category) {
    final t = AppStrings.current;
    return [
      for (final sub in category.subCategories)
        for (final quote in sub.quotes)
          SearchableQuote(
            quote: quote,
            categoryId: category.id,
            categoryTitle: t.mainCategoryTitle(category.id),
            subCategoryTitle: t.subCategoryTitle(sub.id),
            subCategoryId: sub.id,
          ),
    ];
  }

  static List<SearchableQuote> fromSubCategory({
    required MainCategory mainCategory,
    required SubCategory subCategory,
  }) {
    final t = AppStrings.current;
    return [
      for (final quote in subCategory.quotes)
        SearchableQuote(
          quote: quote,
          categoryId: mainCategory.id,
          categoryTitle: t.mainCategoryTitle(mainCategory.id),
          subCategoryTitle: t.subCategoryTitle(subCategory.id),
          subCategoryId: subCategory.id,
        ),
    ];
  }

  @override
  State<QuoteSearchScreen> createState() => _QuoteSearchScreenState();
}

class _QuoteSearchScreenState extends State<QuoteSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<SearchableQuote> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final t = AppStrings.current;

    return widget.items.where((item) {
      final text = item.quote.text.toLowerCase();
      final author = item.quote.author.toLowerCase();
      final sub = t.subCategoryTitle(item.subCategoryId).toLowerCase();
      return text.contains(q) || author.contains(q) || sub.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final results = _results;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final t = AppStrings.current;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: widget.accent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.search,
                            style: AppTheme.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: t.searchHint,
                              hintStyle: AppTheme.body.copyWith(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                              border: InputBorder.none,
                              icon: Icon(
                                Icons.search_rounded,
                                color: widget.accent,
                              ),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() => _query = '');
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: AppColors.muted,
                                        size: 20,
                                      ),
                                    ),
                            ),
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _query.trim().isEmpty
                          ? t.searchIn(widget.title)
                          : t.searchResults(results.length),
                      style: AppTheme.body.copyWith(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _query.trim().isEmpty
                      ? Center(
                          child: Text(
                            t.searchExample,
                            style: AppTheme.body.copyWith(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        )
                      : results.isEmpty
                          ? Center(
                              child: Text(
                                t.searchEmpty,
                                style: AppTheme.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                            )
                          : ListenableBuilder(
                              listenable: archiveController,
                              builder: (context, _) {
                                return ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                  itemCount: results.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = results[index];
                                    return _SearchResultCard(
                                      item: item,
                                      borderColor: palette.settingsLine,
                                    );
                                  },
                                );
                              },
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

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.item,
    required this.borderColor,
  });

  final SearchableQuote item;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final quote = item.quote;
    final saved = archiveController.contains(quote.id);
    final t = AppStrings.current;

    return DashedBorder(
      color: borderColor,
      radius: 14,
      strokeWidth: 2,
      dashLength: 4,
      gapLength: 3,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.subCategoryTitle(item.subCategoryId),
            style: AppTheme.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            quote.text,
            style: AppTheme.body.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
          if (quote.author.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '- ${quote.author}',
              style: AppTheme.body.copyWith(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: () {
                  final nowSaved = archiveController.toggle(
                    id: quote.id,
                    text: quote.text,
                    categoryId: item.categoryId,
                    categoryTitle: t.mainCategoryTitle(item.categoryId),
                    subCategoryTitle: t.subCategoryTitle(item.subCategoryId),
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
                },
                icon: Icon(
                  saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: AppColors.heart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
