import 'package:flutter/material.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/legal/legal_copy.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// Terms and privacy policy in the language selected in the app.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final copy = LegalCopy.forLanguage(localeController.language);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 28,
                          color: AppColors.ink,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.current.termsTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      Text(
                        copy.updated,
                        style: AppTheme.body.copyWith(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Document(
                        title: copy.termsHeading,
                        blocks: copy.terms,
                        accent: palette.accent,
                      ),
                      const SizedBox(height: 28),
                      _Document(
                        title: copy.privacyHeading,
                        blocks: copy.privacy,
                        accent: palette.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Document extends StatelessWidget {
  const _Document({
    required this.title,
    required this.blocks,
    required this.accent,
  });

  final String title;
  final List<LegalBlock> blocks;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.body.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
        const SizedBox(height: 12),
        for (final block in blocks) ...[
          Text(
            block.heading,
            style: AppTheme.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            block.body,
            style: AppTheme.body.copyWith(
              fontSize: 13.5,
              height: 1.55,
              color: const Color(0xFF3C4553),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
