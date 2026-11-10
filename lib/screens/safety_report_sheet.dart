import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/together_bubble.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/safety_report_repository.dart';
import 'package:quotation/data/together_cheer_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_theme.dart';

Future<void> showSafetyReportSheet({
  required BuildContext context,
  required DdayItem room,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _SafetyReportSheet(roomId: room.id),
  );
}

class _SafetyReportSheet extends StatefulWidget {
  const _SafetyReportSheet({required this.roomId});

  final String roomId;

  @override
  State<_SafetyReportSheet> createState() => _SafetyReportSheetState();
}

class _SafetyReportSheetState extends State<_SafetyReportSheet> {
  String _reason = SafetyReportReason.harassment;
  bool _block = true;
  bool _busy = false;
  String? _targetKey;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  DdayItem? get _room {
    final matches = ddayController.items.where((e) => e.id == widget.roomId);
    return matches.isEmpty ? null : matches.first;
  }

  _CheerTarget _targetOf(DdayItem room, TogetherCheer? cloud) {
    final local = room.latestCheer?.trim();
    final cloudText = cloud?.text.trim();
    final mine = local != null &&
        local.isNotEmpty &&
        (cloudText == null || local != cloudText);
    final text = mine ? local : (cloudText ?? local ?? '');
    final authorUid = mine ? _myUid : cloud?.authorUid;
    final authorName = mine ? null : cloud?.authorName;
    final visible = blockedUsersController.visibleCheer(
      room.id,
      text,
      authorUid: authorUid,
    );
    return _CheerTarget(
      text: visible,
      authorUid: authorUid,
      authorName: authorName,
    );
  }

  bool _canReport(_CheerTarget target) {
    if (target.text.isEmpty) return false;
    final author = target.authorUid;
    final me = _myUid;
    if (author != null && author.isNotEmpty && me != null && author == me) {
      return false;
    }
    return true;
  }

  /// Everything in this room that other people wrote, cheer first.
  List<_ReportTarget> _reportTargets(
    AppStrings t,
    DdayItem room,
    _CheerTarget cheer,
    List<DdayFriendMember> friends,
  ) {
    bool mine(String? uid) =>
        uid != null && uid.isNotEmpty && authController.myIds.contains(uid);
    String? nameOf(String uid) =>
        friends.where((f) => f.uid == uid).firstOrNull?.displayName?.trim();
    return [
      if (_canReport(cheer))
        _ReportTarget(
          key: 'cheer',
          type: 'cheer',
          label: t.safetyKindCheer,
          text: cheer.text,
          authorUid: cheer.authorUid,
          authorName: cheer.authorName,
        ),
      for (final bubble in blockedUsersController.visibleBubbles(
        room.id,
        ddayController.bubblesForRoom(room.id),
      ))
        if (bubble.text.isNotEmpty && !mine(bubble.authorUid))
          _ReportTarget(
            key: 'bubble:${bubble.id}',
            type: 'bubble',
            label: t.safetyKindBubble,
            text: bubble.text,
            authorUid: bubble.authorUid,
            authorName: nameOf(bubble.authorUid),
            bubble: bubble,
          ),
      for (final friend in friends)
        if ((friend.displayName?.trim() ?? '').isNotEmpty)
          _ReportTarget(
            key: 'nickname:${friend.uid}',
            type: 'nickname',
            label: t.safetyKindNickname,
            text: friend.displayName!.trim(),
            authorUid: friend.uid,
            authorName: friend.displayName!.trim(),
          ),
      if (room.title.trim().isNotEmpty && !mine(room.cloudOwnerUid))
        _ReportTarget(
          key: 'room',
          type: 'room_title',
          label: t.safetyKindRoom,
          text: room.title.trim(),
          authorUid: room.cloudOwnerUid,
          authorName: nameOf(room.cloudOwnerUid ?? ''),
        ),
    ];
  }

