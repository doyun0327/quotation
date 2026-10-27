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

  factory AuthUser.fromFirebase(User user, {String? emailFallback}) {
    return AuthUser(
      id: user.uid,
      email: emailOf(user, fallback: emailFallback),
      displayName: user.displayName,
      photoUrl: user.photoURL,
      firebaseLinked: true,
    );
  }

  /// Firebase often leaves [User.email] empty; the Google provider still has it.
  static String emailOf(User user, {String? fallback}) {
    final direct = user.email?.trim() ?? '';
    if (direct.isNotEmpty) return direct;
    for (final info in user.providerData) {
      final email = info.email?.trim() ?? '';
      if (email.isNotEmpty) return email;
    }
    final extra = fallback?.trim() ?? '';
    return extra;
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
    final email = prefs.getString(_prefsEmail)?.trim() ?? '';
    if (id == null || email.isEmpty) return null;
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
const _prefsNickname = 'profile_nickname';
const _prefsPhoto = 'auth_google_photo';
const _prefsFirebase = 'auth_firebase_linked';

/// In-app native Google account picker only — no Custom Tabs / Firebase web page.
class AuthController extends ChangeNotifier {
  AuthUser? _user;
  String? _nickname;
  bool _busy = false;
  bool _signingIn = false;
  bool _ready = false;
  String? _lastError;
  String? _lastErrorDetail;
  bool _startedCloud = false;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<User?>? _authSub;

  AuthUser? get user => _user;
  bool get isSignedIn => _user != null;

  /// Gmail from a Google sign-in. Empty for anonymous sessions.
  String? get googleEmail {
    final saved = _user?.email.trim() ?? '';
    if (saved.isNotEmpty) return saved;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null || fb.isAnonymous) return null;
    final email = fb.email?.trim() ?? '';
    return email.isEmpty ? null : email;
  }

  /// Name shown to friends. Survives anonymous auth, which has no Google name.
  String? get nickname {
    final saved = _nickname?.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    final google = _user?.displayName?.trim();
    if (google != null && google.isNotEmpty) return google;
    return null;
  }
  bool get isBusy => _busy;
  bool get isSigningIn => _signingIn;
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
    final saved = prefs.getString(_prefsNickname)?.trim();
    final legacy = prefs.getString(_prefsName)?.trim();
    _nickname = (saved != null && saved.isNotEmpty)
        ? saved
        : (legacy != null && legacy.isNotEmpty ? legacy : null);
    notifyListeners();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
      if (fbUser == null || fbUser.isAnonymous) return;
      await _setUser(AuthUser.fromFirebase(fbUser));
      unawaited(DdayCloudSync.start());
    });

    try {
      final existingFb = FirebaseAuth.instance.currentUser;
      if (existingFb != null && !existingFb.isAnonymous) {
        await existingFb.reload();
        final fresh = FirebaseAuth.instance.currentUser ?? existingFb;
        await _setUser(AuthUser.fromFirebase(fresh));
      }
      await ensureAnonymous();
      if (googleEmail == null) {
        await _restoreGoogleAccount();
      }
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
    _signingIn = true;
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
      _signingIn = false;
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
      final current = FirebaseAuth.instance.currentUser;
      UserCredential result;
      if (current != null && current.isAnonymous) {
        try {
          result = await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          // This Google account already has a Firebase user. Switch to it.
          if (e.code != 'credential-already-in-use' &&
              e.code != 'email-already-in-use' &&
              e.code != 'provider-already-linked') {
            rethrow;
          }
          result = await FirebaseAuth.instance.signInWithCredential(credential);
        }
      } else {
        result = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      final fbUser = result.user;
      if (fbUser == null) return false;
      await _setUser(
        AuthUser.fromFirebase(fbUser, emailFallback: account.email),
      );
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

  /// Saves a friend-facing nickname and mirrors it to Firebase.
  Future<bool> setNickname(String raw) async {
    final name = raw.trim();
    if (name.isEmpty || name.length > 16) return false;
    await ensureAnonymous();
    try {
      final fb = FirebaseAuth.instance.currentUser;
      if (fb != null) {
        await fb.updateDisplayName(name);
        await fb.reload();
      }
    } catch (e) {
      debugPrint('updateDisplayName: $e');
    }
    _nickname = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsNickname, name);
    final current = _user;
    final fb = FirebaseAuth.instance.currentUser;
    if (current != null) {
      _user = AuthUser(
        id: current.id,
        email: current.email,
        displayName: name,
        photoUrl: current.photoUrl,
        firebaseLinked: current.firebaseLinked,
      );
    } else if (fb != null && !fb.isAnonymous) {
      _user = AuthUser(
        id: fb.uid,
        email: AuthUser.emailOf(fb),
        displayName: name,
        photoUrl: fb.photoURL,
        firebaseLinked: true,
      );
    }
    if (_user != null) {
      await prefs.setString(_prefsId, _user!.id);
      await prefs.setString(_prefsEmail, _user!.email);
    }
    notifyListeners();
    unawaited(UserProfileSync.syncDisplayName(name));
    return true;
  }

  Future<void> _setUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _nickname?.trim();
    final incoming = user.displayName?.trim();
    final name = (saved != null && saved.isNotEmpty)
        ? saved
        : (incoming != null && incoming.isNotEmpty ? incoming : null);
    if (name != null) {
      _nickname = name;
      await prefs.setString(_prefsNickname, name);
    }
    final incomingEmail = user.email.trim();
    final keptEmail = incomingEmail.isNotEmpty
        ? incomingEmail
        : (_user?.email.trim() ?? '');
    _user = AuthUser(
      id: user.id,
      email: keptEmail,
      displayName: name,
      photoUrl: user.photoUrl,
      firebaseLinked: user.firebaseLinked,
    );
    await prefs.setString(_prefsId, user.id);
    if (keptEmail.isNotEmpty) {
      await prefs.setString(_prefsEmail, keptEmail);
    }
    await prefs.setString(_prefsFirebase, user.firebaseLinked ? '1' : '0');
    if (name != null) {
      await prefs.setString(_prefsName, name);
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

  /// Brings back the Gmail address when Firebase only has an anonymous session.
  Future<void> _restoreGoogleAccount() async {
    try {
      final account = await _client.signInSilently();
      if (account == null || account.email.trim().isEmpty) return;
      await _setUser(AuthUser.fromGoogle(account));
      unawaited(_linkFirebase(account));
    } catch (e) {
      debugPrint('Google silent restore: $e');
    }
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
