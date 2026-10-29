import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// How to request account and related cloud data deletion.
class AccountDeletionScreen extends StatelessWidget {
  const AccountDeletionScreen({super.key});

  static const contactEmail = 'idoyun781@gmail.com';
  static const webUrl =
      'https://doyun0327.github.io/quotation/delete-account.html';

  Future<void> _deleteInApp(BuildContext context) async {
    final t = AppStrings.current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            t.accountDeleteTitle,
            style: AppTheme.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            t.accountDeleteConfirmBody,
            style: AppTheme.body.copyWith(fontSize: 14, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.accountDeleteNow),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await authController.deleteAccount();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? t.accountDeleteDone : t.accountDeleteFailed)),
    );
    if (ok) Navigator.of(context).maybePop();
  }

  Future<void> _sendMail(BuildContext context) async {
    final t = AppStrings.current;
    final uri = Uri(
      scheme: 'mailto',
      path: contactEmail,
      queryParameters: {
        'subject': 'Dearly account deletion request',
        'body': t.accountDeleteMailBody,
      },
    );
    final opened = await launchUrl(uri);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.accountDeleteMailFailed)),
      );
    }
  }

  Future<void> _openWeb(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(webUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current.accountDeleteMailFailed)),
      );
    }
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
                          t.accountDeleteTitle,
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
                        t.accountDeleteBody,
                        style: AppTheme.body.copyWith(
                          fontSize: 15,
                          height: 1.55,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          t.accountDeleteNow,
                          style: AppTheme.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () => _sendMail(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          t.accountDeleteMailCta,
                          style: AppTheme.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => _openWeb(context),
                        child: Text(
                          t.accountDeleteWebCta,
                          style: AppTheme.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        contactEmail,
                        style: AppTheme.body.copyWith(
                          fontSize: 13,
                          color: AppColors.muted,
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
