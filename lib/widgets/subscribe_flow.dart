import 'package:flutter/material.dart';
import 'package:quotation/data/billing_controller.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// Buys the monthly plan and keeps the person informed while the store and
/// RevenueCat confirm it. True when premium is on at the end.
///
/// A "please wait" overlay covers the screen (and blocks a second tap) until
/// the purchase settles. A slow confirmation is shown as "paid, opening
/// soon", never as a failure, and a short notice follows when it lands.
Future<bool> runMonthlySubscription(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.maybeOf(context);
  var overlayOpen = true;
  // The store sheet opens on top of this; it shows once the sheet closes.
  showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: _ProcessingDialog()),
  ).whenComplete(() => overlayOpen = false);

  final result = await billingController.subscribeMonthly();
  if (overlayOpen && navigator.mounted) navigator.pop();
  if (!navigator.mounted) return membershipController.isPremium;
  final t = AppStrings.current;

  switch (result.outcome) {
    case SubscribeOutcome.done:
      await _showUnlocked(navigator.context);
      return true;
    case SubscribeOutcome.verifying:
      _notifyWhenPremium(navigator);
      await _showInfo(navigator.context, t.subscribeLaterTitle, t.subscribeLaterBody);
      return false;
    case SubscribeOutcome.pending:
      _notifyWhenPremium(navigator);
      await _showInfo(navigator.context, t.subscribePendingTitle, t.subscribePendingBody);
      return false;
    case SubscribeOutcome.canceled:
      return false;
    case SubscribeOutcome.failed:
      messenger?.showSnackBar(
        SnackBar(content: Text(t.billingError(result.code ?? 'failed'))),
      );
      return false;
  }
}

/// Shows the unlocked dialog once RevenueCat turns premium on later.
void _notifyWhenPremium(NavigatorState navigator) {
  late final VoidCallback listener;
  listener = () {
    if (!membershipController.isPremium) return;
    membershipController.removeListener(listener);
    if (navigator.mounted) _showUnlocked(navigator.context);
  };
  membershipController.addListener(listener);
}

class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    return Dialog(
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: context.palette.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.subscribeProcessing,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.subscribeProcessingNote,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showUnlocked(BuildContext context) {
  final t = AppStrings.current;
  return _showInfo(context, t.subscribeDoneTitle, t.subscribeDoneBody);
}

Future<void> _showInfo(BuildContext context, String title, String body) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        title,
        style: AppTheme.body.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
      content: Text(
        body,
        style: AppTheme.body.copyWith(
          fontSize: 13.5,
          height: 1.45,
          color: AppColors.muted,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            AppStrings.current.trialWelcomeConfirm,
            style: AppTheme.body.copyWith(
              fontWeight: FontWeight.w900,
              color: dialogContext.palette.accent,
            ),
          ),
        ),
      ],
    ),
  );
}
