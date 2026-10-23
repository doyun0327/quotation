import 'package:flutter/material.dart';
import 'package:quotation/data/billing_controller.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/dashed_border.dart';
import 'package:quotation/widgets/pixel_icons.dart';

class CategoryBrowseSection extends StatelessWidget {
  const CategoryBrowseSection({
    super.key,
    this.onCategoryTap,
  });

  final ValueChanged<MainCategory>? onCategoryTap;

  Future<void> _showPremiumLockDialog(BuildContext context) async {
    final t = AppStrings.current;
    final palette = context.palette;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: palette.border, width: 1.5),
          ),
          title: Text(
            t.premiumLockedTitle,
            style: AppTheme.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
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
              child: Text(
                t.premiumLockedDismiss,
                style: AppTheme.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final code = await billingController.buyMonthly();
                if (!context.mounted || code == null) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.current.billingError(code)),
                  ),
                );
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListenableBuilder(
      listenable: Listenable.merge([
        localeController,
        membershipController,
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final categories = QuoteRepository.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const _PixelBadge(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.browseTitle,
                    style: AppTheme.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final locked = !membershipController.canAccess(category.id);
                return _CategoryCard(
                  category: category,
                  title: t.mainCategoryTitle(category.id),
                  lines: t.mainCategoryLines(category.id),
                  locked: locked,
                  onTap: () {
                    if (locked) {
                      _showPremiumLockDialog(context);
                      return;
                    }
                    onCategoryTap?.call(category);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PixelBadge extends StatelessWidget {
  const _PixelBadge();

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFFF9B5C),
      Color(0xFF5B8DEF),
      Color(0xFFFFC48A),
      Color(0xFF8EC5FF),
    ];

    return SizedBox(
      width: 16,
      height: 16,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: [
          for (final color in colors) ColoredBox(color: color),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.title,
    required this.lines,
    required this.locked,
    this.onTap,
  });

  final MainCategory category;
  final String title;
  final List<String> lines;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clean = visualStyleController.isClean;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(clean ? 18 : 10),
        child: Opacity(
          opacity: locked ? 0.55 : 1,
          child: DashedBorder(
            color: category.border,
            radius: clean ? 18 : 10,
            strokeWidth: 2,
            dashLength: 4,
            gapLength: 3,
            backgroundColor: category.background,
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PixelIcon(
                  kind: category.pixelIcon,
                  color: category.accent,
                  size: clean ? 30 : 34,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTheme.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2F4A6E),
                        ),
                      ),
                    ),
                    Text(
                      ' >',
                      style: AppTheme.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2F4A6E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final line in lines)
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
