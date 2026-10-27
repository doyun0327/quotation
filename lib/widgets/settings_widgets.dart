import 'package:flutter/material.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/font_scale_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/dashed_border.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTheme.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.settingsLine, width: 1.6),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsItem extends StatelessWidget {
  const SettingsItem({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackground,
  }) : assert(icon != null || leading != null);

  final IconData? icon;
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DashedBorder(
          color: palette.settingsLine.withValues(alpha: 0.75),
          radius: 12,
          dashLength: 4,
          gapLength: 3,
          strokeWidth: 1.2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              leading ??
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconBackground ?? palette.settingsSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: iconColor ?? palette.settingsLine,
                    ),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.body.copyWith(
                        fontSize: 10,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.settingsLine,
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsOutlineButton extends StatelessWidget {
  const SettingsOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTheme.body.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Text(label),
    );
  }
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: palette.settingsSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: AppTheme.pixel.copyWith(
          fontSize: 14,
          color: const Color(0xFF4285F4),
        ),
      ),
    );
  }
}

class StyleRow extends StatelessWidget {
  const StyleRow({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<VisualStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          for (final style in VisualStyle.values) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selectedId == style.id
                        ? palette.settingsSoft
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedId == style.id
                          ? palette.settingsLine
                          : palette.border,
                      width: selectedId == style.id ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        style == VisualStyle.pixel
                            ? Icons.grid_on_rounded
                            : Icons.auto_awesome_rounded,
                        size: 22,
                        color: selectedId == style.id
                            ? palette.accent
                            : AppColors.muted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.current.styleName(style.id),
                        style: AppTheme.body.copyWith(
                          fontSize: 12,
                          fontWeight: selectedId == style.id
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selectedId == style.id
                              ? AppColors.ink
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (style != VisualStyle.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class ThemeSwatchRow extends StatelessWidget {
  const ThemeSwatchRow({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<AppPalette> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          for (final palette in AppPalette.all) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(palette),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedId == palette.id
                              ? AppColors.ink
                              : palette.border,
                          width: selectedId == palette.id ? 2.2 : 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.current.themeName(palette.id),
                      style: AppTheme.body.copyWith(
                        fontSize: 10,
                        fontWeight: selectedId == palette.id
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selectedId == palette.id
                            ? AppColors.ink
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (palette != AppPalette.all.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class FontScaleRow extends StatelessWidget {
  const FontScaleRow({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<FontScaleOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          for (final option in FontScaleOption.values) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedId == option.id
                        ? palette.settingsSoft
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedId == option.id
                          ? palette.settingsLine
                          : palette.border,
                      width: selectedId == option.id ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.current.fontSample,
                        style: AppTheme.body.copyWith(
                          fontSize: option.sampleSize,
                          fontWeight: FontWeight.w900,
                          color: selectedId == option.id
                              ? palette.accent
                              : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.current.fontName(option.id),
                        style: AppTheme.body.copyWith(
                          fontSize: 10,
                          fontWeight: selectedId == option.id
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selectedId == option.id
                              ? AppColors.ink
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (option != FontScaleOption.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
