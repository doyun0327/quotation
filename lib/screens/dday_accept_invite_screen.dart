import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/dday_invite_repository.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/screens/together_room_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// Guest screen: enter invite code (or prefilled from deep link) and join.
class DdayAcceptInviteScreen extends StatefulWidget {
  const DdayAcceptInviteScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<DdayAcceptInviteScreen> createState() => _DdayAcceptInviteScreenState();
}

class _DdayAcceptInviteScreenState extends State<DdayAcceptInviteScreen> {
  late final TextEditingController _codeCtrl;
  bool _busy = false;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(
      text: widget.initialCode?.toUpperCase() ?? '',
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final t = AppStrings.current;
    setState(() {
      _busy = true;
      _message = null;
      _success = false;
    });
    try {
      // Guest-facing: only ask for Google sign-in, no technical wording.
      final ok = await authController.ensureFirebaseSession();
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _success = false;
          _message = t.ddayInviteNeedLogin;
        });
        return;
      }

      final roomId =
          await DdayInviteRepository.acceptInviteByCode(_codeCtrl.text);
      await DdayCloudSync.pullMemberships();
      await ddayController.pinForWidget(roomId);
      await HomeWidgetSync.syncDday();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TogetherRoomScreen(roomId: roomId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = _mapError(e, t);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapError(Object e, AppStrings t) {
    final s = e.toString();
    if (s.contains('invite_not_found')) return t.ddayInviteNotFound;
    if (s.contains('invite_expired')) return t.ddayInviteExpired;
    if (s.contains('friends_full')) return t.ddayInviteFull;
    if (s.contains('cannot_join_own')) return t.ddayInviteOwnCode;
    if (s.contains('invalid_code')) return t.ddayInviteInvalidCode;
    if (s.contains('not_signed_in')) return t.ddayInviteNeedLogin;
    return t.ddayInviteAcceptFailed;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F7FD),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
        ),
        title: Text(
          t.ddayInviteAcceptTitle,
          style: AppTheme.body.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: palette.accent,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            t.ddayInviteAcceptSubtitle,
            style: AppTheme.body.copyWith(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: DdayInviteLimits.codeLength,
            decoration: InputDecoration(
              labelText: t.ddayInviteCodeLabel,
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            style: AppTheme.body.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _accept,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                shape: const StadiumBorder(),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      t.ddayInviteAcceptAction,
                      style: AppTheme.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: AppTheme.body.copyWith(
                color: _success ? Colors.green.shade700 : Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
