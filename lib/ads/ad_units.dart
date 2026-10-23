import 'package:flutter/foundation.dart';

/// AdMob ids for dearly (`com.dearly.quoteswidget`).
abstract final class AdUnits {
  static const appId = 'ca-app-pub-4752729386590212~7216288149';
  static const banner = 'ca-app-pub-4752729386590212/4127090374';

  /// Google's sample banner. Labeled "Test Ad".
  static const androidTestBanner = 'ca-app-pub-3940256099942544/6300978111';

  /// Store builds pass `--dart-define=PROD_ADS=true`.
  /// Everyday installs keep the test creative so taps are not invalid traffic.
  static const prodAds = bool.fromEnvironment('PROD_ADS');

  static String get bannerUnitId {
    if (kIsWeb) return banner;
    if (prodAds && kReleaseMode) return banner;
    return androidTestBanner;
  }

  /// Google's sample rewarded ad. Labeled as a test ad.
  static const androidTestRewarded =
      'ca-app-pub-3940256099942544/5224354917';

  /// Rewarded unit used to open a shop character. Reward amount in AdMob is 1.
  static const rewarded = 'ca-app-pub-4752729386590212/6190216743';

  static String get rewardedUnitId {
    if (kIsWeb) return androidTestRewarded;
    if (prodAds && kReleaseMode) return rewarded;
    return androidTestRewarded;
  }
}
