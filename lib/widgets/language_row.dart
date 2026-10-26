import 'package:flutter/material.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

class LanguageRow extends StatelessWidget {
  const LanguageRow({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final current = AppLanguage.byId(selectedId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          for (final language in AppLanguage.values) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(language),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selectedId == language.id
                        ? palette.settingsSoft
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedId == language.id
                          ? palette.settingsLine
                          : palette.border,
                      width: selectedId == language.id ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        language.mark,
                        style: AppTheme.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: selectedId == language.id
                              ? palette.accent
                              : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        language.label(current),
                        style: AppTheme.body.copyWith(
                          fontSize: 11,
                          fontWeight: selectedId == language.id
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selectedId == language.id
                              ? AppColors.ink
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (language != AppLanguage.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
