import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/together_crowd_layout.dart';
import 'package:quotation/data/together_editing.dart';
import 'package:quotation/data/together_guide.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/widget_album_background.dart';
import 'package:quotation/data/together_cheer_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/dday_invite_screen.dart';
import 'package:quotation/screens/safety_report_sheet.dart';
import 'package:quotation/screens/dday_widget_decorate_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/app_pixel_icon.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';
import 'package:quotation/widgets/editing_spinner_overlay.dart';
import 'package:quotation/widgets/together_widget_preview.dart';

class TogetherRoomScreen extends StatefulWidget {
  const TogetherRoomScreen({super.key, required this.roomId});

  final String roomId;

  /// Route name so a widget/notification tap can find an already-open room
  /// instead of stacking another copy on top.
  static String routeNameFor(String roomId) => '/together_room/$roomId';

  static Route<void> route(String roomId) => MaterialPageRoute<void>(
        settings: RouteSettings(name: routeNameFor(roomId)),
        builder: (_) => TogetherRoomScreen(roomId: roomId),
      );

  @override
  State<TogetherRoomScreen> createState() => _TogetherRoomScreenState();
}

class _TogetherRoomScreenState extends State<TogetherRoomScreen> {
  Set<String> _invited = {};
  Set<String> _decorated = {};

  DdayItem? get _room {
    final matches =
        ddayController.items.where((e) => e.id == widget.roomId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  void initState() {
    super.initState();
    _loadGuide();
  }

  Future<void> _loadGuide() async {
    final invited = await TogetherGuide.invitedRooms();
    final decorated = await TogetherGuide.decoratedRooms();
    if (!mounted) return;
    setState(() {
      _invited = invited;
      _decorated = decorated;
    });
  }

  Future<void> _openInvite(DdayItem room) async {
    final invitedRoom = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => DdayInviteScreen(item: room),
      ),
    );
    if (invitedRoom != null) {
      await TogetherGuide.markInvited(invitedRoom);
    }
    await _loadGuide();
  }

