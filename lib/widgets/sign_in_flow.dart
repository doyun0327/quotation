import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_theme.dart';

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: AppTheme.body.copyWith(color: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
    ),
  );
}

/// Sign in with a toast for the result. iPhone gets an Apple/Google chooser;
/// other platforms go straight to Google. Returns true when signed in.
Future<bool> showSignInFlow(BuildContext context) async {
  if (!AuthController.isAppleSignInAvailable) {
    return _signInWithGoogle(context);
  }
  final t = AppStrings.current;
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.loginMethodTitle,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(sheetContext).pop('apple'),
              icon: const Icon(Icons.apple, size: 22),
              label: Text(t.appleLoginTitle),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: AppTheme.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(sheetContext).pop('google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.ink, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: AppTheme.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(t.googleLoginTitle),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return false;
  return switch (choice) {
    'apple' => _signInWithApple(context),
    'google' => _signInWithGoogle(context),
    _ => false,
  };
}

/// Before a purchase, suggests signing in so the plan follows the account.
///
/// App Review 5.1.1 does not allow requiring an account to buy, so the user
/// can always continue without one. Returns false only when they back out.
Future<bool> suggestSignInBeforePurchase(BuildContext context) async {
  if (authController.isSignedIn) return true;
  final t = AppStrings.current;
  final choice = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(
        t.purchaseLoginTitle,
        style: AppTheme.body.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
      content: Text(
        t.purchaseLoginBody,
        style: AppTheme.body.copyWith(fontSize: 14, color: AppColors.ink),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop('skip'),
          child: Text(t.purchaseLoginSkip),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop('login'),
          child: Text(t.login),
        ),
      ],
    ),
  );
  if (!context.mounted) return false;
  return switch (choice) {
    'skip' => true,
    'login' => showSignInFlow(context),
    _ => false,
  };
}

Future<bool> _signInWithGoogle(BuildContext context) async {
  final t = AppStrings.current;
  final ok = await authController.signIn();
  if (!context.mounted) return ok;
  if (ok) {
    _toast(context, t.googleLoginSuccess);
    return true;
  }
  switch (authController.lastError) {
    case 'canceled':
      _toast(context, t.googleLoginCanceled);
    case 'canceled_or_config':
    case 'config':
    case 'clientConfigurationError':
      _toast(context, t.googleLoginConfigError);
    case 'missing_client_id':
      _toast(context, t.googleLoginConfigMissing);
    default:
      final detail = authController.lastErrorDetail;
      _toast(
        context,
        detail == null || detail.isEmpty
            ? t.googleLoginFailed
            : t.googleLoginFailedDetail(detail),
      );
  }
  return false;
}

Future<bool> _signInWithApple(BuildContext context) async {
  final t = AppStrings.current;
  final ok = await authController.signInWithApple();
  if (!context.mounted) return ok;
  if (ok) {
    _toast(context, t.appleLoginSuccess);
    return true;
  }
  switch (authController.lastError) {
    case 'canceled':
      _toast(context, t.googleLoginCanceled);
    case 'config':
      _toast(context, t.appleLoginConfigError);
    default:
      final detail = authController.lastErrorDetail;
      _toast(
        context,
        detail == null || detail.isEmpty
            ? t.appleLoginFailed
            : t.appleLoginFailedDetail(detail),
      );
  }
  return false;
}
