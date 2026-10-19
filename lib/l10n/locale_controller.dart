import 'package:flutter/foundation.dart';

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

  AppLanguage _language;

  AppLanguage get language => _language;
  bool get isKorean => _language == AppLanguage.korean;

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  void setById(String id) => setLanguage(AppLanguage.byId(id));
}

final localeController = LocaleController();