  Future<void> _openDecorate(String roomId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DdayWidgetDecorateScreen(roomId: roomId),
      ),
    );
    await _loadGuide();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListenableBuilder(
      listenable: Listenable.merge([
        ddayController,
        localeController,
        characterController,
        blockedUsersController,
        authController,
        togetherEditing,
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
                        icon: AppPixelIcon(
                          AppGlyph.chevronLeft,
                          size: 20,
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
                        child: Text(
                          room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      if (room.hasFriend)
                        IconButton(
                          tooltip: t.safetyReport,
                          onPressed: () => showSafetyReportSheet(
                            context: context,
                            room: room,
                          ),
                          icon: Icon(
                            Icons.flag_outlined,
                            color: palette.accent,
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
                        showInviteNudge: TogetherCrowdLayout.withoutMe(
                              room.friends,
                              myIds: authController.myIds,
                              myName: authController.nickname?.trim() ?? '',
                              myCharacterId: ddayController
                                  .meCharacterIdForRoom(room.id),
                            ).isEmpty &&
                            !_invited.contains(room.id),
                        onInvite: () => _openInvite(room),
                      ),
                      const SizedBox(height: 18),
                      if (_invited.contains(room.id) &&
                          !_decorated.contains(room.id))
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: _NudgeBubble(
                            textKey: _NudgeKind.decorate,
                            tail: _NudgeTail.down,
                            alignEnd: false,
                          ),
                        ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openDecorate(room.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.ddayDuoDecorateOpen,
                                    style: AppTheme.body.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2C3340),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF2C3340),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<TogetherCheer?>(
                        stream: TogetherCheerRepository.watch(room.id),
                        builder: (context, snap) {
                          final cheer = snap.data;
                          final local = room.latestCheer?.trim();
                          // Typed text wins immediately. Cloud fills in only when
                          // nothing has been saved on this device yet.
                          final raw = (local != null && local.isNotEmpty)
                              ? local
                              : cheer?.text;
                          final text = blockedUsersController.visibleCheer(
                            room.id,
                            raw,
                            authorUid: cheer?.authorUid,
                          );
                          return _RoomWidgetPreview(
                            room: room,
                            cheerText: text,
                            onOpenDecorate: () => _openDecorate(room.id),
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
  const _FriendsCard({
    required this.room,
    required this.onInvite,
    required this.showInviteNudge,
  });

  final DdayItem room;
  final VoidCallback onInvite;
  final bool showInviteNudge;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;
    // My character in this room (main-screen pick is only the default).
    final me = ddayController.meCharacterForRoom(room.id);
    final friends = TogetherCrowdLayout.withoutMe(
      room.friends,
      myIds: authController.myIds,
      myName: authController.nickname?.trim() ?? '',
      myCharacterId: me.id,
    );

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
                    _CharBubble(asset: me.assetPath, label: _meName(t)),
                    for (final f in friends)
                      if (!blockedUsersController.isBlocked(f.uid))
                      _CharBubble(
                        asset: AppCharacter.byId(f.characterId).assetPath,
                        label: _friendLabel(f),
                        editing: togetherEditing.isEditing(room.id, f.uid),
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
          if (showInviteNudge) ...[
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerRight,
              child: _NudgeBubble(
                textKey: _NudgeKind.invite,
                tail: _NudgeTail.up,
                alignEnd: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _meName(AppStrings t) {
    final name = authController.nickname?.trim();
    if (name != null && name.isNotEmpty) return name;
    return t.meLabel;
  }

  String _friendLabel(DdayFriendMember f) {
    final name = f.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return AppStrings.current.togetherFriendFallbackName;
  }
}

class _CharBubble extends StatelessWidget {
  const _CharBubble({
    required this.asset,
    required this.label,
    this.editing = false,
  });

  final String asset;
  final String label;

  /// This friend has the widget decorator open right now.
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          EditingSpinnerOverlay(
            editing: editing,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                asset,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                cacheWidth: (52 * MediaQuery.devicePixelRatioOf(context))
                    .round()
                    .clamp(1, 512),
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
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

class _RoomWidgetPreview extends StatefulWidget {
  const _RoomWidgetPreview({
    required this.room,
    required this.cheerText,
    required this.onOpenDecorate,
  });

  final DdayItem room;
  final String? cheerText;
  final VoidCallback onOpenDecorate;

  @override
  State<_RoomWidgetPreview> createState() => _RoomWidgetPreviewState();
}

class _RoomWidgetPreviewState extends State<_RoomWidgetPreview> {
  Size? _hostSize;
  TogetherWidgetSize? _hostForSize;
  double _hostCornerDp = TogetherWidgetSize.defaultCornerDp;

  @override
  void initState() {
    super.initState();
    _loadHostSize();
  }

  Future<void> _loadHostSize() async {
    // Opening the room only reads the launcher cell. Redrawing the home
    // widget here decodes the full background and characters during the
    // page transition.
    final host = await HomeWidgetSync.loadHostPreviewSize(
      roomId: widget.room.id,
    );
    if (!mounted || host == null) return;
    setState(() {
      _hostSize = host.size;
      _hostForSize = host.forSize;
      _hostCornerDp = host.cornerDp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final cheerText = widget.cheerText;
    final onOpenDecorate = widget.onOpenDecorate;
    final cheer = cheerText?.trim();
    final label = (cheer != null && cheer.isNotEmpty) ? cheer : '';
    final friendId = room.friendCharacterId;
    final friendBlocked = friendId != null &&
        room.friends.any(
          (friend) =>
              friend.characterId == friendId &&
              blockedUsersController.isBlocked(friend.uid),
        );
    final meX = ddayController.meOffsetXForRoom(room.id).toDouble();
    final meY = ddayController.meOffsetYForRoom(room.id).toDouble();
    final friendX = ddayController.friendOffsetXForRoom(room.id).toDouble();
    final friendY = ddayController.friendOffsetYForRoom(room.id).toDouble();
    final textX = ddayController.textOffsetXForRoom(room.id).toDouble();
    final textY = ddayController.textOffsetYForRoom(room.id).toDouble();
    final widgetSize = ddayController.widgetSizeForRoom(room.id);
    final previewSize = TogetherWidgetPreview.sizeForShape(
      TogetherWidgetShape.square,
      widgetSize,
      _hostSize,
      _hostForSize,
    );
    final charBase = widgetSize.charFactor;
    final people = TogetherCrowdLayout.roster(
      myUid: authController.viewerUid,
      myCharacterId: ddayController.meCharacterIdForRoom(room.id),
      myName: authController.nickname?.trim() ?? '',
      myIds: authController.myIds,
      hostUid: room.cloudOwnerUid,
      friends: room.friends,
    );
    final placed = TogetherCrowdLayout.withUserScale(
      placed: TogetherCrowdLayout.resolve(
        people: people,
        canvasW: previewSize.width,
        canvasH: previewSize.height,
        charFactor: charBase,
        saved: ddayController.crowdForRoom(room.id),
      ),
      myUid: authController.viewerUid,
      meScale: ddayController.charScaleForRoom(room.id),
      friendScale: ddayController.friendScaleForRoom(room.id),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDecorate,
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: IgnorePointer(
            child: TogetherWidgetPreview(
            width: previewSize.width,
            height: previewSize.height,
            charW: 72 * charBase,
            charH: 96 * charBase,
            label: label,
            me: ddayController.meCharacterForRoom(room.id),
            friend: room.hasFriend && friendId != null && !friendBlocked
                ? AppCharacter.byId(friendId)
                : null,
            meX: meX,
            meY: meY,
            friendX: friendX,
            friendY: friendY,
            crowd: [
              for (final slot in placed)
                TogetherPreviewSprite(
                  keyId: slot.uid,
                  assetPath: slot.uid == authController.viewerUid
                      ? ddayController.meCharacterForRoom(room.id).assetPath
                      : AppCharacter.byId(slot.characterId).assetPath,
                  x: slot.x,
                  y: slot.y,
                  scale: slot.scale,
                  rotation: slot.rotation,
                ),
            ],
            bubbles: [
              for (final bubble in ddayController.bubblesForRoom(room.id))
                TogetherPreviewBubble(bubble: bubble),
            ],
            textX: textX,
            textY: textY,
            textRotation: ddayController.textRotationForRoom(room.id).toDouble(),
            isPixel: true,
            meScale: ddayController.charScaleForRoom(room.id),
            friendScale: ddayController.friendScaleForRoom(room.id),
            textScale: ddayController.textScaleForRoom(room.id),
            bgColor: 0x00000000,
            bgOpacity: 100,
            bgAssetPath: WidgetAlbumBackground.resolvedAsset(
              themeId: ddayController.bgThemeForRoom(room.id),
              roomId: room.id,
            ),
            textColor: ddayController.textColorForRoom(room.id),
            textFont: ddayController.textFontForRoom(room.id),
            shape: TogetherWidgetShape.square,
            cornerRadius: _hostCornerDp,
            ),
          ),
        ),
      ),
    );
  }
}

enum _NudgeKind { invite, decorate }

enum _NudgeTail { up, down }

class _NudgeBubble extends StatelessWidget {
  const _NudgeBubble({
    required this.textKey,
    required this.tail,
    required this.alignEnd,
  });

  final _NudgeKind textKey;
  final _NudgeTail tail;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final text = textKey == _NudgeKind.invite
        ? t.togetherInviteNudge
        : t.togetherDecorateNudge;
    final accent = context.palette.accent;
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTheme.body.copyWith(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final pointer = Padding(
      padding: EdgeInsets.only(right: alignEnd ? 12 : 0, left: alignEnd ? 0 : 18),
      child: CustomPaint(
        size: const Size(14, 8),
        painter: _NudgeTailPainter(color: accent, up: tail == _NudgeTail.up),
      ),
    );
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (tail == _NudgeTail.up) pointer,
        bubble,
        if (tail == _NudgeTail.down) pointer,
      ],
    );
  }
}

class _NudgeTailPainter extends CustomPainter {
  const _NudgeTailPainter({required this.color, required this.up});

  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NudgeTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.up != up;
}

