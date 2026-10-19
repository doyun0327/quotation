import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/together_cheer_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/dday_edit_screen.dart';
import 'package:quotation/screens/dday_invite_screen.dart';
import 'package:quotation/screens/dday_widget_decorate_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';

class TogetherRoomScreen extends StatefulWidget {
  const TogetherRoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<TogetherRoomScreen> createState() => _TogetherRoomScreenState();
}

class _TogetherRoomScreenState extends State<TogetherRoomScreen> {
  final _cheerCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _cheerCtrl.dispose();
    super.dispose();
  }

  DdayItem? get _room {
    final matches =
        ddayController.items.where((e) => e.id == widget.roomId);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _sendCheer() async {
    final t = AppStrings.current;
    if (!authController.isSignedIn ||
        authController.user?.firebaseLinked != true) {
      final ok = await authController.ensureFirebaseSession();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.togetherCheerNeedLogin)),
        );
        return;
      }
    }
    final text = _cheerCtrl.text;
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    final ok = await TogetherCheerRepository.post(
      roomId: widget.roomId,
      text: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _cheerCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.togetherCheerFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListenableBuilder(
      listenable: Listenable.merge([
        ddayController,
        localeController,
        authController,
        characterController,
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final room = _room;
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t.ddayTitle)),
            body: Center(child: Text(t.ddayEmptyTitle)),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          size: 32,
                          color: palette.accent,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DdayPixelIcon(kind: room.iconKind, size: 28),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: palette.accent,
                              ),
                            ),
                            Text(
                              t.togetherFriendCountLabel(room.friendCount),
                              style: AppTheme.body.copyWith(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DdayEditScreen(existing: room),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                          color: palette.accent,
                        ),
                        tooltip: t.ddayEdit,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      _FriendsCard(room: room),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionChipButton(
                              icon: Icons.widgets_outlined,
                              label: t.ddayDuoDecorateOpen,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const DdayWidgetDecorateScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionChipButton(
                              icon: Icons.person_add_alt_1_rounded,
                              label: t.ddayInviteTitle,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        DdayInviteScreen(item: room),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        t.togetherCheerTitle,
                        style: AppTheme.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C3340),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.togetherCheerHint,
                        style: AppTheme.body.copyWith(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<TogetherCheer>>(
                        stream: TogetherCheerRepository.watch(room.id),
                        builder: (context, snap) {
                          final cheers = snap.data ?? const <TogetherCheer>[];
                          if (cheers.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE4ECF7),
                                ),
                              ),
                              child: Text(
                                t.togetherCheerEmpty,
                                style: AppTheme.body.copyWith(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final cheer in cheers) ...[
                                _CheerTile(cheer: cheer),
                                const SizedBox(height: 8),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.black12,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cheerCtrl,
                              maxLength: 80,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendCheer(),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: t.togetherCheerPlaceholder,
                                filled: true,
                                fillColor: const Color(0xFFF7F9FC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _sending ? null : _sendCheer,
                            child: Text(t.togetherCheerSend),
                          ),
                        ],
                      ),
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

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({required this.room});

  final DdayItem room;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final me = characterController.character;
    final friends = room.friends;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.togetherFriendsLabel,
            style: AppTheme.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2C3340),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _CharBubble(asset: me.assetPath, label: _koMe(t)),
              for (final f in friends)
                _CharBubble(
                  asset: AppCharacter.byId(f.characterId).assetPath,
                  label: _friendLabel(f),
                ),
            ],
          ),
          if (friends.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              t.togetherSoloFriends,
              style: AppTheme.body.copyWith(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _koMe(AppStrings t) => localeController.isKorean ? '나' : 'Me';

  String _friendLabel(DdayFriendMember f) {
    final name = f.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return localeController.isKorean ? '친구' : 'Friend';
  }
}

class _CharBubble extends StatelessWidget {
  const _CharBubble({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(asset, width: 52, height: 52, fit: BoxFit.cover),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C3340),
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

class _CheerTile extends StatelessWidget {
  const _CheerTile({required this.cheer});

  final TogetherCheer cheer;

  @override
  Widget build(BuildContext context) {
    final name = cheer.authorName?.trim();
    final who = (name != null && name.isNotEmpty)
        ? name
        : (localeController.isKorean ? '친구' : 'Friend');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            who,
            style: AppTheme.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.palette.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cheer.text,
            style: AppTheme.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3340),
            ),
          ),
        ],
      ),
    );
  }
}
