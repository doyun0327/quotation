import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quotation/data/billing_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
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
        final fine = AppTheme.body.copyWith(
          fontSize: 11,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price first, then what it buys as short chips.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                      fontSize: price == null ? 13 : 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BenefitGrid(
                    benefits: t.subscriptionBenefits,
                    // Short Korean labels sit two to a row; the longer
                    // English and Japanese ones get a line each.
                    perRow: localeController.isKorean ? 2 : 1,
                    color: palette.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Billing period, auto-renewal, how to cancel, what is not
            // included: the store policy terms, kept to one quiet line.
            Text(t.subscriptionFinePrint(_store), style: fine),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LegalScreen()),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.muted,
                textStyle: AppTheme.body.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: Text(t.termsTitle),
            ),
          ],
        );
      },
    );
  }
}

class _BenefitGrid extends StatelessWidget {
  const _BenefitGrid({
    required this.benefits,
    required this.perRow,
    required this.color,
  });

  final List<String> benefits;
  final int perRow;
  final Color color;

  Widget _chip(String label) {
    final style = AppTheme.body.copyWith(
      fontSize: perRow > 1 ? 10.5 : 11,
      height: 1.25,
      fontWeight: FontWeight.w800,
      color: color,
    );
    // Two to a row is narrow on a phone dialog: the label wraps onto a second
    // line at the same size rather than shrinking out of reading range. One
    // per line has room, so it stays on one line.
    final text = perRow > 1
        ? Text(label, maxLines: 2, style: style)
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, maxLines: 1, style: style),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(perRow > 1 ? 10 : 20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: perRow > 1 ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(child: text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      for (var i = 0; i < benefits.length; i += perRow)
        benefits.sublist(i, (i + perRow).clamp(0, benefits.length)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 5),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < perRow; c++) ...[
                  if (c > 0) const SizedBox(width: 5),
                  Expanded(
                    child: c >= rows[r].length
                        ? const SizedBox.shrink()
                        : perRow > 1
                            ? _chip(rows[r][c])
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: _chip(rows[r][c]),
                              ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
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
