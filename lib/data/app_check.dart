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
/// Optional fixed debug token for debug builds, so several emulators can
/// share one token already registered in the console:
/// `flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<uuid>`. Never set it in
/// store builds (release builds ignore it anyway).
const _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

Future<void> activateAppCheck() async {
  try {
    final token = _debugToken.isEmpty ? null : _debugToken;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(debugToken: token)
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider(debugToken: token)
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (e) {
    // Never block startup; unenforced Firebase keeps working without it.
    debugPrint('App Check activate: $e');
  }
}
