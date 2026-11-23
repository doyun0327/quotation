import 'package:flutter/material.dart';
import 'package:quotation/widgets/subscribe_flow.dart';
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
import 'package:quotation/widgets/subscription_terms.dart';

class CategoryBrowseSection extends StatelessWidget {
  const CategoryBrowseSection({
    super.key,
    this.onSubcategoryTap,
    this.onToMyselfTap,
    this.onlyCategoryIds,
    this.gridHeight,
  });

  /// Home grid: the height the tiles share, so they reach the bottom of the
  /// screen with no empty band below. Null keeps them square.
  final double? gridHeight;

  final void Function(MainCategory main, SubCategory sub)? onSubcategoryTap;

  /// Home: the "나에게 건네는 말" row, which stands in for every
  /// [QuoteRepository.toMyselfCategoryIds] row. Null lists those rows here.
  final VoidCallback? onToMyselfTap;

  /// Only these main categories (the "나에게 건네는 말" screen).
  final Set<String>? onlyCategoryIds;

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
          content: SubscriptionPromptBody(
            message: t.premiumLockedBody,
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
                if (!await suggestSignInBeforePurchase(context) ||
                    !context.mounted) {
                  return;
                }
                await runMonthlySubscription(context);
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
        // Home (onToMyselfTap set): square tiles, two per row.
        final square = onToMyselfTap != null;
        Widget item({
          required String title,
          required String subtitle,
          required String categoryId,
          required bool locked,
          required VoidCallback? onTap,
        }) =>
            square
                ? _SquareTile(
                    title: title,
                    subtitle: subtitle,
                    categoryId: categoryId,
                    palette: palette,
                    locked: locked,
                    onTap: onTap,
                  )
                : _SubcategoryRow(
                    title: title,
                    subtitle: subtitle,
                    categoryId: categoryId,
                    palette: palette,
                    locked: locked,
                    onTap: onTap,
                  );
        final open = <Widget>[];
        final locked = <Widget>[];
        if (onToMyselfTap != null) {
          open.add(
            item(
              title: t.toMyselfTitle,
              subtitle: t.toMyselfSubtitle,
              categoryId: 'love',
              locked: false,
              onTap: onToMyselfTap,
            ),
          );
        }
        for (final category in QuoteRepository.categories) {
          if (onlyCategoryIds != null &&
              !onlyCategoryIds!.contains(category.id)) {
            continue;
          }
          if (onToMyselfTap != null &&
              QuoteRepository.toMyselfCategoryIds.contains(category.id)) {
            continue;
          }
          final isLocked = !membershipController.canAccess(category.id);
          for (final sub in category.subCategories) {
            final tile = item(
              title: t.subCategoryTitle(sub.id),
              subtitle: t.subCategorySubtitle(sub.id),
              categoryId: sub.id,
              locked: isLocked,
              onTap: () {
                if (isLocked) {
                  _showPremiumLockDialog(context);
                  return;
                }
                onSubcategoryTap?.call(category, sub);
              },
            );
            (isLocked ? locked : open).add(tile);
          }
        }

        if (square) {
          // Locked tiles after the open ones, as in the row list.
          // Checkerboard tint: tiles 1 and 4 match, 2 and 3 match.
          final all = [
            for (final (i, tile) in [...open, ...locked].indexed)
              (tile as _SquareTile).withTint(((i ~/ 2) + i).isEven),
          ];
          const gap = 12.0;
          final rows = (all.length + 1) ~/ 2;
          final rowHeight = gridHeight == null
              ? null
              : ((gridHeight! - gap * (rows - 1)) / rows)
                    .clamp(140.0, double.infinity);
          Widget cell(Widget child) => rowHeight == null
              ? AspectRatio(aspectRatio: 1, child: child)
              : SizedBox(height: rowHeight, child: child);
          return Column(
            children: [
              for (var i = 0; i < all.length; i += 2) ...[
                if (i > 0) const SizedBox(height: gap),
                Row(
                  children: [
                    Expanded(child: cell(all[i])),
                    const SizedBox(width: gap),
                    Expanded(
                      child: i + 1 < all.length
                          ? cell(all[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          );
        }

        final tiles = <Widget>[
          for (var i = 0; i < open.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            open[i],
          ],
          // Locked rows stay below the free ones so the home matches the
          // open-category mock (gratitude + love first).
          for (final tile in locked) ...[
            const SizedBox(height: 10),
            tile,
          ],
        ];

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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTheme.body.copyWith(
                  fontSize: 12,
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
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
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

/// Home: one category as a square card (icon, title, short line).
class _SquareTile extends StatelessWidget {
  const _SquareTile({
    required this.title,
    required this.subtitle,
    required this.categoryId,
    required this.palette,
    required this.locked,
    this.onTap,
    this.tinted = false,
  });

  final String title;
  final String subtitle;
  final String categoryId;
  final AppPalette palette;
  final bool locked;
  final VoidCallback? onTap;
  final bool tinted;

  _SquareTile withTint(bool value) => _SquareTile(
        title: title,
        subtitle: subtitle,
        categoryId: categoryId,
        palette: palette,
        locked: locked,
        onTap: onTap,
        tinted: value,
      );

  static const _ink = Color(0xFF3A3834);
  static const _caption = Color(0xFF8E877E);

  @override
  Widget build(BuildContext context) {
    final tone = CategorySky.ofTint(tinted, palette);
    final body = Opacity(
      opacity: locked ? 0.62 : 1,
      child: DashedBorder(
        color: CategorySky.border(palette),
        strokeWidth: 1.5,
        dashLength: 4,
        gapLength: 3.5,
        radius: 18,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        backgroundColor: tone.card,
        alwaysDashed: true,
        // Icon in the middle, title and line under it. No arrow; a locked
        // tile keeps a small lock in its corner.
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tone.plate,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tone.plateLine, width: 1),
                    ),
                    child: CategoryPixelIcon(categoryId: categoryId, size: 36),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.25,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(
                      fontSize: 11.5,
                      height: 1.3,
                      color: _caption,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Positioned(
                top: 2,
                right: 2,
                child: AppPixelIcon(
                  AppGlyph.lock,
                  size: 16,
                  color: CategorySky.ink(palette),
                ),
              ),
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: body,
      ),
    );
  }
}
