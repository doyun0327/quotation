import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quotation/data/billing_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/screens/legal_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// What the monthly plan costs and how it renews, shown in every subscribe
/// prompt before the store sheet opens (Google Play and App Store both ask
/// for price, billing period and auto-renewal up front).
class SubscriptionTerms extends StatefulWidget {
  const SubscriptionTerms({super.key});

  @override
  State<SubscriptionTerms> createState() => _SubscriptionTermsState();
}

class _SubscriptionTermsState extends State<SubscriptionTerms> {
  @override
  void initState() {
    super.initState();
    billingController.loadMonthlyPrice();
  }

  static String get _store =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: billingController,
      builder: (context, _) {
        final t = AppStrings.current;
        final price = billingController.monthlyPrice;
        final small = AppTheme.body.copyWith(
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        );
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.accent.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price == null
                    ? t.subscriptionPriceUnknown
                    : t.subscriptionPriceLine(price),
                style: AppTheme.body.copyWith(
                  fontSize: price == null ? 12.5 : 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(t.subscriptionRenewNotice(_store), style: small),
              const SizedBox(height: 2),
              Text(t.subscriptionTrialNote, style: small),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const LegalScreen()),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: palette.accent,
                    textStyle: AppTheme.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(t.termsTitle),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// [message] above the plan terms, for a subscribe prompt's dialog content.
class SubscriptionPromptBody extends StatelessWidget {
  const SubscriptionPromptBody({
    super.key,
    required this.message,
    this.style,
  });

  final String message;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: style),
          const SizedBox(height: 12),
          const SubscriptionTerms(),
        ],
      ),
    );
  }
}

/// Settings' subscribe button used to open the store sheet directly. It now
/// shows the plan terms first; true when the person chose to subscribe.
Future<bool> confirmSubscription(BuildContext context) async {
  final t = AppStrings.current;
  final palette = context.palette;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        t.premiumTitle,
        style: AppTheme.body.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
      content: SubscriptionPromptBody(
        message: t.premiumSubtitle,
        style: AppTheme.body.copyWith(
          fontSize: 13.5,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            t.premiumLockedDismiss,
            style: AppTheme.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            t.premiumLockedCta,
            style: AppTheme.body.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.accent,
            ),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}
