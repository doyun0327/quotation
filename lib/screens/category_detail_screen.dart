import 'package:flutter/material.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/quote_list_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/pixel_icons.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  final MainCategory category;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final t = AppStrings.current;
        final category = QuoteRepository.byId(this.category.id);
        final title = t.mainCategoryTitle(category.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  title: title,
                  accent: category.accent,
                  leadingIcon: PixelIcon(
                    kind: category.pixelIcon,
                    color: category.accent,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _IntroBanner(
                        text: t.mainCategoryBanner(category.id),
                        color: category.bannerColor,
                        accent: category.accent,
                        icon: category.pixelIcon,
                      ),
                      const SizedBox(height: 16),
                      for (final sub in category.subCategories) ...[
                        _SubCategoryTile(
                          title: t.subCategoryTitle(sub.id),
                          subtitle: t.subCategorySubtitle(sub.id),
                          icon: sub.icon,
                          iconColor: sub.iconColor,
                          iconBackground: sub.iconBackground,
                          onTap: () {
                            selectionController.selectSubCategory(
                              category.id,
                              sub.id,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => QuoteListScreen(
                                  mainCategory: category,
                                  subCategory: sub,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.accent,
    this.leadingIcon,
  });

  final String title;
  final Color accent;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
          ),
          if (leadingIcon != null) ...[
            leadingIcon!,
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTheme.body.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({
    required this.text,
    required this.color,
    required this.accent,
    required this.icon,
  });

  final String text;
  final Color color;
  final Color accent;
  final PixelIconKind icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTheme.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.45,
                color: const Color(0xFF3D4F6F),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PixelIcon(kind: icon, color: accent, size: 40),
        ],
      ),
    );
  }
}

class _SubCategoryTile extends StatelessWidget {
  const _SubCategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTheme.body.copyWith(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
