import 'package:flutter/material.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/dday_accept_invite_screen.dart';
import 'package:quotation/screens/dday_edit_screen.dart';
import 'package:quotation/screens/dday_widget_decorate_screen.dart';
import 'package:quotation/screens/together_room_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/dashed_border.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';

class DdayScreen extends StatefulWidget {
  const DdayScreen({super.key});

  @override
  State<DdayScreen> createState() => _DdayScreenState();
}

class _DdayScreenState extends State<DdayScreen> {
  @override
  void initState() {
    super.initState();
    ddayController.addListener(_onDdayChanged);
  }

  @override
  void dispose() {
    ddayController.removeListener(_onDdayChanged);
    super.dispose();
  }

  void _onDdayChanged() {
    HomeWidgetSync.syncDday();
  }

  Future<void> _openEditor({DdayItem? existing}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DdayEditScreen(existing: existing),
      ),
    );
  }

  Future<void> _openRoom(DdayItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TogetherRoomScreen(roomId: item.id),
      ),
    );
  }

  Future<void> _onMenuSelected(String action, DdayItem item) async {
    switch (action) {
      case 'open':
        await _openRoom(item);
      case 'edit':
        await _openEditor(existing: item);
      case 'pin':
        await ddayController.pinForWidget(item.id);
      case 'delete':
        await ddayController.remove(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ColoredBox(
      color: const Color(0xFFF7F9FC),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            ddayController,
            localeController,
            characterController,
          ]),
          builder: (context, _) {
            final t = AppStrings.current;
            final items = ddayController.items;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
                  child: Row(
                    children: [
                      Icon(Icons.groups_rounded, color: palette.accent),
                      const SizedBox(width: 8),
                      Text(
                        t.ddayTitle,
                        style: AppTheme.body.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: palette.accent,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const DdayAcceptInviteScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.qr_code_rounded,
                          size: 24,
                          color: palette.accent,
                        ),
                        tooltip: t.ddayInviteEnterCodeMenu,
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const DdayWidgetDecorateScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.widgets_outlined,
                          size: 24,
                          color: palette.accent,
                        ),
                        tooltip: t.ddayDuoDecorateOpen,
                      ),
                      IconButton(
                        onPressed: () => _openEditor(),
                        icon: Icon(
                          Icons.add_rounded,
                          size: 28,
                          color: palette.accent,
                        ),
                        tooltip: t.ddayAdd,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    t.ddayHint,
                    style: AppTheme.body.copyWith(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const DdayWidgetDecorateScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: palette.accent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.widgets_outlined,
                              color: palette.accent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.ddayDuoDecorateOpen,
                                    style: AppTheme.body.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2C3340),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.ddayDuoDecorateMenuHint,
                                    style: AppTheme.body.copyWith(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: palette.accent.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 42,
                                color: palette.accent.withValues(alpha: 0.55),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t.ddayEmptyTitle,
                                style: AppTheme.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.ddayEmptyHint,
                                textAlign: TextAlign.center,
                                style: AppTheme.body.copyWith(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: () => _openEditor(),
                                icon: const Icon(Icons.add_rounded),
                                label: Text(t.ddayAdd),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final colors = _cardColors(item.iconKind, index);
                            return _TogetherRoomCard(
                              item: item,
                              background: colors.$1,
                              border: colors.$2,
                              accent: colors.$3,
                              onOpen: () => _openRoom(item),
                              onMenuSelected: (action) =>
                                  _onMenuSelected(action, item),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

(Color, Color, Color) _cardColors(DdayIconKind kind, int index) {
  return switch (kind) {
    DdayIconKind.cake || DdayIconKind.heart || DdayIconKind.baby => (
        const Color(0xFFFFF5F8),
        const Color(0xFFF5B8C8),
        const Color(0xFFE85A7A),
      ),
    DdayIconKind.plane || DdayIconKind.star || DdayIconKind.pen => (
        const Color(0xFFF3F8FF),
        const Color(0xFFA8C8F0),
        const Color(0xFF4A8FE8),
      ),
    DdayIconKind.tree || DdayIconKind.sport || DdayIconKind.cat => (
        const Color(0xFFF6FFF4),
        const Color(0xFFB5E0B0),
        const Color(0xFF4CAF70),
      ),
    DdayIconKind.dog ||
    DdayIconKind.notebook ||
    DdayIconKind.medal ||
    DdayIconKind.home ||
    DdayIconKind.wine =>
      (
        const Color(0xFFFFF9F0),
        const Color(0xFFF0D0A0),
        const Color(0xFFE09A3E),
      ),
  };
}

class _TogetherRoomCard extends StatelessWidget {
  const _TogetherRoomCard({
    required this.item,
    required this.background,
    required this.border,
    required this.accent,
    required this.onOpen,
    required this.onMenuSelected,
  });

  final DdayItem item;
  final Color background;
  final Color border;
  final Color accent;
  final VoidCallback onOpen;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final cheer = item.latestCheer?.trim();

    return DashedBorder(
      color: border,
      strokeWidth: 1.5,
      dashLength: 5,
      gapLength: 3,
      radius: 18,
      padding: EdgeInsets.zero,
      backgroundColor: background,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DdayPixelIcon(kind: item.iconKind, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2C3340),
                              ),
                            ),
                          ),
                          if (item.hasFriend) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.ddayDuoBadge,
                                style: AppTheme.body.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.hasFriend
                            ? t.togetherFriendCountLabel(item.friendCount)
                            : t.togetherSoloFriends,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body.copyWith(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      if (cheer != null && cheer.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          cheer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: onMenuSelected,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF9AA3B2),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'open',
                      child: Text(t.togetherOpenRoom),
                    ),
                    PopupMenuItem(value: 'edit', child: Text(t.ddayEdit)),
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(
                        item.pinnedForWidget
                            ? t.ddayPinnedWidget
                            : t.ddayPinWidget,
                      ),
                    ),
                    PopupMenuItem(value: 'delete', child: Text(t.delete)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
