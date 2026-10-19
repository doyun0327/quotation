import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotation/data/archive_controller.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/dashed_border.dart';
import 'package:quotation/widgets/pixel_icons.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([archiveController, localeController]),
        builder: (context, _) {
          final t = AppStrings.current;
          final groups = archiveController.groupedByCategory;
          final total = archiveController.items.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.heart),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  t.archiveHint,
                  style: AppTheme.body.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),
              Expanded(
                child: groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 42,
                              color: AppColors.heart.withValues(alpha: 0.55),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.archiveEmptyTitle,
                              style: AppTheme.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.archiveEmptyHint,
                              style: AppTheme.body.copyWith(
                                fontSize: 12,
                                color: AppColors.muted,
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
                          final category = QuoteRepository.byId(group.categoryId);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == groups.length - 1 ? 0 : 22,
                            ),
                            child: _CategoryArchiveSection(
                              title: t.mainCategoryTitle(group.categoryId),
                              accent: category.accent,
                              icon: category.pixelIcon,
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
  }
}

class _CategoryArchiveSection extends StatelessWidget {
  const _CategoryArchiveSection({
    required this.title,
    required this.accent,
    required this.icon,
    required this.items,
  });

  final String title;
  final Color accent;
  final PixelIconKind icon;
  final List<ArchiveItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PixelIcon(kind: icon, color: accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTheme.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: accent,
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
          _ArchiveQuoteCard(item: items[i], borderColor: palette.settingsLine),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.subCategoryTitle != null) ...[
                  Text(
                    item.subCategoryTitle!,
                    style: AppTheme.body.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
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
                    if (item.author != null) '- ${item.author}',
                    date,
                  ].where((e) => e.isNotEmpty).join('  ·  '),
                  style: AppTheme.body.copyWith(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => archiveController.remove(item.id),
            icon: const Icon(
              Icons.favorite_rounded,
              color: AppColors.heart,
            ),
            tooltip: '보관 해제',
          ),
        ],
      ),
    );
  }
}
