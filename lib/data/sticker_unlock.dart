import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Store pages shared to open the stickers. Each phone shares its own store.
abstract final class DearlyStoreLinks {
  static const androidPackage = 'com.dearly.quoteswidget';

  /// Numeric App Store id from App Store Connect (App Information → Apple ID).
  static const appStoreId = '6827842803';

  static const playStore =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  /// Dearly's App Store page, as shared from the widget decorator. No
  /// country in the path, so it opens the viewer's own store.
  static const appStore = 'https://apps.apple.com/app/id$appStoreId';

  /// The link for this phone's own store.
  static String get forThisPhone =>
      defaultTargetPlatform == TargetPlatform.iOS ? appStore : playStore;
}

/// Free users open the decorator stickers for good by sharing Dearly's store
/// link with a friend (not the room invite code). Subscribers never need it.
///
/// Kept on the phone and on the account (`users/{uid}.stickerShareUnlocked`),
/// so a reinstall or a new phone signed in to the same account keeps it.
class StickerUnlock extends ChangeNotifier {
  static const _prefsKey = 'sticker_share_unlocked';
  static const _cloudField = 'stickerShareUnlocked';

  bool _unlocked = false;
  bool get unlocked => _unlocked;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefsKey) ?? false;
    if (saved == _unlocked) return;
    _unlocked = saved;
    notifyListeners();
  }

  /// Opens the stickers for good. Called after the share sheet sent the link.
  Future<void> unlock() async {
    if (!_unlocked) {
      _unlocked = true;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    }
    await _writeCloud();
  }

  /// Takes an unlock this account earned on another phone, and records one
  /// earned here before the account was signed in.
  Future<void> syncFromCloud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final cloud = snap.data()?[_cloudField] == true;
      if (cloud && !_unlocked) {
        _unlocked = true;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefsKey, true);
      } else if (!cloud && _unlocked) {
        await _writeCloud();
      }
    } catch (e) {
      debugPrint('StickerUnlock.syncFromCloud: $e');
    }
  }

  Future<void> _writeCloud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {_cloudField: true},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('StickerUnlock._writeCloud: $e');
    }
  }
}

final stickerUnlock = StickerUnlock();
