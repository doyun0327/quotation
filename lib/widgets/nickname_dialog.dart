import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/language_row.dart';

/// Asks for a friend-facing nickname.
/// When [requiredName] is true the dialog stays until a name is saved.
Future<void> showNicknameDialog(
  BuildContext context, {
  bool requiredName = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !requiredName,
    builder: (context) => _NicknameDialog(requiredName: requiredName),
  );
}

class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.requiredName});

  final bool requiredName;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: authController.nickname ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppStrings.current;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.nicknameRequired);
      return;
    }
    final ok = await authController.setNickname(name);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = t.nicknameRequired);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.requiredName,
      child: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) {
          final t = AppStrings.current;
          return AlertDialog(
            title: Text(
              t.nicknameTitle,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w900),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.nicknameHint,
                    style: AppTheme.body.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    autofocus: !widget.requiredName,
                    maxLength: 16,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: t.nicknameTitle,
                      errorText: _error.isEmpty ? null : _error,
                    ),
                  ),
                  if (widget.requiredName) ...[
                    const SizedBox(height: 8),
                    Text(
                      t.languageTitle,
                      style: AppTheme.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    LanguageRow(
                      selectedId: localeController.language.id,
                      onSelected: localeController.setLanguage,
                      nativeNames: true,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!widget.requiredName)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.togetherCheerCancel),
                ),
              FilledButton(
                onPressed: _save,
                child: Text(t.nicknameSave),
              ),
            ],
          );
        },
      ),
    );
  }
}
