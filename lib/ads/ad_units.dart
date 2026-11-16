import 'package:flutter/foundation.dart';

/// AdMob ids for dearly (`com.dearly.quoteswidget`).
/// AdMob apps are per platform: Android and iOS each have their own app id
/// (AndroidManifest.xml / Info.plist) and their own ad units.
abstract final class AdUnits {
  // Android app `~7216288149`
  static const androidAppId = 'ca-app-pub-4752729386590212~7216288149';
  static const androidBanner = 'ca-app-pub-4752729386590212/4127090374';
  static const androidRewarded = 'ca-app-pub-4752729386590212/6190216743';

  // iOS app `~5570330297`. Units must be created under this iOS app.
  static const iosAppId = 'ca-app-pub-4752729386590212~5570330297';
  static const iosBanner = 'ca-app-pub-4752729386590212/1582983825';
  static const iosRewarded = 'ca-app-pub-4752729386590212/7760630931';

  /// Google's sample units. Labeled "Test Ad".
  static const androidTestBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const androidTestRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const iosTestBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const iosTestRewarded = 'ca-app-pub-3940256099942544/1712485313';

  /// Store builds pass `--dart-define=PROD_ADS=true`.
  /// Everyday installs keep the test creative so taps are not invalid traffic.
  static const prodAds = bool.fromEnvironment('PROD_ADS');

  static bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _prod => prodAds && kReleaseMode;

  static String get bannerUnitId {
    if (_ios) return _prod ? iosBanner : iosTestBanner;
    return _prod ? androidBanner : androidTestBanner;
  }

  /// Rewarded unit used to open a shop character. Reward amount in AdMob is 1.
  static String get rewardedUnitId {
    if (_ios) return _prod ? iosRewarded : iosTestRewarded;
    return _prod ? androidRewarded : androidTestRewarded;
  }
}
