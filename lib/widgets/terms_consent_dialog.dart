import 'package:flutter/material.dart';
import 'package:quotation/data/terms_consent.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/screens/legal_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// Blocks the app until the terms are accepted. Back and outside taps do
/// nothing, because nothing may be written before this is agreed to.
Future<void> showTermsConsentDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final t = AppStrings.current;
      final accent = dialogContext.palette.accent;
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            t.termsConsentTitle,
            style: AppTheme.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.termsConsentBody,
                  style: AppTheme.body.copyWith(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: accent,
                  ),
                  child: Text(t.termsTitle),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: () async {
                await TermsConsent.accept();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(t.termsConsentAccept),
            ),
          ],
        ),
      );
    },
  );
}
