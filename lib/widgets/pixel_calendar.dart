import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';

class PixelCalendar extends StatelessWidget {
  const PixelCalendar({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final month = DateFormat('MMM').format(date).toUpperCase();
    final day = DateFormat('d').format(date);
    final weekday = DateFormat('EEE').format(date).toUpperCase();
    final clean = visualStyleController.isClean;
    final radius = clean ? 14.0 : 6.0;

    return Container(
      width: 72,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.border, width: clean ? 1 : 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(clean ? 8 : 3),
            ),
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: AppTheme.pixel.copyWith(
                fontSize: clean ? 10 : 7,
                color: palette.accent,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            day,
            style: AppTheme.pixel.copyWith(
              fontSize: clean ? 22 : 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weekday,
            style: AppTheme.pixel.copyWith(
              fontSize: clean ? 10 : 7,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
