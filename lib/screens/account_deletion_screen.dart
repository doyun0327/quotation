import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// Confirms account and related cloud data deletion.
class AccountDeletionScreen extends StatelessWidget {
  const AccountDeletionScreen({super.key});

  Future<void> _deleteInApp(BuildContext context) async {
    final t = AppStrings.current;
    final ok = await authController.deleteAccount();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? t.accountDeleteDone : t.accountDeleteFailed)),
    );
    if (ok) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([localeController, authController]),
      builder: (context, _) {
        final t = AppStrings.current;
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
                          t.accountDeleteGuideTitle,
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
                        t.accountDeleteAsk,
                        style: AppTheme.body.copyWith(
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.accountDeleteDataNotice,
                        style: AppTheme.body.copyWith(
                          fontSize: 15,
                          height: 1.55,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        t.accountDeleteSubscriptionHeading,
                        style: AppTheme.body.copyWith(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.accountDeleteSubscriptionKeep,
                        style: AppTheme.body.copyWith(
                          fontSize: 15,
                          height: 1.55,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.accountDeleteSubscriptionCancel,
                        style: AppTheme.body.copyWith(
                          fontSize: 15,
                          height: 1.55,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.accountDeleteSubscriptionRenew,
                        style: AppTheme.body.copyWith(
                          fontSize: 15,
                          height: 1.55,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: authController.isBusy
                            ? null
                            : () => _deleteInApp(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          t.accountDeleteTitle,
                          style: AppTheme.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
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
