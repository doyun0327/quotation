import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quotation/data/app_check.dart';
import 'package:quotation/ads/ad_consent.dart';
import 'package:quotation/ads/interstitial_ads.dart';
import 'package:quotation/data/terms_consent.dart';
import 'package:quotation/widgets/terms_consent_dialog.dart';
import 'package:quotation/data/cloud_consent.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/billing_controller.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/encouragement_notification_scheduler.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/invite_deep_link.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/data/together_fcm.dart';
import 'package:quotation/data/user_profile_sync.dart';
import 'package:quotation/data/widget_fonts.dart';
import 'package:quotation/firebase_options.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/main_shell.dart';
import 'package:quotation/screens/together_room_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/font_scale_controller.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/bottom_banner_ad.dart';
import 'package:quotation/widgets/nickname_dialog.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Used once: the Navigator is rebuilt when the character or style changes.
String? _widgetLaunchRoom;

Route<void> _mainShellRoute() => MaterialPageRoute<void>(
      settings: const RouteSettings(name: Navigator.defaultRouteName),
      builder: (_) => const MainShell(),
    );

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetFont.registerLicenses();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.card,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await activateAppCheck();
    FirebaseMessaging.onBackgroundMessage(togetherFcmBackground);
  } catch (e) {
    debugPrint('Firebase.initializeApp: $e');
  }

  await visualStyleController.load();
  await characterController.load();
  await membershipController.load();
  await localeController.load();
  await QuoteRepository.initialize();
  localeController.addListener(() {
    QuoteRepository.onLocaleChanged();
    unawaited(selectionController.syncAfterQuotesReady());
  });
  await ddayController.load();
  await blockedUsersController.load();
  await CloudConsent.load();
  await TermsConsent.load();
  await selectionController.syncAfterQuotesReady();
  selectionController.addListener(HomeWidgetSync.syncFromHome);
  themeController.addListener(HomeWidgetSync.syncThemeOnly);
  characterController.addListener(() {
    HomeWidgetSync.syncCharacter();
    unawaited(UserProfileSync.syncCharacter());
  });
  visualStyleController.addListener(() {
    unawaited(HomeWidgetSync.syncDday());
    unawaited(HomeWidgetSync.syncFromHome());
  });
  // Server-sent notices (iPhone) are written in this language.
  var noticeLanguage = localeController.language;
  localeController.addListener(() {
    if (localeController.language == noticeLanguage) return;
    noticeLanguage = localeController.language;
    unawaited(UserProfileSync.syncLocale());
  });

  _widgetLaunchRoom = await TogetherFcm.widgetLaunchRoom();
  if (_widgetLaunchRoom != null) mainShellTab.value = 1;

  runApp(const QuotationApp());

  unawaited(AdConsent.canShowAds().then((allowed) async {
    if (!allowed) return;
    await MobileAds.instance.initialize();
    InterstitialAds.preload();
  }));
  unawaited(billingController.initialize());
  unawaited(HomeWidgetSync.initialize());
  unawaited(TogetherFcm.start(appNavigatorKey));
  unawaited(EncouragementNotificationScheduler.initialize());
  unawaited(authController.initialize());
  unawaited(InviteDeepLink.start(appNavigatorKey));
}

class QuotationApp extends StatefulWidget {
  const QuotationApp({super.key});

  @override
  State<QuotationApp> createState() => _QuotationAppState();
}

class _QuotationAppState extends State<QuotationApp> {
  bool _askingTerms = false;
  bool _askingNickname = false;
  bool _showingTrialNotice = false;

