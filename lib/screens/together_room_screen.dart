import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/together_cheer_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/dday_invite_screen.dart';
import 'package:quotation/screens/dday_widget_decorate_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';
import 'package:quotation/widgets/together_widget_preview.dart';

class TogetherRoomScreen extends StatefulWidget {
  const TogetherRoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<TogetherRoomScreen> createState() => _TogetherRoomScreenState();
}

class _TogetherRoomScreenState extends State<TogetherRoomScreen> {
  final _cheerCtrl = TextEditingController();
  final _cheerFocus = FocusNode();
  bool _sending = false;
  bool _loggingIn = false;
  bool _editingCheer = false;

  @override
  void dispose() {
    _cheerCtrl.dispose();
    _cheerFocus.dispose();
    super.dispose();
  }

  DdayItem? get _room {
    final matches =
        ddayController.items.where((e) => e.id == widget.roomId);
    return matches.isEmpty ? null : matches.first;
  }

  void _startEditCheer(String? current) {
    _cheerCtrl.text = current?.trim() ?? '';
    setState(() => _editingCheer = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cheerFocus.requestFocus();
    });
  }

  void _cancelEditCheer() {
    setState(() => _editingCheer = false);
    _cheerFocus.unfocus();
  }

  Future<void> _saveCheer() async {
    if (_sending || _loggingIn) return;
    final t = AppStrings.current;
    final text = _cheerCtrl.text;
    if (text.trim().isEmpty) return;

    final needsLogin = !authController.isSignedIn ||
        authController.user?.firebaseLinked != true;

    if (needsLogin) {
      // Google sheet → then show "로그인 중" until session is ready.
      setState(() => _loggingIn = true);
      final ok = await authController.ensureFirebaseSession();
      if (!mounted) return;
      setState(() => _loggingIn = false);
      if (!ok) {
        final message = authController.lastError == 'canceled'
            ? t.googleLoginCanceled
            : t.togetherCheerNeedLogin;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
      // Login finished — continue once into save (same as pressing 저장).
    }

    setState(() => _sending = true);
    final result = await TogetherCheerRepository.save(
      roomId: widget.roomId,
      text: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.ok) {
      setState(() => _editingCheer = false);
      _cheerFocus.unfocus();
      return;
    }
    final message = switch (result.errorCode) {
      'not_signed_in' => t.togetherCheerNeedLogin,
      'permission' => t.togetherCheerPermission,
      _ => t.togetherCheerFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        visualStyleController,
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
                        onPressed: () {
                          if (_editingCheer) {
                            _cancelEditCheer();
                            return;
                          }
                          Navigator.of(context).maybePop();
                        },
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
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      _FriendsCard(
                        room: room,
                        onInvite: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DdayInviteScreen(item: room),
                            ),
                          );
                        },
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
                      const SizedBox(height: 12),
                      StreamBuilder<TogetherCheer?>(
                        stream: TogetherCheerRepository.watch(room.id),
                        builder: (context, snap) {
                          final cheer = snap.data;
                          final local = room.latestCheer?.trim();
                          final text = cheer?.text ??
                              ((local != null && local.isNotEmpty)
                                  ? local
                                  : null);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CheerCard(
                                text: text,
                                editing: _editingCheer,
                                sending: _sending,
                                loggingIn: _loggingIn,
                                controller: _cheerCtrl,
                                focusNode: _cheerFocus,
                                onTap: () => _startEditCheer(text),
                                onCancel: _cancelEditCheer,
                                onSave: _saveCheer,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                t.ddayDuoDecorateOpen,
                                style: AppTheme.body.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2C3340),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _RoomWidgetPreview(
                                room: room,
                                cheerText: text,
                                onOpenDecorate: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          DdayWidgetDecorateScreen(
                                        roomId: room.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
  const _FriendsCard({required this.room, required this.onInvite});

  final DdayItem room;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
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
              ),
              Material(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onInvite,
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.add_rounded,
                      color: palette.accent,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

class _RoomWidgetPreview extends StatelessWidget {
  const _RoomWidgetPreview({
    required this.room,
    required this.cheerText,
    required this.onOpenDecorate,
  });

  final DdayItem room;
  final String? cheerText;
  final VoidCallback onOpenDecorate;

  @override
  Widget build(BuildContext context) {
    final cheer = cheerText?.trim();
    final label = (cheer != null && cheer.isNotEmpty) ? cheer : '';
    final friendId = room.friendCharacterId;
    final meX = ddayController.meOffsetXForRoom(room.id).toDouble();
    final meY = ddayController.meOffsetYForRoom(room.id).toDouble();
    final friendX = ddayController.friendOffsetXForRoom(room.id).toDouble();
    final friendY = ddayController.friendOffsetYForRoom(room.id).toDouble();
    final textX = ddayController.textOffsetXForRoom(room.id).toDouble();
    final textY = ddayController.textOffsetYForRoom(room.id).toDouble();
    final widgetSize = ddayController.widgetSizeForRoom(room.id);
    final cellDp = TogetherWidgetSize.cellDpForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final previewSize = TogetherWidgetPreview.sizeForShape(
      TogetherWidgetShape.square,
      widgetSize,
      cellDp,
    );
    final charBase = widgetSize.charFactor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDecorate,
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Center(
            child: TogetherWidgetPreview(
              width: previewSize.width,
              height: previewSize.height,
              charW: 72 * charBase,
              charH: 96 * charBase,
              label: label,
              me: characterController.character,
              friend: room.hasFriend && friendId != null
                  ? AppCharacter.byId(friendId)
                  : null,
              meX: meX,
              meY: meY,
              friendX: friendX,
              friendY: friendY,
              textX: textX,
              textY: textY,
              isPixel: visualStyleController.isPixel,
              charScale: ddayController.charScaleForRoom(room.id),
              textScale: ddayController.textScaleForRoom(room.id),
              bgColor: ddayController.bgColorForRoom(room.id),
              bgOpacity: ddayController.bgOpacityForRoom(room.id),
              textColor: ddayController.textColorForRoom(room.id),
              shape: TogetherWidgetShape.square,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheerCard extends StatelessWidget {
  const _CheerCard({
    this.text,
    required this.editing,
    required this.sending,
    this.loggingIn = false,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onCancel,
    required this.onSave,
  });

  final String? text;
  final bool editing;
  final bool sending;
  final bool loggingIn;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;
    final hasText = text != null && text!.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: editing ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: editing
                  ? palette.accent.withValues(alpha: 0.45)
                  : const Color(0xFFE4ECF7),
            ),
          ),
          child: editing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLength: 80,
                      maxLines: 3,
                      minLines: 2,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onSave(),
                      style: AppTheme.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C3340),
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: t.togetherCheerPlaceholder,
                        hintStyle: AppTheme.body.copyWith(
                          fontSize: 15,
                          color: const Color(0xFFB0B8C6),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                (sending || loggingIn) ? null : onCancel,
                            child: Text(t.togetherCheerCancel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed:
                                (sending || loggingIn) ? null : onSave,
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.accent,
                            ),
                            child: loggingIn
                                ? Text(t.togetherCheerLoggingIn)
                                : sending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(t.togetherCheerSend),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(
                  hasText ? text!.trim() : t.togetherCheerEmpty,
                  style: AppTheme.body.copyWith(
                    fontSize: hasText ? 16 : 14,
                    fontWeight: hasText ? FontWeight.w700 : FontWeight.w600,
                    color: hasText ? const Color(0xFF2C3340) : AppColors.muted,
                    height: 1.35,
                  ),
                ),
        ),
      ),
    );
  }
}
