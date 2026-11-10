import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's consent prompt for ads. It only appears where the law asks for
/// it (EEA, UK, Switzerland), and needs a privacy message published in AdMob.
abstract final class AdConsent {
  static Future<void>? _gathering;
  static bool _updateFailed = false;

  /// Settings shows a way to change the choice while this is true.
  static final privacyOptionsRequired = ValueNotifier<bool>(false);

  static Future<void> gather() => _gathering ??= _gather();

  static Future<void> _gather() async {
    if (kIsWeb) return;
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('ad consent form: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
      },
      (error) {
        // Also hit when AdMob has no published consent message yet. Ads then
        // run as before rather than stopping in every country.
        debugPrint('ad consent update: ${error.message}');
        _updateFailed = true;
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    await _refreshPrivacyOptions();
  }

  static Future<void> _refreshPrivacyOptions() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('ad consent status: $e');
    }
  }

  /// False until the prompt is answered, and whenever ads are not allowed.
  static Future<bool> canShowAds() async {
    if (kIsWeb) return true;
    await gather();
    try {
      if (await ConsentInformation.instance.canRequestAds()) return true;
      return _updateFailed;
    } catch (e) {
      debugPrint('ad consent check: $e');
      return false;
    }
  }

  static void showPrivacyOptions() {
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('ad privacy options: ${error.message}');
    });
  }
}
