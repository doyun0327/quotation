import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/encouragement_notification_scheduler.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/main_shell.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/font_scale_controller.dart';
import 'package:quotation/theme/theme_controller.dart';
import 'package:quotation/theme/visual_style_controller.dart';

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
  await visualStyleController.load();
  await QuoteRepository.initialize();
  selectionController.syncAfterQuotesReady();
  selectionController.addListener(HomeWidgetSync.syncFromHome);
  themeController.addListener(HomeWidgetSync.syncThemeOnly);
  await HomeWidgetSync.initialize();
  await EncouragementNotificationScheduler.initialize();
  await authController.initialize();
  runApp(const QuotationApp());
}

class QuotationApp extends StatelessWidget {
  const QuotationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        themeController,
        visualStyleController,
        fontScaleController,
        localeController,
      ]),
      builder: (context, _) {
        return MaterialApp(
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
              // Key forces rebuild of titles/icons when style changes.
              child: KeyedSubtree(
                key: ValueKey(visualStyleController.style.id),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const MainShell(),
        );
      },
    );
  }
}
