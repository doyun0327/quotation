/// Google Cloud Console OAuth (same project for Android + Web clients):
///
/// 1. APIs & Services → OAuth consent screen
///    - If status is "Testing", add your Google account under Test users
/// 2. Credentials → Create OAuth client ID
///    - Android
///      package: `com.quotation.quotation`
///      SHA-1:  `11:09:9B:F0:34:CE:72:A0:28:FC:21:6D:CC:1E:A5:DE:C9:EE:C1:E2`
///      SHA-256:`3B:6D:11:9B:34:9E:69:66:83:1A:0C:6A:F7:07:D1:9A:28:B8:80:8E:19:21:29:86:13:B5:2C:CC:57:1D:1A:1E`
///    - Web application → paste that Client ID into [serverClientId]
///      (must be the *Web* client, not the Android client)
///
/// Or at build time:
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
abstract final class GoogleAuthConfig {
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    // Web OAuth client ID from the same GCP project as the Android client.
    defaultValue:
        '204379279129-vo3qsc9bptaphodhfrbi438jfn4drbku.apps.googleusercontent.com',
  );

  static bool get isConfigured => serverClientId.trim().isNotEmpty;
}
