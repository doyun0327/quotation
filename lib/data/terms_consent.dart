import 'package:shared_preferences/shared_preferences.dart';

/// Whether the person accepted the terms, which Play requires before anyone
/// can write a nickname, cheer, bubble or room name. Raise [_key]'s version
/// when a change to the terms needs everyone to agree again.
abstract final class TermsConsent {
  static const _key = 'ugc_terms_accepted_v1';

  static bool accepted = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accepted = prefs.getBool(_key) ?? false;
  }

  static Future<void> accept() async {
    accepted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
