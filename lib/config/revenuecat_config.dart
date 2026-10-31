import 'package:flutter/foundation.dart';

/// Public RevenueCat SDK keys: Android `goog_…`, iOS `appl_…`.
///
/// The secret API key stays in the RevenueCat dashboard and must not be
/// placed in the app. Paste the public keys at build time:
/// `--dart-define=REVENUECAT_ANDROID_API_KEY=goog_...`
/// `--dart-define=REVENUECAT_IOS_API_KEY=appl_...`
abstract final class RevenueCatConfig {
  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: 'goog_hEsPzpOwjAERNxjWrGupMANGWwm',
  );

  /// From RevenueCat → API keys → "Dearly (App Store)".
  static const String iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: 'appl_laYIEqlZpHIYJbSoeMEjmpjEfzF',
  );

  /// Key for the store this build runs on. Empty on unsupported platforms.
  static String get apiKey {
    if (kIsWeb) return '';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidApiKey.trim(),
      TargetPlatform.iOS => iosApiKey.trim(),
      _ => '',
    };
  }

  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get isConfigured => apiKey.isNotEmpty;
}
