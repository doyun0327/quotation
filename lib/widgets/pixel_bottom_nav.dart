import 'package:flutter/material.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/hamfoot_icon.dart';

class PixelBottomNav extends StatelessWidget {
  const PixelBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final t = AppStrings.current;
        final items = [
          (Icons.home_outlined, Icons.home_rounded, t.homeTab),
          (Icons.groups_outlined, Icons.groups_rounded, t.ddayTab),
          (Icons.favorite_border_rounded, Icons.favorite_rounded, t.archiveTab),
          (Icons.settings_outlined, Icons.settings_rounded, t.settingsTab),
        ];

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(
              top: BorderSide(color: Color(0xFFE3E7EF), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => onTap(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (i == 2)
                              HamfootIcon(
                                size: 24,
                                color: currentIndex == i
                                    ? palette.accent
                                    : AppColors.muted,
                              )
                            else
                              Icon(
                                currentIndex == i ? items[i].$2 : items[i].$1,
                                size: 24,
                                color: currentIndex == i
                                    ? palette.accent
                                    : AppColors.muted,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              items[i].$3,
                              style: AppTheme.body.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: currentIndex == i
                                    ? palette.accent
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
