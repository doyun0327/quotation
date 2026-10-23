import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quotation/ads/ad_units.dart';

/// Rewarded ad used to unlock a shop character.
class InterstitialAds {
  static RewardedAd? _ready;
  static bool _loading = false;

  static void preload() {
    if (_ready != null || _loading) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdUnits.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ready = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _ready = null;
          _loading = false;
          debugPrint('RewardedAds: $error');
        },
      ),
    );
  }

  /// Shows one rewarded ad. True only after the reward is granted.
  static Future<bool> show() async {
    final ad = _ready;
    if (ad == null) {
      preload();
      return false;
    }
    _ready = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        preload();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        debugPrint('RewardedAds show: $error');
        preload();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (shown, reward) {
        earned = true;
      },
    );
    return done.future;
  }
}
