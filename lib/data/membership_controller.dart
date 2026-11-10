import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium access. RevenueCat entitlement `premium` sets this and keeps it.
/// New installs also get a 3-day content trial (quotes + widget decorate).
class MembershipController extends ChangeNotifier {
  static const _prefsKey = 'premium_active';
  static const _firstOpenKey = 'membership_first_open_ms';
  static const _trialNoticeKey = 'membership_trial_notice_shown';

  /// Length of the post-install content trial.
  static const trialDays = 3;

  bool _isPremium = false;
  DateTime? _firstOpenAt;
  bool _trialNoticePending = false;
  Timer? _trialEndTimer;

  /// Paid / restored subscription only (not the free trial).
  bool get isPremium => _isPremium;

  /// Quotes + decorate unlock: paid premium or still inside the free trial.
  bool get hasPremiumContent => _isPremium || isInFreeTrial;

  bool get isInFreeTrial {
    final start = _firstOpenAt;
    if (start == null) return false;
    final end = start.add(const Duration(days: trialDays));
    return DateTime.now().isBefore(end);
  }

  static const String freeCategoryId = 'daily';

  bool isCategoryFree(String id) => id == freeCategoryId;

  bool canAccess(String categoryId) =>
      hasPremiumContent || isCategoryFree(categoryId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefsKey) ?? false;
    final rawMs = prefs.getInt(_firstOpenKey);
    var changed = false;

    if (rawMs == null) {
      final now = DateTime.now();
      _firstOpenAt = now;
      await prefs.setInt(_firstOpenKey, now.millisecondsSinceEpoch);
      if (!(prefs.getBool(_trialNoticeKey) ?? false)) {
        _trialNoticePending = true;
      }
      changed = true;
    } else {
      _firstOpenAt = DateTime.fromMillisecondsSinceEpoch(rawMs);
    }

    if (saved != _isPremium) {
      _isPremium = saved;
      changed = true;
    }
    _scheduleTrialEnd();
    if (changed) notifyListeners();
  }

  /// The free trial can end while the app is open; tell listeners so premium
  /// looks (backgrounds, fonts) switch back right away.
  void _scheduleTrialEnd() {
    _trialEndTimer?.cancel();
    final start = _firstOpenAt;
    if (start == null || !isInFreeTrial) return;
    final left =
        start.add(const Duration(days: trialDays)).difference(DateTime.now());
    _trialEndTimer = Timer(left + const Duration(seconds: 1), notifyListeners);
  }

  /// Whether the install trial welcome dialog should still be shown.
  Future<bool> shouldShowTrialNotice() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_trialNoticeKey) ?? false) return false;
    if (_trialNoticePending) return true;
    // First open recorded but notice never confirmed.
    return _firstOpenAt != null && isInFreeTrial && !_isPremium;
  }

  /// Call after the user dismisses the trial welcome dialog.
  Future<void> markTrialNoticeShown() async {
    _trialNoticePending = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trialNoticeKey, true);
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
