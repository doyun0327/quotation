import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// iPhone apps cannot add a home-screen widget themselves (Galaxy opens the
/// system add sheet), so export explains the steps instead.
abstract final class IosWidgetGuide {
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Widget names exactly as the iPhone widget gallery shows them
  /// (`configurationDisplayName` in ios/DearlyWidgets).
  static const togetherWidgetName = '함께';
  static const characterWidgetName = '오늘의 말';

  /// Bottom sheet with the add-widget steps for [widgetName].
  static Future<void> show(
    BuildContext context, {
    required String widgetName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GuideSheet(widgetName: widgetName),
    );
  }
}

class _GuideSheet extends StatelessWidget {
  const _GuideSheet({required this.widgetName});

  final String widgetName;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final accent = context.palette.accent;
    final steps = [
      t.iosWidgetGuideStep1,
      t.iosWidgetGuideStep2,
      t.iosWidgetGuideStep3(widgetName),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.iosWidgetGuideTitle,
              style: AppTheme.body.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.iosWidgetGuideSubtitle,
              style: AppTheme.body.copyWith(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            for (final (index, step) in steps.indexed) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppTheme.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: AppTheme.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  t.iosWidgetGuideOk,
                  style: AppTheme.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
