import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_theme.dart';

/// Asks for a friend-facing nickname.
/// When [requiredName] is true the dialog stays until a name is saved.
Future<void> showNicknameDialog(
  BuildContext context, {
  bool requiredName = false,
}) async {
  final t = AppStrings.current;
  final controller = TextEditingController(text: authController.nickname ?? '');
  var error = '';
  await showDialog<void>(
    context: context,
    barrierDismissible: !requiredName,
    builder: (context) {
      return PopScope(
        canPop: !requiredName,
        child: StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> save() async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                setLocal(() => error = t.nicknameRequired);
                return;
              }
              final ok = await authController.setNickname(name);
              if (!context.mounted) return;
              if (!ok) {
                setLocal(() => error = t.nicknameRequired);
                return;
              }
              Navigator.of(context).pop();
            }

            return AlertDialog(
              title: Text(
                t.nicknameTitle,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.nicknameHint,
                    style: AppTheme.body.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 16,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => save(),
                    decoration: InputDecoration(
                      hintText: t.nicknameTitle,
                      errorText: error.isEmpty ? null : error,
                    ),
                  ),
                ],
              ),
              actions: [
                if (!requiredName)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.togetherCheerCancel),
                  ),
                FilledButton(
                  onPressed: save,
                  child: Text(t.nicknameSave),
                ),
              ],
            );
          },
        ),
      );
    },
  );
  controller.dispose();
}
