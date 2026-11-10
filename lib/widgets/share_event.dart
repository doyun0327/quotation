import 'package:flutter/material.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// Share event: send an invite code [CharacterController.shareEventGoal]
/// times (any rooms) to open [AppCharacter.shareEvent].
abstract final class ShareEvent {
  /// Call after an invite code was shared or copied. Shows the reward when
  /// this send completes the event.
  static Future<void> onInviteSent(BuildContext context) async {
    final opened = await characterController.recordInviteSent();
    if (!opened || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final t = AppStrings.current;
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            t.shareEventOpenedTitle,
            textAlign: TextAlign.center,
            style: AppTheme.body.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _EventArt(size: 140),
              const SizedBox(height: 10),
              Text(
                t.shareEventOpenedBody,
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.trialWelcomeConfirm),
            ),
          ],
        );
      },
    );
  }
}

class _EventArt extends StatelessWidget {
  const _EventArt({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppCharacter.shareEvent.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );
  }
}

/// Together tab banner: shows the reward character and the progress until
/// the event is done, then disappears.
class ShareEventCard extends StatelessWidget {
  const ShareEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: characterController,
      builder: (context, _) {
        if (characterController.shareEventDone) return const SizedBox.shrink();
        final t = AppStrings.current;
        final accent = context.palette.accent;
        final sent = characterController.inviteSends;
        const goal = CharacterController.shareEventGoal;
        // One headline, one quiet line, and a step per invite to send.
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const _EventArt(size: 60),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.shareEventTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.shareEventBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body.copyWith(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ● ● ○ : invites sent out of the goal.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < goal; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < sent
                            ? accent
                            : accent.withValues(alpha: 0.15),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
