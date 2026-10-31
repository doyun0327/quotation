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
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/widgets/category_pixel_icon.dart';
import 'package:quotation/widgets/app_pixel_icon.dart';
import 'package:quotation/widgets/dashed_border.dart';
import 'package:quotation/widgets/sign_in_flow.dart';

class CategoryBrowseSection extends StatelessWidget {
  const CategoryBrowseSection({
    super.key,
    this.onSubcategoryTap,
  });

  final void Function(MainCategory main, SubCategory sub)? onSubcategoryTap;

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
                if (!await suggestSignInBeforePurchase(context)) return;
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        localeController,
        membershipController,
        themeController,
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final palette = context.palette;
        final tiles = <Widget>[];
        for (final category in QuoteRepository.categories) {
          final locked = !membershipController.canAccess(category.id);
          for (final sub in category.subCategories) {
            if (tiles.isNotEmpty) tiles.add(const SizedBox(height: 10));
            tiles.add(
              _SubcategoryRow(
                title: t.subCategoryTitle(sub.id),
                subtitle: t.subCategorySubtitle(sub.id),
                categoryId: sub.id,
                palette: palette,
                locked: locked,
                onTap: () {
                  if (locked) {
                    _showPremiumLockDialog(context);
                    return;
                  }
                  onSubcategoryTap?.call(category, sub);
                },
              ),
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: tiles,
        );
      },
    );
  }
}

class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({
    required this.title,
    required this.subtitle,
    required this.categoryId,
    required this.palette,
    required this.locked,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String categoryId;
  final AppPalette palette;
  final bool locked;
  final VoidCallback? onTap;

  static const _ink = Color(0xFF3A3834);
  static const _caption = Color(0xFF8E877E);

  @override
  Widget build(BuildContext context) {
    final tone = CategorySky.of(categoryId, palette);
    final row = Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.plate,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tone.plateLine, width: 1),
          ),
          child: CategoryPixelIcon(categoryId: categoryId, size: 28),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTheme.body.copyWith(
                  fontSize: 11.5,
                  height: 1.3,
                  color: _caption,
                ),
              ),
            ],
          ),
        ),
        AppPixelIcon(
          locked ? AppGlyph.lock : AppGlyph.chevronRight,
          size: 18,
          color: CategorySky.ink(palette),
        ),
      ],
    );

    final body = Opacity(
      opacity: locked ? 0.62 : 1,
      child: DashedBorder(
        color: CategorySky.border(palette),
        strokeWidth: 1.5,
        dashLength: 4,
        gapLength: 3.5,
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        backgroundColor: tone.card,
        alwaysDashed: true,
        child: row,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: body,
      ),
    );
  }
}
