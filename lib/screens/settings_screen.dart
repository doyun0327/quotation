import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/billing_controller.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/screens/account_deletion_screen.dart';
import 'package:quotation/screens/legal_screen.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/font_scale_controller.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/language_row.dart';
import 'package:quotation/widgets/nickname_dialog.dart';
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

  /// iPhone gets a provider chooser; other platforms go straight to Google.
  Future<void> _chooseSignIn(BuildContext context) async {
    if (!AuthController.isAppleSignInAvailable) {
      await _signIn(context);
      return;
    }
    final t = AppStrings.current;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.loginMethodTitle,
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop('apple'),
                icon: const Icon(Icons.apple, size: 22),
                label: Text(t.appleLoginTitle),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTheme.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop('google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.ink, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTheme.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(t.googleLoginTitle),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'apple':
        await _signInWithApple(context);
      case 'google':
        await _signIn(context);
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    final t = AppStrings.current;
    final ok = await authController.signInWithApple();
    if (!context.mounted) return;
    if (ok) {
      _toast(context, t.appleLoginSuccess);
      return;
    }
    switch (authController.lastError) {
      case 'canceled':
        _toast(context, t.googleLoginCanceled);
      case 'config':
        _toast(context, t.appleLoginConfigError);
      default:
        final detail = authController.lastErrorDetail;
        _toast(
          context,
          detail == null || detail.isEmpty
              ? t.appleLoginFailed
              : t.appleLoginFailedDetail(detail),
        );
    }
  }

  Future<void> _subscribe(BuildContext context) async {
    final code = await billingController.buyMonthly();
    if (!context.mounted || code == null) return;
    _toast(context, AppStrings.current.billingError(code));
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
        billingController,
        authController,
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final fontOption = fontScaleController.option;
        final language = localeController.language;
        final visualStyle = visualStyleController.style;
        final isPremium = membershipController.isPremium;
        final user = authController.user;
        final signedIn = user != null;
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
                            title: authController.nickname ?? t.nicknameEmptyTitle,
                            subtitle: authController.googleEmail ??
                                t.nicknameEditSubtitle,
                            trailing: SettingsOutlineButton(
                              label: signedIn ? t.logout : t.login,
                              onPressed: authController.isBusy
                                  ? null
                                  : () => signedIn
                                      ? _signOut(context)
                                      : _chooseSignIn(context),
                            ),
                            onTap: () => showNicknameDialog(context),
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
                              onPressed: billingController.isBusy
                                  ? null
                                  : () => _subscribe(context),
                            ),
                            onTap: billingController.isBusy
                                ? null
                                : () => _subscribe(context),
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
                            icon: Icons.description_outlined,
                            title: t.termsTitle,
                            subtitle: t.termsSubtitle,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const LegalScreen(),
                                ),
                              );
                            },
                          ),
                          SettingsItem(
                            icon: Icons.person_off_outlined,
                            title: t.accountDeleteTitle,
                            subtitle: t.accountDeleteSubtitle,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AccountDeletionScreen(),
                                ),
                              );
                            },
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
