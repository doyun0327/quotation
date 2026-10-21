import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/encouragement_notification_scheduler.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/together_test_room.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/character_select_screen.dart';
import 'package:quotation/screens/dday_accept_invite_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/font_scale_controller.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/language_row.dart';
import 'package:quotation/widgets/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.body.copyWith(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
    );
  }

  Future<void> _signIn(BuildContext context) async {
    final t = AppStrings.current;
    final ok = await authController.signIn();
    if (!context.mounted) return;
    if (ok) {
      _toast(context, t.googleLoginSuccess);
      return;
    }
    switch (authController.lastError) {
      case 'canceled':
        _toast(context, t.googleLoginCanceled);
      case 'canceled_or_config':
      case 'config':
      case 'clientConfigurationError':
        _toast(context, t.googleLoginConfigError);
      case 'missing_client_id':
        _toast(context, t.googleLoginConfigMissing);
      default:
        final detail = authController.lastErrorDetail;
        _toast(
          context,
          detail == null || detail.isEmpty
              ? t.googleLoginFailed
              : t.googleLoginFailedDetail(detail),
        );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await authController.signOut();
    if (!context.mounted) return;
    _toast(context, AppStrings.current.googleLogoutSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListenableBuilder(
      listenable: Listenable.merge([
        fontScaleController,
        localeController,
        themeController,
        visualStyleController,
        membershipController,
        authController,
        characterController,
        ddayController,
        togetherTestRoom,
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final fontOption = fontScaleController.option;
        final language = localeController.language;
        final visualStyle = visualStyleController.style;
        final isPremium = membershipController.isPremium;
        final user = authController.user;
        final signedIn = user != null;
        final character = characterController.character;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                  child: SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 28,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          t.settingsTitle,
                          style: AppTheme.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      SettingsSection(
                        title: t.accountSection,
                        children: [
                          SettingsItem(
                            leading: signedIn && user.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      user.photoUrl!,
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, stack) =>
                                          const GoogleMark(),
                                    ),
                                  )
                                : const GoogleMark(),
                            title: signedIn
                                ? (user.displayName?.isNotEmpty == true
                                    ? user.displayName!
                                    : t.googleLoggedInTitle)
                                : t.googleLoginTitle,
                            subtitle: signedIn
                                ? t.googleLoggedInSubtitle(user.email)
                                : t.googleLoginSubtitle,
                            trailing: SettingsOutlineButton(
                              label: signedIn ? t.logout : t.login,
                              onPressed: authController.isBusy
                                  ? null
                                  : () => signedIn
                                      ? _signOut(context)
                                      : _signIn(context),
                            ),
                            onTap: authController.isBusy
                                ? null
                                : () => signedIn
                                    ? _signOut(context)
                                    : _signIn(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.subscriptionSection,
                        children: [
                          SettingsItem(
                            icon: Icons.auto_awesome_rounded,
                            title: t.premiumTitle,
                            subtitle: t.premiumSubtitle,
                            iconColor: palette.accent,
                            trailing: SettingsOutlineButton(
                              label: t.viewPremium,
                              onPressed: () =>
                                  _toast(context, t.premiumToast),
                            ),
                            onTap: () => _toast(context, t.premiumToast),
                          ),
                          SettingsItem(
                            icon: Icons.workspace_premium_rounded,
                            title: t.premiumToggleTitle,
                            subtitle: t.premiumToggleSubtitle,
                            iconColor: palette.accent,
                            trailing: Switch.adaptive(
                              value: isPremium,
                              activeTrackColor: palette.accent,
                              onChanged: (value) {
                                membershipController.setPremium(value);
                                _toast(
                                  context,
                                  value
                                      ? t.premiumEnabledToast
                                      : t.premiumDisabledToast,
                                );
                              },
                            ),
                            onTap: () {
                              final next = !membershipController.isPremium;
                              membershipController.setPremium(next);
                              _toast(
                                context,
                                next
                                    ? t.premiumEnabledToast
                                    : t.premiumDisabledToast,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.languageSection,
                        children: [
                          SettingsItem(
                            icon: Icons.public_rounded,
                            title: t.languageTitle,
                            subtitle: t.languageSubtitle,
                            trailing: Text(
                              language.label(language),
                              style: AppTheme.body.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.settingsLine,
                              ),
                            ),
                          ),
                          LanguageRow(
                            selectedId: language.id,
                            onSelected: (selected) {
                              localeController.setLanguage(selected);
                              final next = AppStrings(selected);
                              _toast(
                                context,
                                next.languageChanged(selected.label(selected)),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.characterSection,
                        children: [
                          SettingsItem(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                character.assetPath,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                            title: t.characterTitle,
                            subtitle: t.characterSubtitle,
                            trailing: SettingsOutlineButton(
                              label: t.characterChange,
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const CharacterSelectScreen(
                                      allowSkip: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const CharacterSelectScreen(
                                    allowSkip: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.friendCharacterTitle,
                        children: [
                          SettingsItem(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                togetherTestRoom.friendCharacter.assetPath,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                            title: t.friendCharacterTitle,
                            subtitle: t.friendCharacterSubtitle,
                            trailing: Switch.adaptive(
                              value: togetherTestRoom.enabled,
                              activeTrackColor: palette.accent,
                              onChanged: togetherTestRoom.busy
                                  ? null
                                  : (value) async {
                                      final ok = await togetherTestRoom
                                          .setEnabled(value);
                                      if (!context.mounted) return;
                                      _toast(
                                        context,
                                        ok
                                            ? (value
                                                ? t.friendCharacterOnToast
                                                : t.friendCharacterOffToast)
                                            : t.friendCharacterFailedToast,
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.ddayTitle,
                        children: [
                          SettingsItem(
                            icon: Icons.qr_code_rounded,
                            title: t.ddayInviteEnterCodeMenu,
                            subtitle: t.ddayInviteAcceptSubtitle,
                            iconColor: palette.accent,
                            trailing: SettingsOutlineButton(
                              label: t.ddayInviteAcceptAction,
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const DdayAcceptInviteScreen(),
                                  ),
                                );
                              },
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const DdayAcceptInviteScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.styleSection,
                        children: [
                          SettingsItem(
                            icon: Icons.style_outlined,
                            title: t.styleTitle,
                            subtitle: t.styleSubtitle,
                            trailing: Text(
                              t.styleName(visualStyle.id),
                              style: AppTheme.body.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.settingsLine,
                              ),
                            ),
                          ),
                          StyleRow(
                            selectedId: visualStyle.id,
                            onSelected: (selected) {
                              visualStyleController.setStyle(selected);
                              _toast(
                                context,
                                t.styleChanged(t.styleName(selected.id)),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.themeSection,
                        children: [
                          SettingsItem(
                            icon: Icons.palette_outlined,
                            title: t.themeTitle,
                            subtitle: t.themeSubtitle,
                            trailing: Text(
                              t.themeName(palette.id),
                              style: AppTheme.body.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.settingsLine,
                              ),
                            ),
                          ),
                          ThemeSwatchRow(
                            selectedId: palette.id,
                            onSelected: (selected) {
                              themeController.setPalette(selected);
                              _toast(
                                context,
                                t.themeChanged(t.themeName(selected.id)),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.fontSection,
                        children: [
                          SettingsItem(
                            icon: Icons.text_fields_rounded,
                            title: t.fontTitle,
                            subtitle: t.fontSubtitle,
                            trailing: Text(
                              t.fontName(fontOption.id),
                              style: AppTheme.body.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.settingsLine,
                              ),
                            ),
                          ),
                          FontScaleRow(
                            selectedId: fontOption.id,
                            onSelected: (selected) {
                              fontScaleController.setOption(selected);
                              _toast(
                                context,
                                t.fontChanged(t.fontName(selected.id)),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SettingsSection(
                        title: t.otherSection,
                        children: [
                          SettingsItem(
                            icon: Icons.nights_stay_outlined,
                            title: t.eveningDebugTitle,
                            subtitle: t.eveningDebugSubtitle,
                            onTap: () async {
                              await EncouragementNotificationScheduler
                                  .debugShowEveningOnce();
                              if (context.mounted) {
                                _toast(context, t.eveningDebugToast);
                              }
                            },
                          ),
                          SettingsItem(
                            icon: Icons.description_outlined,
                            title: t.termsTitle,
                            subtitle: t.termsSubtitle,
                            onTap: () => _toast(context, t.termsToast),
                          ),
                          SettingsItem(
                            icon: Icons.info_outline_rounded,
                            title: t.appInfoTitle,
                            subtitle: t.appInfoSubtitle,
                            onTap: () => _toast(context, t.appInfoToast),
                          ),
                        ],
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
