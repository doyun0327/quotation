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
              const CustomPaint(
                size: Size.square(16),
                painter: _CloverPainter(),
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

/// Four-leaf clover drawn as a few filled pixels.
class _CloverPainter extends CustomPainter {
  const _CloverPainter();

  static const _green = Color(0xFF3DAA5C);
  static const _stem = Color(0xFF2E8A45);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 12;
    final leaf = Paint()
      ..color = _green
      ..isAntiAlias = false;
    final stem = Paint()
      ..color = _stem
      ..isAntiAlias = false;

    void pixel(int x, int y, Paint paint) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, unit + 0.2, unit + 0.2),
        paint,
      );
    }

    const leaves = <List<int>>[
      [2, 0], [3, 0], [7, 0], [8, 0],
      [1, 1], [2, 1], [3, 1], [4, 1], [6, 1], [7, 1], [8, 1], [9, 1],
      [2, 2], [3, 2], [4, 2], [6, 2], [7, 2], [8, 2],
      [4, 3], [5, 3], [6, 3],
      [2, 4], [3, 4], [4, 4], [6, 4], [7, 4], [8, 4],
      [1, 5], [2, 5], [3, 5], [4, 5], [6, 5], [7, 5], [8, 5], [9, 5],
      [2, 6], [3, 6], [7, 6], [8, 6],
    ];
    for (final p in leaves) {
      pixel(p[0], p[1], leaf);
    }
    for (final p in const [
      [5, 4],
      [5, 5],
      [5, 7],
      [5, 8],
      [5, 9],
      [6, 10],
    ]) {
      pixel(p[0], p[1], stem);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
