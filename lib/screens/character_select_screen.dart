import 'package:flutter/material.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/character_widget_hint.dart';

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
  bool _hintVisible = true;
  bool _hintBusy = false;
  CharacterGroup _group = CharacterGroup.female;

  List<AppCharacter> get _choices {
    final pool = AppCharacter.inGroup(_group);
    final owned = [
      for (final character in pool)
        if (characterController.isUsable(character)) character,
    ];
    owned.sort((a, b) {
      final fav = (characterController.isFavorite(a) ? 0 : 1) -
          (characterController.isFavorite(b) ? 0 : 1);
      if (fav != 0) return fav;
      return pool.indexOf(a).compareTo(pool.indexOf(b));
    });
    return owned;
  }

  @override
  void initState() {
    super.initState();
    _selected = characterController.character;
  }

  Future<void> _hideHint() async {
    await CharacterWidgetHint.markDismissed();
    if (!mounted) return;
    setState(() => _hintVisible = false);
  }

  Future<void> _exportHint() async {
    if (_hintBusy) return;
    setState(() => _hintBusy = true);
    await characterController.select(_selected);
    await _hideHint();
    if (!mounted) return;
    await CharacterWidgetHint.export(context);
  }

  Future<void> _closeHint() async {
    if (_hintBusy) return;
    setState(() => _hintBusy = true);
    CharacterWidgetHint.showClosedMessage(context);
    await _hideHint();
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
      listenable: Listenable.merge([
        localeController,
        membershipController,
        characterController,
      ]),
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
                  if (!widget.allowSkip && _hintVisible) ...[
                    const SizedBox(height: 16),
                    CharacterWidgetHintCard(
                      onExport: _exportHint,
                      onClose: _closeHint,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GroupTab(
                        label: t.shopGroupFemale,
                        selected: _group == CharacterGroup.female,
                        accent: palette.accent,
                        onTap: () =>
                            setState(() => _group = CharacterGroup.female),
                      ),
                      const SizedBox(width: 8),
                      _GroupTab(
                        label: t.shopGroupMale,
                        selected: _group == CharacterGroup.male,
                        accent: palette.accent,
                        onTap: () =>
                            setState(() => _group = CharacterGroup.male),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _choices.isEmpty
                        ? Center(
                            child: Text(
                              t.shopMaleEmpty,
                              style: AppTheme.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                              ),
                            ),
                          )
                        : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: _choices.length,
                      itemBuilder: (context, index) {
                        final character = _choices[index];
                        return _CharacterOption(
                          character: character,
                          selected: _selected.id == character.id,
                          label: t.characterName(character.id),
                          onTap: () => setState(() => _selected = character),
                        );
                      },
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

class _GroupTab extends StatelessWidget {
  const _GroupTab({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : Colors.white,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Text(
            label,
            style: AppTheme.body.copyWith(
              color: selected ? Colors.white : accent,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
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
                  filterQuality: FilterQuality.none,
                  isAntiAlias: false,
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
