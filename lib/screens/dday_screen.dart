import 'package:flutter/material.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/dday_accept_invite_screen.dart';
import 'package:quotation/screens/dday_edit_screen.dart';
import 'package:quotation/screens/together_room_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/app_pixel_icon.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';
import 'package:quotation/widgets/hamfoot_icon.dart';

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

  Future<void> _openEditor() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DdayEditScreen()),
    );
  }

  Future<void> _openRoom(DdayItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TogetherRoomScreen(roomId: item.id),
      ),
    );
  }

  Future<void> _confirmDelete(DdayItem item) async {
    final t = AppStrings.current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.delete),
          content: Text(t.deleteRoomConfirm(item.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.delete),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await ddayController.remove(item.id);
      await HomeWidgetSync.syncDday();
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
            blockedUsersController,
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
                      Icon(
                        Icons.groups_rounded,
                        size: 26,
                        color: palette.accent,
                      ),
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
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: palette.accent,
                          overlayColor: palette.accent.withValues(alpha: 0.08),
                        ),
                        icon: AppPixelIcon(
                          AppGlyph.qr,
                          size: 22,
                          color: palette.accent,
                        ),
                        tooltip: t.ddayInviteEnterCodeMenu,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Text(
                    t.ddayHint,
                    style: AppTheme.body.copyWith(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 40,
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
                                  onPressed: _openEditor,
                                  icon: AppPixelIcon(
                                    AppGlyph.add,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(t.ddayAdd),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: palette.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: items.length + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return OutlinedButton.icon(
                                onPressed: _openEditor,
                                icon: AppPixelIcon(
                                  AppGlyph.add,
                                  size: 16,
                                  color: palette.accent,
                                ),
                                label: Text(t.ddayAdd),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.accent,
                                  side: BorderSide(
                                    color:
                                        palette.accent.withValues(alpha: 0.35),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              );
                            }
                            final item = items[index];
                            return _TogetherRoomCard(
                              item: item,
                              onOpen: () => _openRoom(item),
                              onDelete: () => _confirmDelete(item),
                              onToggleFavorite: () =>
                                  ddayController.toggleFavorite(item.id),
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

class _TogetherRoomCard extends StatelessWidget {
  const _TogetherRoomCard({
    required this.item,
    required this.onOpen,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final DdayItem item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;
    final cheer = blockedUsersController.visibleCheer(
      item.id,
      item.latestCheer,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4ECF7)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DdayPixelIcon(kind: item.iconKind, size: 26),
              ),
              const SizedBox(width: 10),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2C3340),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (cheer.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        cheer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onToggleFavorite,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: HamfootIcon(
                      size: 22,
                      active: item.favorite,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: t.ddayLeaveRoom,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 22,
                      color: Color(0xFFB7C0CE),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
