import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// iPhone: when the App Store has a newer version than this install, asks
/// the user to update and sends them to the store. The dialog cannot be
/// dismissed, so an old build is not used against a newer server.
abstract final class AppUpdateCheck {
  static const _bundleId = 'com.dearly.quoteswidget';
  static const _appStoreId = '6827842803';
  static const _channel = MethodChannel(
    'com.dearly.quoteswidget/widget_reload',
  );

  static bool _showing = false;

  static Future<void> run(GlobalKey<NavigatorState> navigatorKey) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (_showing) return;
    try {
      final installed = await _channel.invokeMethod<String>('appVersion');
      final store = await _storeVersion();
      if (installed == null || store == null) return;
      if (!isNewer(store, installed)) return;
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      _showing = true;
      await _showDialog(context);
    } catch (e) {
      // Offline or lookup failed: never block the app for that.
      debugPrint('app update check: $e');
    } finally {
      _showing = false;
    }
  }

  /// Version string on the App Store, or null when it cannot be read.
  static Future<String?> _storeVersion() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      // Cache-buster: the lookup is cached by Apple's CDN for a while.
      final uri = Uri.https('itunes.apple.com', '/lookup', {
        'bundleId': _bundleId,
        't': '${DateTime.now().millisecondsSinceEpoch ~/ 60000}',
      });
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 6),
      );
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final results = decoded['results'];
      if (results is! List || results.isEmpty) return null;
      final version = (results.first as Map)['version'];
      return version is String && version.isNotEmpty ? version : null;
    } finally {
      client.close(force: true);
    }
  }

  /// True when [store] is a higher dotted version than [installed]
  /// ("1.0.10" > "1.0.9").
  @visibleForTesting
  static bool isNewer(String store, String installed) {
    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final a = parts(store);
    final b = parts(installed);
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static Future<void> _openStore() async {
    final store = Uri.parse('itms-apps://apps.apple.com/app/id$_appStoreId');
    if (await launchUrl(store, mode: LaunchMode.externalApplication)) return;
    await launchUrl(
      Uri.parse('https://apps.apple.com/app/id$_appStoreId'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> _showDialog(BuildContext context) {
    final t = AppStrings.current;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              t.appUpdateTitle,
              style: AppTheme.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            content: Text(
              t.appUpdateBody,
              style: AppTheme.body.copyWith(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            actions: [
              // Stays open: coming back from the store without updating
              // shows the same request again.
              FilledButton(
                onPressed: () => unawaited(_openStore()),
                child: Text(t.appUpdateButton),
              ),
            ],
          ),
        );
      },
    );
  }
}
