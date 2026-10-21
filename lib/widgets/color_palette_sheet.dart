import 'package:flutter/material.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/pixel_color_tile.dart';

/// Bottom sheet: pick a color from a palette board (+ optional transparent).
Future<int?> showColorPaletteSheet(
  BuildContext context, {
  required int initialArgb,
  bool allowTransparent = false,
  String? title,
  bool pixelStyle = false,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: pixelStyle ? const Color(0xFFFFF8F0) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(pixelStyle ? 6 : 20),
      ),
    ),
    builder: (ctx) => _ColorPaletteSheet(
      initialArgb: initialArgb,
      allowTransparent: allowTransparent,
      title: title,
      pixelStyle: pixelStyle,
    ),
  );
}

class _ColorPaletteSheet extends StatefulWidget {
  const _ColorPaletteSheet({
    required this.initialArgb,
    required this.allowTransparent,
    this.title,
    this.pixelStyle = false,
  });

  final int initialArgb;
  final bool allowTransparent;
  final String? title;
  final bool pixelStyle;

  @override
  State<_ColorPaletteSheet> createState() => _ColorPaletteSheetState();
}

class _ColorPaletteSheetState extends State<_ColorPaletteSheet> {
  late int _selected;

  /// Soft pastel rows for pixel widget bg (incl. cream tones from reference).
  static const _pixelPresetRows = <List<int>>[
    kPixelCreamShades,
    [
      0xFFFFFFFF,
      0xFFFFF3E8,
      0xFFFFE4EC,
      0xFFFFD6E8,
      0xFFF8BBD0,
      0xFFF48FB1,
      0xFFF26B8A,
      0xFFE85A7A,
    ],
    [
      0xFFE8F5E9,
      0xFFC8E6C9,
      0xFFA5D6A7,
      0xFFC8F0E0,
      0xFF81C784,
      0xFF66BB6A,
      0xFF43A047,
      0xFF2E7D32,
    ],
    [
      0xFFE3F2FD,
      0xFFBBDEFB,
      0xFFD4E5FF,
      0xFF90CAF9,
      0xFF64B5F6,
      0xFF42A5F5,
      0xFF1E88E5,
      0xFF1565C0,
    ],
    [
      0xFFF3E5F5,
      0xFFE1BEE7,
      0xFFCE93D8,
      0xFFBA68C8,
      0xFFAB47BC,
      0xFF8E24AA,
      0xFF6A1B9A,
      0xFF4A148C,
    ],
    [
      0xFFFFF8E1,
      0xFFFFECB3,
      0xFFFFE082,
      0xFFFFD54F,
      0xFFFFCA28,
      0xFFFFB300,
      0xFFFFA000,
      0xFFFF6F00,
    ],
    [
      0xFFEFEBE9,
      0xFFD7CCC8,
      0xFFBCAAA4,
      0xFFA1887F,
      0xFF8D6E63,
      0xFF6D4C41,
      0xFF5D4037,
      0xFF3E2723,
    ],
    [
      0xFFFAFAFA,
      0xFFEEEEEE,
      0xFFE0E0E0,
      0xFFBDBDBD,
      0xFF9E9E9E,
      0xFF757575,
      0xFF616161,
      0xFF212121,
    ],
  ];