  Future<void> _submit(_ReportTarget target, _CheerTarget cheer) async {
    if (_busy) return;
    final room = _room;
    if (room == null) return;
    setState(() => _busy = true);
    final t = AppStrings.current;
    final result = await SafetyReportRepository.submit(
      roomId: room.id,
      reason: _reason,
      targetType: target.type,
      targetUid: target.authorUid,
      targetName: target.authorName,
      contentText: target.text,
      note: _note.text,
      blockUser: _block,
    );
    if (!mounted) return;
    if (!result.ok) {
      setState(() => _busy = false);
      _snack(
        result.errorCode == 'not_signed_in' ? t.safetyNeedLogin : t.safetyFailed,
      );
      return;
    }
    final author = target.authorUid;
    if (_block && author != null && author.isNotEmpty) {
      await _blockUid(
        author,
        cheer,
        hideCurrentCheer: author == cheer.authorUid,
      );
    } else if (target.type == 'cheer') {
      await blockedUsersController.hideCheer(
        roomId: room.id,
        text: target.text,
      );
      await ddayController.setRoomCheer(room.id, '');
      await HomeWidgetSync.syncDday();
    } else if (target.bubble != null) {
      await blockedUsersController.hideBubble(room.id, target.bubble!);
      await HomeWidgetSync.syncDday();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    _snack(t.safetySent);
  }

  Future<void> _blockUid(
    String uid,
    _CheerTarget target, {
    required bool hideCurrentCheer,
  }) async {
    final author = target.authorUid;
    await blockedUsersController.block(
      uid: uid,
      roomId: widget.roomId,
      cheerText: hideCurrentCheer || uid == author ? target.text : null,
      cheerAuthorUid: author,
    );
    final hidden = blockedUsersController.hidesCheer(
      roomId: widget.roomId,
      text: target.text,
      authorUid: uid == author ? author : null,
    );
    if (hidden) await ddayController.setRoomCheer(widget.roomId, '');
    // Redraws even with no cheer: the person's bubbles leave the widget too.
    await HomeWidgetSync.syncDday();
  }

  void _snack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.body.copyWith(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return StreamBuilder<TogetherCheer?>(
      stream: TogetherCheerRepository.watch(widget.roomId),
      builder: (context, snap) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            blockedUsersController,
            ddayController,
          ]),
          builder: (context, _) {
            final room = _room;
            if (room == null) return const SizedBox.shrink();
            final cheer = _targetOf(room, snap.data);
            final me = _myUid;
            final friends = room.friends.where((friend) {
              return friend.uid.isNotEmpty && friend.uid != me;
            }).toList();
            final targets = _reportTargets(t, room, cheer, friends);
            final canReport = targets.isNotEmpty;
            final target = !canReport
                ? null
                : targets.where((e) => e.key == _targetKey).firstOrNull ??
                    targets.first;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5DDE8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.safetyReportTitle,
                      style: AppTheme.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      canReport ? t.safetyReportBody : t.safetyNothingToReport,
                      style: AppTheme.body.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                    if (target != null) ...[
                      const SizedBox(height: 12),
                      // Material, not a DecoratedBox: the tiles paint their
                      // ink on it.
                      Material(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: RadioGroup<String>(
                            groupValue: target.key,
                            onChanged: (next) {
                              if (_busy || next == null) return;
                              setState(() => _targetKey = next);
                            },
                            child: Column(
                              children: [
                                for (final item in targets) _targetTile(item),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioGroup<String>(
                        groupValue: _reason,
                        onChanged: (next) {
                          if (_busy || next == null) return;
                          setState(() => _reason = next);
                        },
                        child: Column(
                          children: [
                            _reasonTile(
                              t.safetyReasonHarassment,
                              SafetyReportReason.harassment,
                            ),
                            _reasonTile(
                              t.safetyReasonSexual,
                              SafetyReportReason.sexual,
                            ),
                            _reasonTile(
                              t.safetyReasonSpam,
                              SafetyReportReason.spam,
                            ),
                            _reasonTile(
                              t.safetyReasonOther,
                              SafetyReportReason.other,
                            ),
                          ],
                        ),
                      ),
                      if ((target.authorUid ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _block,
                          onChanged: _busy
                              ? null
                              : (value) =>
                                  setState(() => _block = value ?? false),
                          title: Text(
                            t.safetyBlockUser,
                            style: AppTheme.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            t.safetyBlockHint,
                            style: AppTheme.body.copyWith(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                      TextField(
                        controller: _note,
                        maxLength: 300,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: t.safetyNoteHint,
                          hintStyle:
                              AppTheme.body.copyWith(color: AppColors.muted),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _busy ? null : () => _submit(target, cheer),
                        child: Text(t.safetySubmit),
                      ),
                    ],
                    if (friends.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      for (final friend in friends)
                        _friendRow(t, friend, cheer),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _targetTile(_ReportTarget item) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: item.key,
      title: Text(
        item.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      subtitle: Text(
        item.label,
        style: AppTheme.body.copyWith(fontSize: 12, color: AppColors.muted),
      ),
    );
  }

  Widget _reasonTile(String label, String value) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: value,
      title: Text(
        label,
        style: AppTheme.body.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _friendRow(AppStrings t, DdayFriendMember friend, _CheerTarget target) {
    final blocked = blockedUsersController.isBlocked(friend.uid);
    final name = friend.displayName?.trim();
    final label = (name != null && name.isNotEmpty)
        ? name
        : t.togetherFriendFallbackName;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: AppTheme.body.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      trailing: TextButton(
        onPressed: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                if (blocked) {
                  await blockedUsersController.unblock(friend.uid);
                  await HomeWidgetSync.syncDday();
                } else {
                  await _blockUid(
                    friend.uid,
                    target,
                    hideCurrentCheer: friend.uid == target.authorUid,
                  );
                  if (mounted) _snack(t.safetyBlockedDone);
                }
                if (mounted) setState(() => _busy = false);
              },
        child: Text(blocked ? t.safetyUnblock : t.safetyBlock),
      ),
    );
  }
}

/// One thing in the room that can be reported.
class _ReportTarget {
  const _ReportTarget({
    required this.key,
    required this.type,
    required this.label,
    required this.text,
    this.authorUid,
    this.authorName,
    this.bubble,
  });

  final String key;
  final String type;
  final String label;
  final String text;
  final String? authorUid;
  final String? authorName;
  final TogetherBubble? bubble;
}

class _CheerTarget {
  const _CheerTarget({
    required this.text,
    this.authorUid,
    this.authorName,
  });

  final String text;
  final String? authorUid;
  final String? authorName;
}
