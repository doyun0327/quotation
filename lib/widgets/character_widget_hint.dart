import 'package:flutter/material.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotation/widgets/ios_widget_guide.dart';

/// Shown once so people know the home character can be a widget.
class CharacterWidgetHint {
  static const prefsKey = 'character_widget_hint_v2_dismissed';

  static Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) == true;
  }

  static Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  static void showClosedMessage(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.current.characterWidgetHintClosed,
          style: AppTheme.body.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
    );
  }

  /// Pins the character + speech-bubble widget. If the phone cannot open
  /// the add sheet, tell the user how to add it from the home screen.
  static Future<void> export(BuildContext context) async {
    var bubble = false;
    if (!IosWidgetGuide.isIOS) {
      final picked = await _pickStyle(context);
      if (picked == null || !context.mounted) return;
      bubble = picked;
    }
    final pinned = await HomeWidgetSync.pinCharacterWidget(bubble: bubble);
    if (!context.mounted || pinned) return;
    if (IosWidgetGuide.isIOS) {
      // iPhone has no add sheet for apps: show the step-by-step guide.
      await IosWidgetGuide.show(
        context,
        widgetName: IosWidgetGuide.characterWidgetName,
      );
      return;
    }
    showClosedMessage(context);
  }

  /// True for the speech-bubble style, false for the classic box, null when
  /// dismissed.
  static Future<bool?> _pickStyle(BuildContext context) {
    final t = AppStrings.current;
    final accent = context.palette.accent;
    Widget option(BuildContext sheet, String title, String note, bool value) {
      return ListTile(
        leading: Icon(
          value ? Icons.chat_bubble_outline_rounded : Icons.crop_square_rounded,
          color: accent,
        ),
        title: Text(
          title,
          style: AppTheme.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        subtitle: Text(
          note,
          style: AppTheme.body.copyWith(fontSize: 12, color: AppColors.muted),
        ),
        onTap: () => Navigator.of(sheet).pop(value),
      );
    }

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  t.characterWidgetStyleTitle,
                  style: AppTheme.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              option(
                sheet,
                t.characterWidgetStyleBubble,
                t.characterWidgetStyleBubbleNote,
                true,
              ),
              option(
                sheet,
                t.characterWidgetStyleClassic,
                t.characterWidgetStyleClassicNote,
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CharacterWidgetHintCard extends StatelessWidget {
  const CharacterWidgetHintCard({
    super.key,
    required this.onExport,
    required this.onClose,
  });

  final VoidCallback onExport;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final palette = context.palette;
    final t = AppStrings.current;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.widgets_outlined,
                size: 20,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.characterWidgetHint,
                    style: AppTheme.body.copyWith(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onExport,
                        style: TextButton.styleFrom(
                          foregroundColor: palette.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: AppTheme.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(t.characterWidgetHintExport),
                      ),
                      TextButton(
                        onPressed: onClose,
                        style: TextButton.styleFrom(
                          foregroundColor: palette.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: AppTheme.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(t.characterWidgetHintClose),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home-screen copy of the hint. Either button hides it for good.
class CharacterWidgetHintBanner extends StatefulWidget {
  const CharacterWidgetHintBanner({super.key});

  @override
  State<CharacterWidgetHintBanner> createState() =>
      _CharacterWidgetHintBannerState();
}

class _CharacterWidgetHintBannerState extends State<CharacterWidgetHintBanner> {
  bool _visible = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dismissed = await CharacterWidgetHint.isDismissed();
    if (!mounted || dismissed) return;
    setState(() => _visible = true);
  }

  Future<void> _finish() async {
    await CharacterWidgetHint.markDismissed();
    if (!mounted) return;
    setState(() => _visible = false);
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _finish();
    if (!mounted) return;
    await CharacterWidgetHint.export(context);
  }

  Future<void> _close() async {
    if (_busy) return;
    setState(() => _busy = true);
    CharacterWidgetHint.showClosedMessage(context);
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: CharacterWidgetHintCard(
        onExport: _export,
        onClose: _close,
      ),
    );
  }
}
