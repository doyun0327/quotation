import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/encouragement_notification_scheduler.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/invite_deep_link.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/data/user_profile_sync.dart';
import 'package:quotation/firebase_options.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/character_select_screen.dart';
import 'package:quotation/screens/main_shell.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/font_scale_controller.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  } catch (e) {
    debugPrint('Firebase.initializeApp: $e');
  }

  await visualStyleController.load();
  await characterController.load();
  await QuoteRepository.initialize();
  await ddayController.load();
  selectionController.syncAfterQuotesReady();
  selectionController.addListener(HomeWidgetSync.syncFromHome);
  themeController.addListener(HomeWidgetSync.syncThemeOnly);
  characterController.addListener(() {
    HomeWidgetSync.syncCharacter();
    unawaited(UserProfileSync.syncCharacter());
  });
  visualStyleController.addListener(HomeWidgetSync.syncDday);

  runApp(const QuotationApp());

  unawaited(HomeWidgetSync.initialize());
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
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        themeController,
        visualStyleController,
        fontScaleController,
        localeController,
        characterController,
      ]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Daily Word',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(themeController.palette),
          locale: Locale(localeController.language.id),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(fontScaleController.scale),
              ),
              child: KeyedSubtree(
                key: ValueKey(
                  '${visualStyleController.style.id}_'
                  '${characterController.character.id}',
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: characterController.hasPicked
              ? const MainShell()
              : CharacterSelectScreen(
                  onFinished: () => setState(() {}),
                ),
        );
      },
    );
  }
}
