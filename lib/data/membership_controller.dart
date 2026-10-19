import 'package:flutter/foundation.dart';

/// In-memory membership flag until real billing is wired.
/// App restart resets to free.
class MembershipController extends ChangeNotifier {
  bool _isPremium = false;

  bool get isPremium => _isPremium;

  static const String freeCategoryId = 'daily';

  bool isCategoryFree(String id) => id == freeCategoryId;

  bool canAccess(String categoryId) =>
      _isPremium || isCategoryFree(categoryId);

  void setPremium(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    notifyListeners();
  }

  void togglePremium() => setPremium(!_isPremium);
}

final membershipController = MembershipController();
