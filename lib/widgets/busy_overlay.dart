import 'package:flutter/material.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/style_text_scale.dart';

/// Same look as the room screen's "방 확인 중…": dimmed page, a card with a
/// spinner and [label]. It swallows taps so nothing else starts meanwhile.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3C4C60);
    return StyleTextScale.pixelOnly(
      context,
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: context.palette.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(
                      fontFamily: 'Galmuri',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
