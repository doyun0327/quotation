import 'package:flutter/material.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({
    super.key,
    this.onFinished,
    this.allowSkip = false,
  });

  /// Called after a character is confirmed (e.g. first-launch → home).
  final VoidCallback? onFinished;

  /// When true (settings), shows a back/close affordance.
  final bool allowSkip;

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  late AppCharacter _selected;

  @override
  void initState() {
    super.initState();
    _selected = characterController.character;
  }

  Future<void> _confirm() async {
    await characterController.select(_selected);
    await HomeWidgetSync.syncCharacter();
    if (!mounted) return;
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).maybePop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final t = AppStrings.current;
        return Scaffold(
          backgroundColor: const Color(0xFFF3F7FD),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.allowSkip)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.chevron_left_rounded, size: 30),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  Text(
                    t.characterSelectTitle,
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.characterSelectSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: Row(
                      children: [
                        for (final character in AppCharacter.values) ...[
                          Expanded(
                            child: _CharacterOption(
                              character: character,
                              selected: _selected == character,
                              label: t.characterName(character.id),
                              onTap: () =>
                                  setState(() => _selected = character),
                            ),
                          ),
                          if (character != AppCharacter.values.last)
                            const SizedBox(width: 14),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        shape: const StadiumBorder(),
                        textStyle: AppTheme.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(t.characterSelectConfirm),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CharacterOption extends StatelessWidget {
  const _CharacterOption({
    required this.character,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final AppCharacter character;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? palette.accent : const Color(0xFFE4ECF7),
              width: selected ? 2.2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  character.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: visualStyleController.isClean
                      ? FilterQuality.medium
                      : FilterQuality.none,
                  isAntiAlias: visualStyleController.isClean,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTheme.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? palette.accent : AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 20,
                color: selected ? palette.accent : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
