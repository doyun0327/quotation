/// Web OAuth client ID for Google `idToken` → Firebase Auth.
/// Project: `dearly-cf730`
///
/// App signing (this repo): `android/app/dearly-debug.jks`
/// Package: `com.quotation.quotation`
/// SHA-1:  `6E:31:0B:53:73:5B:12:D3:43:ED:50:02:8F:CB:4B:FC:54:C2:3F:5E`
/// SHA-256:`D7:4D:08:45:3A:BF:27:CB:DA:78:F8:DC:0B:B9:24:4C:86:05:20:86:C2:49:75:7D:33:CE:7F:A4:A5:78:FE:16`
abstract final class GoogleAuthConfig {
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '313256890607-q02od35jq32g1lp2atr7ou0oi2feqs0g.apps.googleusercontent.com',
  );

  static bool get isConfigured => serverClientId.trim().isNotEmpty;
}