  @override
  void initState() {
    super.initState();
    authController.addListener(_onAuthReady);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthReady());
  }

  @override
  void dispose() {
    authController.removeListener(_onAuthReady);
    super.dispose();
  }

  Future<void> _maybeShowTrialNotice() async {
    if (!mounted || _showingTrialNotice) return;
    // Wait until nickname is set so this doesn't stack under that dialog.
    if (authController.nickname == null) return;
    final shouldShow = await membershipController.shouldShowTrialNotice();
    if (!shouldShow || !mounted) return;
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShowTrialNotice();
      });
      return;
    }
    _showingTrialNotice = true;
    final t = AppStrings.current;
    await showDialog<void>(
      context: navContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            t.trialWelcomeTitle,
            style: AppTheme.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          content: Text(
            t.trialWelcomeBody,
            style: AppTheme.body.copyWith(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                t.trialWelcomeConfirm,
                style: AppTheme.body.copyWith(
                  fontWeight: FontWeight.w900,
                  color: themeController.palette.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
    await membershipController.markTrialNoticeShown();
    _showingTrialNotice = false;
  }

  /// Comes before sign-in finishes, so nothing can be written unaccepted.
  Future<bool> _ensureTermsAccepted() async {
    if (TermsConsent.accepted) return true;
    if (_askingTerms) return false;
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onAuthReady();
      });
      return false;
    }
    _askingTerms = true;
    await showTermsConsentDialog(navContext);
    _askingTerms = false;
    if (!mounted) return false;
    // A widget tap can pop the dialog while opening a room: ask again.
    return _ensureTermsAccepted();
  }

  Future<void> _onAuthReady() async {
    if (!mounted || !await _ensureTermsAccepted() || !mounted) return;
    if (!authController.isReady || _askingNickname) {
      return;
    }
    if (authController.nickname == null) {
      final ok = await _maybeAskNickname();
      if (!ok || !mounted) return;
    }
    await _maybeShowTrialNotice();
  }

  Future<bool> _maybeAskNickname() async {
    if (!mounted || _askingNickname || !authController.isReady) {
      return false;
    }
    if (authController.isBusy || authController.nickname != null) return true;
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onAuthReady();
      });
      return false;
    }
    _askingNickname = true;
    await showNicknameDialog(navContext, requiredName: true);
    _askingNickname = false;
    if (!mounted) return false;
    if (authController.nickname == null) {
      return _maybeAskNickname();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        themeController,
        visualStyleController,
        fontScaleController,
        localeController,
        characterController,
        membershipController,
      ]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Dearly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(themeController.palette),
          locale: Locale(localeController.language.id),
          // iOS Simulator (and trackpad) sends mouse/trackpad pointers, which
          // MaterialScrollBehavior ignores on mobile by default.
          scrollBehavior: const _AppScrollBehavior(),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final showAd = !membershipController.isPremium;
            var data = media.copyWith(
              textScaler: TextScaler.linear(fontScaleController.scale),
            );
            if (showAd) {
              data = data.removePadding(removeBottom: true);
            }
            return MediaQuery(
              data: data,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: KeyedSubtree(
                          key: ValueKey(
                            '${visualStyleController.style.id}_'
                            '${characterController.character.id}',
                          ),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                      if (showAd)
                        const SafeArea(
                          top: false,
                          child: BottomBannerAd(),
                        ),
                    ],
                  ),
                  const Positioned.fill(child: _LoginOverlay()),
                ],
              ),
            );
          },
          onGenerateRoute: (settings) =>
              settings.name == Navigator.defaultRouteName
                  ? _mainShellRoute()
                  : null,
          // A widget tap starts on its room, with the main screen behind it.
          onGenerateInitialRoutes: (_) {
            final room = _widgetLaunchRoom;
            _widgetLaunchRoom = null;
            return [
              _mainShellRoute(),
              if (room != null) TogetherRoomScreen.route(room),
            ];
          },
        );
      },
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class _LoginOverlay extends StatelessWidget {
  const _LoginOverlay();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([authController, localeController]),
      builder: (context, _) {
        if (!authController.isSigningIn) {
          return const IgnorePointer(child: SizedBox.expand());
        }
        return AbsorbPointer(
          // Sits above the Navigator, so it needs its own Material for text
          // (otherwise Flutter draws the yellow debug underline).
          child: Material(
            color: const Color(0x99000000),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.current.googleLoggingIn,
                    style: AppTheme.body.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
