import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/dday_invite_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';

class DdayEditScreen extends StatefulWidget {
  const DdayEditScreen({super.key, this.existing});

  final DdayItem? existing;

  @override
  State<DdayEditScreen> createState() => _DdayEditScreenState();
}

class _DdayEditScreenState extends State<DdayEditScreen> {
  late final TextEditingController _titleCtrl;
  late DateTime _date;
  late bool _repeatYearly;
  late DdayIconKind _icon;

  static const _bg = Color(0xFFF3F7FD);
  static const _labelBlue = Color(0xFF4A7FD4);
  static const _cardBorder = Color(0xFFE4ECF7);
  static const _pink = Color(0xFFFF8FB5);
  static const _sky = Color(0xFF7EB6FF);
  static const _yellow = Color(0xFFFFD56A);
  static const _mint = Color(0xFF7DCFB6);
  static const _btnBlue = Color(0xFF5B8DEF);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _date = existing?.targetDate ?? DateTime.now();
    _repeatYearly = existing?.repeatYearly ?? true;
    _icon = existing?.iconKind ?? DdayIconKind.cake;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final locale = localeController.language.id;
    if (localeController.isKorean) {
      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final w = weekdays[date.weekday - 1];
      return '${date.year}. ${date.month.toString().padLeft(2, '0')}. '
          '${date.day.toString().padLeft(2, '0')} ($w)';
    }
    return DateFormat.yMMMEd(locale).format(date);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _btnBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current.ddayTitleRequired)),
      );
      return;
    }

    final existing = widget.existing;
    if (existing == null) {
      await ddayController.add(
        title: title,
        targetDate: _date,
        iconId: _icon.id,
        repeatYearly: _repeatYearly,
      );
    } else {
      await ddayController.update(
        existing.copyWith(
          title: title,
          targetDate: DateTime(_date.year, _date.month, _date.day),
          iconId: _icon.id,
          repeatYearly: _repeatYearly,
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final isEdit = widget.existing != null;
    final accent = context.palette.accent;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          size: 32,
                          color: accent,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              isEdit ? t.ddayEdit : t.ddayAdd,
                              style: AppTheme.body.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.ddayAddSubtitle,
                              style: AppTheme.body.copyWith(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    children: [
                      _SectionCard(
                        iconColor: _mint,
                        label: t.ddayPickIcon,
                        labelColor: _labelBlue,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: DdayIconKind.all.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.92,
                          ),
                          itemBuilder: (context, index) {
                            final kind = DdayIconKind.all[index];
                            final selected = _icon == kind;
                            return Material(
                              color: selected
                                  ? const Color(0xFFEFF5FF)
                                  : const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => setState(() => _icon = kind),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? accent : _cardBorder,
                                      width: selected ? 1.6 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      DdayPixelIcon(kind: kind, size: 30),
                                      const SizedBox(height: 4),
                                      Text(
                                        kind.labelKo(),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.body.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: selected
                                              ? accent
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        iconColor: _pink,
                        label: t.ddayWhatDay,
                        labelColor: _labelBlue,
                        child: TextField(
                          controller: _titleCtrl,
                          textInputAction: TextInputAction.done,
                          style: AppTheme.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: t.ddayTitlePlaceholder,
                            hintStyle: AppTheme.body.copyWith(
                              fontSize: 14,
                              color: const Color(0xFFB0B8C6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: accent, width: 1.4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        iconColor: _sky,
                        label: t.ddayPickDate,
                        labelColor: _labelBlue,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    color: accent,
                                    size: 22,
                                  ),
                                  Expanded(
                                    child: Text(
                                      _formatDate(_date),
                                      textAlign: TextAlign.center,
                                      style: AppTheme.body.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2C3340),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: accent.withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        iconColor: _yellow,
                        label: t.ddayRepeat,
                        labelColor: _labelBlue,
                        child: Row(
                          children: [
                            Expanded(
                              child: _RepeatChip(
                                selected: !_repeatYearly,
                                label: t.ddayRepeatNone,
                                onTap: () =>
                                    setState(() => _repeatYearly = false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _RepeatChip(
                                selected: _repeatYearly,
                                label: t.ddayRepeatYearly,
                                onTap: () =>
                                    setState(() => _repeatYearly = true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.existing != null) ...[
                        const SizedBox(height: 14),
                        _SectionCard(
                          iconColor: _pink,
                          label: t.ddayInviteTitle,
                          labelColor: _labelBlue,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t.ddayInviteSubtitle(
                                  DdayInviteLimits.maxFriends,
                                ),
                                style: AppTheme.body.copyWith(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.ddayInviteFriendCount(
                                  widget.existing!.friendCount,
                                  DdayInviteLimits.maxFriends,
                                ),
                                style: AppTheme.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _btnBlue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => DdayInviteScreen(
                                        item: widget.existing!,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1_rounded),
                                label: Text(t.ddayInviteOpen),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _btnBlue,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        textStyle: AppTheme.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(t.ddaySave),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.child,
  });

  final Color iconColor;
  final String label;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RepeatChip extends StatelessWidget {
  const _RepeatChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFF8FB4F0) : const Color(0xFFE0E6EF);
    final bg = selected ? const Color(0xFFEFF5FF) : Colors.white;
    final fg = selected ? const Color(0xFF4A7FD4) : AppColors.muted;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