  static const _presetRows = <List<int>>[
    [
      0xFFFFFFFF,
      0xFFF5F5F5,
      0xFFECEFF1,
      0xFFCFD8DC,
      0xFF90A4AE,
      0xFF546E7A,
      0xFF37474F,
      0xFF212121,
    ],
    [
      0xFFFFEBEE,
      0xFFFFCDD2,
      0xFFEF9A9A,
      0xFFE57373,
      0xFFF44336,
      0xFFD32F2F,
      0xFFB71C1C,
      0xFF880E4F,
    ],
    [
      0xFFFCE4EC,
      0xFFF8BBD0,
      0xFFF48FB1,
      0xFFF06292,
      0xFFE91E63,
      0xFFC2185B,
      0xFFAD1457,
      0xFFF26B8A,
    ],
    [
      0xFFF3E5F5,
      0xFFE1BEE7,
      0xFFCE93D8,
      0xFFBA68C8,
      0xFF9C27B0,
      0xFF7B1FA2,
      0xFF4A148C,
      0xFF311B92,
    ],
    [
      0xFFE8EAF6,
      0xFFC5CAE9,
      0xFF9FA8DA,
      0xFF7986CB,
      0xFF3F51B5,
      0xFF303F9F,
      0xFF1A237E,
      0xFF0D47A1,
    ],
    [
      0xFFE3F2FD,
      0xFFBBDEFB,
      0xFF90CAF9,
      0xFF64B5F6,
      0xFF2196F3,
      0xFF1976D2,
      0xFF1565C0,
      0xFF0D47A1,
    ],
    [
      0xFFE0F7FA,
      0xFFB2EBF2,
      0xFF80DEEA,
      0xFF4DD0E1,
      0xFF00BCD4,
      0xFF0097A7,
      0xFF006064,
      0xFF004D40,
    ],
    [
      0xFFE8F5E9,
      0xFFC8E6C9,
      0xFFA5D6A7,
      0xFF81C784,
      0xFF4CAF50,
      0xFF388E3C,
      0xFF2E7D32,
      0xFF1B5E20,
    ],
    [
      0xFFFFF8E1,
      0xFFFFECB3,
      0xFFFFE082,
      0xFFFFD54F,
      0xFFFFC107,
      0xFFFFA000,
      0xFFFF6F00,
      0xFFE65100,
    ],
    [
      0xFFFFF3E0,
      0xFFFFE0B2,
      0xFFFFCC80,
      0xFFFFB74D,
      0xFFFF9800,
      0xFFF57C00,
      0xFFE65100,
      0xFFBF360C,
    ],
    [
      0xFFEFEBE9,
      0xFFD7CCC8,
      0xFFBCAAA4,
      0xFFA1887F,
      0xFF795548,
      0xFF5D4037,
      0xFF4E342E,
      0xFF3E2723,
    ],
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialArgb;
  }

  Widget _swatch(int argb, {required bool transparent}) {
    final selected = transparent
        ? (_selected & 0xFF000000) == 0
        : _selected == argb ||
            ((_selected & 0x00FFFFFF) == (argb & 0x00FFFFFF) &&
                (_selected & 0xFF000000) != 0);
    if (widget.pixelStyle) {
      return PixelColorTile(
        argb: argb,
        selected: selected,
        transparent: transparent,
        onTap: () =>
            setState(() => _selected = transparent ? 0x00000000 : argb),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _selected = transparent ? 0x00000000 : argb),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: transparent ? Colors.transparent : Color(argb),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFFF26B8A) : const Color(0xFFE0E0E0),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: transparent ? CustomPaint(painter: _CheckerPainter()) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final rows = widget.pixelStyle ? _pixelPresetRows : _presetRows;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E6F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.title ?? t.ddayDecoratePickColor,
            style: AppTheme.body.copyWith(
              fontFamily: widget.pixelStyle ? 'Galmuri' : null,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2C3340),
            ),
          ),
          const SizedBox(height: 14),
          if (widget.allowTransparent) ...[
            Row(
              children: [
                _swatch(0x00000000, transparent: true),
                const SizedBox(width: 10),
                Text(
                  t.ddayDecorateTransparent,
                  style: AppTheme.body.copyWith(
                    fontFamily: widget.pixelStyle ? 'Galmuri' : null,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5B6B8C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height *
                  (widget.pixelStyle ? 0.52 : 0.36),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final row in rows) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final c in row)
                          _swatch(c | 0xFF000000, transparent: false),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF26B8A),
                shape: widget.pixelStyle
                    ? const RoundedRectangleBorder()
                    : const StadiumBorder(),
                side: widget.pixelStyle
                    ? const BorderSide(color: Color(0xFF1A1A22), width: 2)
                    : null,
              ),
              child: Text(
                t.ddayDecoratePickColorDone,
                style: AppTheme.body.copyWith(
                  fontFamily: widget.pixelStyle ? 'Galmuri' : null,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final cell = size.width / n;
    final light = Paint()..color = const Color(0xFFE8E8E8);
    final dark = Paint()..color = const Color(0xFFBDBDBD);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          ((x + y).isEven) ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
