import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics: crashes and uncaught errors reach the Firebase
/// console (Crashlytics) with the screen and code line. Release builds only,
/// so development runs do not fill the report.
///
/// Call after `Firebase.initializeApp`, in the main app and in the
/// background push isolate.
abstract final class CrashReporting {
  static Future<void> start() async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      if (kDebugMode) return;
      // Flutter framework errors (build, layout, paint).
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      // Uncaught async errors outside the framework.
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('Crashlytics start: $e');
    }
  }
}
