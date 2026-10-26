import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_invite_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

/// Host screen: create an invite code and link for a D-Day.
class DdayInviteScreen extends StatefulWidget {
  const DdayInviteScreen({super.key, required this.item});

  final DdayItem item;

  @override
  State<DdayInviteScreen> createState() => _DdayInviteScreenState();
}

class _DdayInviteScreenState extends State<DdayInviteScreen> {
  bool _busy = false;
  String? _code;
  String? _shareUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInvite());
  }

  Future<void> _ensureInvite() async {
    final t = AppStrings.current;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Invites write to Firestore — need Firebase Auth, not local Google only.
      if (FirebaseAuth.instance.currentUser == null) {
        final ok = await authController.ensureFirebaseSession();
        if (!ok || FirebaseAuth.instance.currentUser == null) {
          if (!mounted) return;
          setState(() => _error = t.ddayInviteLoginAgain);
          return;
        }
      }

      final result = await DdayInviteRepository.createOrGetInvite(
        ddayId: widget.item.id,
        title: widget.item.title,
        targetDate: widget.item.targetDate,
        iconId: widget.item.iconId,
        repeatYearly: widget.item.repeatYearly,
      );
      if (!mounted) return;
      setState(() {
        _code = result.code;
        _shareUrl = result.shareUrl;
      });
    } catch (e) {
      if (!mounted) return;
      final detail = e.toString();
      debugPrint('createOrGetInvite: $detail');
      if (detail.contains('not_signed_in') ||
          detail.contains('permission-denied') ||
          detail.contains('PERMISSION_DENIED') ||
          detail.contains('CONFIGURATION_NOT_FOUND')) {
        setState(() => _error = t.ddayInviteLoginAgain);
      } else {
        setState(() => _error = t.ddayInviteCreateFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final code = _code;
    final url = _shareUrl;
    if (code == null || url == null) return;
    final t = AppStrings.current;
    await SharePlus.instance.share(
      ShareParams(
        text: t.ddayInviteShareText(
          widget.item.title,
          code,
          url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
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
          t.ddayInviteTitle,
          style: AppTheme.body.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: palette.accent,
          ),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: ddayController,
        builder: (context, _) {
          final matches = ddayController.items
              .where((e) => e.id == widget.item.id)
              .toList();
          final item = matches.isEmpty ? widget.item : matches.first;
          final liveFriends = item.friends;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                t.ddayInviteSubtitle,
                style: AppTheme.body.copyWith(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: AppTheme.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.ddayInviteFriendCount(liveFriends.length),
                style: AppTheme.body.copyWith(
                  fontSize: 13,
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (liveFriends.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in liveFriends)
                      Chip(
                        label: Text(
                          f.displayName?.isNotEmpty == true
                              ? f.displayName!
                              : t.characterName(f.characterId),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else if (_error != null) ...[
                Text(
                  _error!,
                  style: AppTheme.body.copyWith(color: Colors.redAccent),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    await authController.ensureFirebaseSession();
                    await _ensureInvite();
                  },
                  child: Text(
                    FirebaseAuth.instance.currentUser == null
                        ? t.googleLoginTitle
                        : t.ddayInviteRetry,
                  ),
                ),
              ] else if (_code != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE0E6EF)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        t.ddayInviteCodeLabel,
                        style: AppTheme.body.copyWith(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _code!,
                        style: AppTheme.body.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _code!),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t.ddayInviteCodeCopied)),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(t.ddayInviteCopyCode),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _share,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: Text(
                      t.ddayInviteShare,
                      style: AppTheme.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
