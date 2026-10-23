/// Public RevenueCat Android SDK key (`goog_…`).
///
/// The secret API key stays in the RevenueCat dashboard and must not be
/// placed in the app. Paste the public key at build time:
/// `--dart-define=REVENUECAT_ANDROID_API_KEY=goog_...`
abstract final class RevenueCatConfig {
  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: 'goog_hEsPzpOwjAERNxjWrGupMANGWwm',
  );

  static bool get isConfigured => androidApiKey.trim().isNotEmpty;
}
