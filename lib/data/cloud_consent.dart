import 'package:shared_preferences/shared_preferences.dart';

/// Whether the person agreed to send an account id, and on Google sign-in
/// an email and name, to Firebase.
enum CloudConsentChoice { unknown, accepted, declined }

abstract final class CloudConsent {
  static const _key = 'cloud_disclosure_choice';

  static CloudConsentChoice choice = CloudConsentChoice.unknown;

  static bool get accepted => choice == CloudConsentChoice.accepted;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    choice = switch (prefs.getString(_key)) {
      'accepted' => CloudConsentChoice.accepted,
      'declined' => CloudConsentChoice.declined,
      _ => CloudConsentChoice.unknown,
    };
  }

  static Future<void> accept() async {
    choice = CloudConsentChoice.accepted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, 'accepted');
  }

  static Future<void> decline() async {
    choice = CloudConsentChoice.declined;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, 'declined');
  }

  static Future<void> reset() async {
    choice = CloudConsentChoice.unknown;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
