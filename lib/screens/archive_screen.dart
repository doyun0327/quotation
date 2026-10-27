import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotation/data/archive_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/widgets/app_pixel_icon.dart';
import 'package:quotation/widgets/category_pixel_icon.dart';
import 'package:quotation/widgets/dashed_border.dart';
import 'package:quotation/widgets/hamfoot_icon.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key, this.showBack = false});

  /// Pushed from the quote reader. Back returns to that quote.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final page = SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          archiveController,
          localeController,
          themeController,
        ]),
        builder: (context, _) {
          final t = AppStrings.current;
          final groups = archiveController.groupedByCategory;
          final total = archiveController.items.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(showBack ? 4 : 20, 8, 20, 8),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const AppPixelIcon(
                          AppGlyph.chevronLeft,
                          size: 20,
                          color: AppColors.ink,
                        ),
                      ),
                    const HamfootIcon(size: 24),
                    const SizedBox(width: 8),
                    Text(
                      t.archiveTitle,
                      style: AppTheme.body.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: palette.accent,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$total',
                      style: AppTheme.pixel.copyWith(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const HamfootIcon(size: 42),
                            const SizedBox(height: 12),
                            Text(
                              t.archiveEmptyTitle,
                              style: AppTheme.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final subId = group.subCategoryId;
                          final title = (subId != null && subId.isNotEmpty)
                              ? t.subCategoryTitle(subId)
                              : t.mainCategoryTitle(group.categoryId);
                          final markId = (subId != null && subId.isNotEmpty)
                              ? subId
                              : _archiveMarkId(group.categoryId);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == groups.length - 1 ? 0 : 22,
                            ),
                            child: _CategoryArchiveSection(
                              title: title,
                              categoryId: markId,
                              items: group.items,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
    if (!showBack) return page;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: page,
    );
  }
}

String _archiveMarkId(String categoryId) {
  return switch (categoryId) {
    'daily' => 'gratitude',
    'comfort' => 'tired',
    'faith' => 'buddhism',
    'literature' => 'quotes',
    _ => categoryId,
  };
}

class _CategoryArchiveSection extends StatelessWidget {
  const _CategoryArchiveSection({
    required this.title,
    required this.categoryId,
    required this.items,
  });

  final String title;
  final String categoryId;
  final List<ArchiveItem> items;

  @override
  Widget build(BuildContext context) {
    final tone = CategorySky.of(categoryId, context.palette);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.plate,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tone.plateLine),
              ),
              child: CategoryPixelIcon(categoryId: categoryId, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTheme.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: CategorySky.ink(context.palette),
                ),
              ),
            ),
            Text(
              '${items.length}',
              style: AppTheme.pixel.copyWith(
                fontSize: 8,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          _ArchiveQuoteCard(item: items[i], borderColor: CategorySky.border(context.palette)),
          if (i < items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ArchiveQuoteCard extends StatelessWidget {
  const _ArchiveQuoteCard({
    required this.item,
    required this.borderColor,
  });

  final ArchiveItem item;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy. MM. dd').format(item.savedAt);

    return DashedBorder(
      color: borderColor,
      radius: 14,
      strokeWidth: 2,
      dashLength: 4,
      gapLength: 3,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.text,
            style: AppTheme.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (item.author != null && item.author!.trim().isNotEmpty)
                '- ${item.author}',
              date,
            ].where((e) => e.isNotEmpty).join('  ·  '),
            style: AppTheme.body.copyWith(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
