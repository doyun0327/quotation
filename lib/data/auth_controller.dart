import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quotation/config/google_auth_config.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/together_test_room.dart';
import 'package:quotation/data/user_profile_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.firebaseLinked = false,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool firebaseLinked;

  factory AuthUser.fromFirebase(User user) {
    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      firebaseLinked: true,
    );
  }

  factory AuthUser.fromGoogle(GoogleSignInAccount account) {
    return AuthUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      firebaseLinked: false,
    );
  }

  static AuthUser? fromPrefs(SharedPreferences prefs) {
    final id = prefs.getString(_prefsId);
    final email = prefs.getString(_prefsEmail);
    if (id == null || email == null) return null;
    return AuthUser(
      id: id,
      email: email,
      displayName: prefs.getString(_prefsName),
      photoUrl: prefs.getString(_prefsPhoto),
      firebaseLinked: prefs.getString(_prefsFirebase) == '1',
    );
  }
}

const _prefsId = 'auth_google_id';
const _prefsEmail = 'auth_google_email';
const _prefsName = 'auth_google_name';
const _prefsPhoto = 'auth_google_photo';
const _prefsFirebase = 'auth_firebase_linked';

/// In-app native Google account picker only — no Custom Tabs / Firebase web page.
class AuthController extends ChangeNotifier {
  AuthUser? _user;
  bool _busy = false;
  bool _ready = false;
  String? _lastError;
  String? _lastErrorDetail;
  bool _startedCloud = false;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<User?>? _authSub;

  AuthUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _busy;
  bool get isReady => _ready;
  String? get lastError => _lastError;
  String? get lastErrorDetail => _lastErrorDetail;

  GoogleSignIn get _client {
    return _googleSignIn ??= GoogleSignIn(
      scopes: const <String>['email', 'profile'],
      // Web client from Firebase Auth → Google (for idToken → Firebase).
      // Native account sheet stays in-app; does not open dearly-cf730 web page.
      serverClientId: GoogleAuthConfig.serverClientId,
    );
  }

  Future<void> initialize() async {
    if (_ready) return;

    final prefs = await SharedPreferences.getInstance();
    _user = AuthUser.fromPrefs(prefs);
    notifyListeners();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
      if (fbUser != null) {
        await _setUser(AuthUser.fromFirebase(fbUser));
        unawaited(DdayCloudSync.start());
      }
    });

    try {
      final existingFb = FirebaseAuth.instance.currentUser;
      if (existingFb != null && !existingFb.isAnonymous) {
        await _setUser(AuthUser.fromFirebase(existingFb));
      }
      await ensureAnonymous();
    } catch (e) {
      debugPrint('Auth init: $e');
      await ensureAnonymous();
    }

    _ready = true;
    notifyListeners();
    unawaited(togetherTestRoom.restoreIfEnabled());
  }

  /// Test sessions skip the Google sheet and use anonymous Firebase auth.
  Future<bool> ensureFirebaseSession() async {
    return ensureAnonymous();
  }

  Future<bool> ensureAnonymous() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      if (!_startedCloud) {
        _startedCloud = true;
        unawaited(DdayCloudSync.start());
      }
      return true;
    }
    try {
      await FirebaseAuth.instance.signInAnonymously();
      _startedCloud = true;
      unawaited(DdayCloudSync.start());
      return true;
    } catch (e) {
      debugPrint('Anonymous sign-in: $e');
      _lastError = 'failed';
      _lastErrorDetail = e.toString();
      return false;
    }
  }

  Future<bool> signIn() async {
    if (_busy) return false;
    _busy = true;
    _lastError = null;
    _lastErrorDetail = null;
    notifyListeners();

    try {
      if (!_ready) await initialize();

      // Force account picker in the native Google UI (still in-app sheet).
      try {
        await _client.signOut();
      } catch (_) {}

      final account = await _client.signIn();
      if (account == null) {
        _lastError = 'canceled';
        return false;
      }

      final linked = await _linkFirebase(account);
      if (!linked) {
        // Profile still saved so settings login isn't a hard failure.
        await _setUser(AuthUser.fromGoogle(account));
      }
      return true;
    } on PlatformException catch (e) {
      final code = e.code;
      final message = e.message ?? '';
      _lastErrorDetail = '$code $message'.trim();
      debugPrint('GoogleSignIn PlatformException: $_lastErrorDetail');
      if (code == 'sign_in_canceled' || message.contains('canceled')) {
        _lastError = 'canceled';
      } else if (code == 'sign_in_failed' ||
          message.contains('10:') ||
          message.contains('DEVELOPER_ERROR')) {
        _lastError = 'config';
      } else {
        _lastError = 'failed';
      }
      return false;
    } catch (e) {
      _lastError = 'failed';
      _lastErrorDetail = e.toString();
      debugPrint('GoogleSignIn error: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Exchange Google tokens for Firebase session (no browser).
  Future<bool> _linkFirebase(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    if (auth.idToken == null && auth.accessToken == null) {
      debugPrint('Google auth missing tokens');
      return false;
    }
    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = result.user;
      if (fbUser == null) return false;
      await _setUser(AuthUser.fromFirebase(fbUser));
      await UserProfileSync.upsertCurrentUser();
      await DdayCloudSync.start();
      return true;
    } catch (e) {
      debugPrint('Firebase credential sign-in failed: $e');
      _lastErrorDetail = e.toString();
      return false;
    }
  }

  Future<void> signOut() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await DdayCloudSync.stop();
      await FirebaseAuth.instance.signOut();
      try {
        await _client.signOut();
        await _client.disconnect();
      } catch (_) {}
    } catch (e) {
      debugPrint('sign-out: $e');
    }
    await _clearUser();
    _busy = false;
    notifyListeners();
  }

  Future<void> _setUser(AuthUser user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsId, user.id);
    await prefs.setString(_prefsEmail, user.email);
    await prefs.setString(_prefsFirebase, user.firebaseLinked ? '1' : '0');
    if (user.displayName != null) {
      await prefs.setString(_prefsName, user.displayName!);
    } else {
      await prefs.remove(_prefsName);
    }
    if (user.photoUrl != null) {
      await prefs.setString(_prefsPhoto, user.photoUrl!);
    } else {
      await prefs.remove(_prefsPhoto);
    }
    notifyListeners();
  }

  Future<void> _clearUser() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsId);
    await prefs.remove(_prefsEmail);
    await prefs.remove(_prefsName);
    await prefs.remove(_prefsPhoto);
    await prefs.remove(_prefsFirebase);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authController = AuthController();
