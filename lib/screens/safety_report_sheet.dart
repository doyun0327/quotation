import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quotation/data/blocked_users_controller.dart';
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

  Future<void> _submit(_CheerTarget target) async {
    if (_busy || !_canReport(target)) return;
    final room = _room;
    if (room == null) return;
    setState(() => _busy = true);
    final t = AppStrings.current;
    final result = await SafetyReportRepository.submit(
      roomId: room.id,
      reason: _reason,
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
      await _blockUid(author, target, hideCurrentCheer: true);
    } else {
      await blockedUsersController.hideCheer(
        roomId: room.id,
        text: target.text,
      );
      await ddayController.setRoomCheer(room.id, '');
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
    if (hidden) {
      await ddayController.setRoomCheer(widget.roomId, '');
      await HomeWidgetSync.syncDday();
    }
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
            final target = _targetOf(room, snap.data);
            final canReport = _canReport(target);
            final me = _myUid;
            final friends = room.friends.where((friend) {
              return friend.uid.isNotEmpty && friend.uid != me;
            }).toList();
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
                      canReport
                          ? t.safetyReportBody
                          : (target.text.isEmpty
                              ? t.safetyNoCheer
                              : t.safetyOwnCheer),
                      style: AppTheme.body.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                    if (canReport) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            target.text,
                            style: AppTheme.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
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
                        onPressed: _busy ? null : () => _submit(target),
                        child: Text(t.safetySubmit),
                      ),
                    ],
                    if (friends.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        t.safetyFriends,
                        style: AppTheme.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      for (final friend in friends)
                        _friendRow(t, friend, target),
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
        child: Text(blocked ? t.safetyUnblock : t.safetyBlockUser),
      ),
    );
  }
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
