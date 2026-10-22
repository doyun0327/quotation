import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  korean(id: 'ko', labelKo: '한국어', labelEn: 'Korean'),
  english(id: 'en', labelKo: '영어', labelEn: 'English');

  const AppLanguage({
    required this.id,
    required this.labelKo,
    required this.labelEn,
  });

  final String id;
  final String labelKo;
  final String labelEn;

  String label(AppLanguage current) =>
      current == AppLanguage.korean ? labelKo : labelEn;

  static AppLanguage byId(String id) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.id == id,
      orElse: () => AppLanguage.korean,
    );
  }
}

class LocaleController extends ChangeNotifier {
  LocaleController({AppLanguage? initial})
      : _language = initial ?? AppLanguage.korean;

  static const _prefsKey = 'app_language';

  AppLanguage _language;

  AppLanguage get language => _language;
  bool get isKorean => _language == AppLanguage.korean;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return;
    final next = AppLanguage.byId(saved);
    if (next == _language) return;
    _language = next;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefsKey, language.id);
    });
  }

  void setById(String id) => setLanguage(AppLanguage.byId(id));
}

final localeController = LocaleController();
