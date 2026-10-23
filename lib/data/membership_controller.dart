import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium access. RevenueCat entitlement `premium` sets this and keeps it.
class MembershipController extends ChangeNotifier {
  static const _prefsKey = 'premium_active';

  bool _isPremium = false;

  bool get isPremium => _isPremium;

  static const String freeCategoryId = 'daily';

  bool isCategoryFree(String id) => id == freeCategoryId;

  bool canAccess(String categoryId) =>
      _isPremium || isCategoryFree(categoryId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefsKey) ?? false;
    if (saved == _isPremium) return;
    _isPremium = saved;
    notifyListeners();
  }

  void setPremium(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_prefsKey, value);
    });
  }

  void togglePremium() => setPremium(!_isPremium);
}

final membershipController = MembershipController();
