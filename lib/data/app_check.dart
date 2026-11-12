import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Check: Firestore and Functions can then tell requests from
/// the real app (Play Integrity / App Attest) apart from ones sent straight to
/// Firebase with the public config. Requests are only refused once App Check
/// is set to "Enforce" in the Firebase console; until then this just reports.
///
/// Debug builds use the debug provider. On first run it logs a debug token
/// ("Enter this debug secret into the allow list…"); add it under
/// App Check → Apps → Manage debug tokens so the dev build keeps working
/// after enforcement.
///
/// Call after every `Firebase.initializeApp` of the default app, including
/// the background push isolate.
Future<void> activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (e) {
    // Never block startup; unenforced Firebase keeps working without it.
    debugPrint('App Check activate: $e');
  }
}
