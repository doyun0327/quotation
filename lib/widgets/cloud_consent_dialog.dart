import 'package:flutter/material.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_theme.dart';

/// Prominent disclosure before any account id or email is sent to Firebase.
Future<bool> showCloudConsentDialog(BuildContext context) async {
  final t = AppStrings.current;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(
          t.cloudConsentTitle,
          style: AppTheme.body.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          t.cloudConsentBody,
          style: AppTheme.body.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cloudConsentDecline),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.cloudConsentAccept),
          ),
        ],
      );
    },
  );
  return result == true;
}
