import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/dashed_border.dart';

class TodaysWordCard extends StatelessWidget {
  const TodaysWordCard({
    super.key,
    required this.date,
    required this.text,
  });

  final DateTime date;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dateLabel = DateFormat('yyyy. MM. dd').format(date);

    return DashedBorder(
      radius: 12,
      color: palette.settingsLine,
      strokeWidth: 2,
      dashLength: 4,
      gapLength: 3,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                color: AppColors.heart,
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: localeController,
                builder: (context, _) {
                  return Text(
                    AppStrings.current.todaysFortune,
                    style: AppTheme.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: palette.accent,
                    ),
                  );
                },
              ),
              const Spacer(),
              Text(
                dateLabel,
                style: AppTheme.pixel.copyWith(
                  fontSize: 7,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTheme.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
