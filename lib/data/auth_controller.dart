import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quotation/config/google_auth_config.dart';
import 'package:quotation/data/cloud_consent.dart';
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
  bool _sessionStarted = false;
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

  /// Signed in with Apple and the email is a "Hide My Email" relay (or none),
  /// so the address means nothing to the user.
  bool get hidesAppleEmail {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null || fb.isAnonymous) return false;
    final viaApple =
        fb.providerData.any((info) => info.providerId == 'apple.com');
    if (!viaApple) return false;
    final email = (googleEmail ?? '').toLowerCase();
    return email.isEmpty || email.endsWith('@privaterelay.appleid.com');
  }

  /// Firebase uid for shared-room ordering. Stable before sign-in too.
  String get viewerUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    return 'local';
  }

  /// Every id this phone has used for the signed-in person.
  Set<String> get myIds => {
        viewerUid,
        if (FirebaseAuth.instance.currentUser?.uid case final uid?) uid,
        'local',
      };

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
  bool get hasCloudConsent => CloudConsent.accepted;

  GoogleSignIn get _client {
    return _googleSignIn ??= GoogleSignIn(
      // email is enough. A bare "profile" scope makes Android Sign-In fail
      // with ApiException 10. Name and photo still come from the account.
      scopes: const <String>['email'],
      // Web client from Firebase Auth → Google (for idToken → Firebase).
      // Native account sheet stays in-app; does not open dearly-cf730 web page.
      serverClientId: GoogleAuthConfig.serverClientId,
    );
  }

  Future<void> initialize() async {
    if (_ready) return;

    await CloudConsent.load();
    final prefs = await SharedPreferences.getInstance();
    _user = AuthUser.fromPrefs(prefs);
    final saved = prefs.getString(_prefsNickname)?.trim();
    final legacy = prefs.getString(_prefsName)?.trim();
    _nickname = (saved != null && saved.isNotEmpty)
        ? saved
        : (legacy != null && legacy.isNotEmpty ? legacy : null);
    notifyListeners();

    // Friends and widgets sync through Firebase without a login prompt.
    if (!CloudConsent.accepted) {
      await CloudConsent.accept();
    }
    await _startCloudSession();

    _ready = true;
    notifyListeners();
  }

  /// After the person agrees to the Firebase disclosure.
  Future<void> acceptCloudDisclosure() async {
    await CloudConsent.accept();
    await _startCloudSession();
    notifyListeners();
  }

  /// Keeps quotes and widgets on the device and does not open a Firebase session.
  Future<void> declineCloudDisclosure() async {
    await CloudConsent.decline();
    await _stopRemoteSession();
    notifyListeners();
  }

  Future<void> _startCloudSession({bool restoreGoogle = true}) async {
    if (!CloudConsent.accepted || _sessionStarted) return;
    _sessionStarted = true;

    _authSub = FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
      if (!CloudConsent.accepted) return;
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
      if (restoreGoogle && googleEmail == null) {
        await _restoreGoogleAccount();
      }
    } catch (e) {
      debugPrint('Auth init: $e');
      await ensureAnonymous();
    }
    unawaited(togetherTestRoom.restoreIfEnabled());
  }

  Future<void> _stopRemoteSession() async {
    _sessionStarted = false;
    _startedCloud = false;
    await _authSub?.cancel();
    _authSub = null;
    try {
      await DdayCloudSync.stop();
      await FirebaseAuth.instance.signOut();
      await _client.signOut();
    } catch (e) {
      debugPrint('stop remote session: $e');
    }
  }

  /// Test sessions skip the Google sheet and use anonymous Firebase auth.
  Future<bool> ensureFirebaseSession() async {
    return ensureAnonymous();
  }

  Future<bool> ensureAnonymous() async {
    if (!CloudConsent.accepted) return false;
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
      if (!CloudConsent.accepted) {
        await CloudConsent.accept();
      }
      if (!_sessionStarted) {
        await _startCloudSession(restoreGoogle: false);
      }

      final account = await _client.signIn();
      if (account == null) {
        _lastError = 'canceled';
        return false;
      }

      final linked = await _linkFirebase(account);
      if (!linked) {
        _lastError ??= 'failed';
        return false;
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

  /// Sign in with Apple is offered on iPhone/iPad only (native sheet).
  static bool get isAppleSignInAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Native Apple sheet → Firebase. Upgrades the anonymous user when possible.
  Future<bool> signInWithApple() async {
    if (_busy) return false;
    _busy = true;
    _signingIn = true;
    _lastError = null;
    _lastErrorDetail = null;
    notifyListeners();

    try {
      if (!_ready) await initialize();

      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final current = FirebaseAuth.instance.currentUser;
      UserCredential result;
      if (current != null && current.isAnonymous) {
        try {
          result = await current.linkWithProvider(provider);
        } on FirebaseAuthException catch (e) {
          // This Apple ID already has a Firebase user. Switch to it.
          final existing = e.credential;
          if (e.code != 'credential-already-in-use' || existing == null) {
            rethrow;
          }
          result = await FirebaseAuth.instance.signInWithCredential(existing);
        }
      } else {
        result = await FirebaseAuth.instance.signInWithProvider(provider);
      }

      final fbUser = result.user;
      if (fbUser == null) {
        _lastError = 'failed';
        return false;
      }
      // Apple shares the name only on the very first authorization.
      final appleName = result.additionalUserInfo?.profile?['name'];
      if ((fbUser.displayName ?? '').trim().isEmpty && appleName is String) {
        try {
          await fbUser.updateDisplayName(appleName);
        } catch (_) {}
      }
      await _setUser(
        AuthUser.fromFirebase(FirebaseAuth.instance.currentUser ?? fbUser),
      );
      await UserProfileSync.upsertCurrentUser();
      await DdayCloudSync.start();
      return true;
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? '';
      _lastErrorDetail = '${e.code} $message'.trim();
      debugPrint('AppleSignIn FirebaseAuthException: $_lastErrorDetail');
      // ASAuthorizationError.canceled (1001) when the sheet is dismissed.
      if (e.code.contains('cancel') ||
          message.contains('1001') ||
          message.toLowerCase().contains('cancel')) {
        _lastError = 'canceled';
      } else if (e.code == 'operation-not-allowed' ||
          e.code == 'invalid-credential' ||
          message.contains('1000')) {
        _lastError = 'config';
      } else {
        _lastError = 'failed';
      }
      return false;
    } catch (e) {
      _lastError = 'failed';
      _lastErrorDetail = e.toString();
      debugPrint('AppleSignIn error: $e');
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
    if (auth.idToken == null) {
      debugPrint('Google auth missing idToken');
      _lastError = 'config';
      _lastErrorDetail = 'missing idToken';
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
          const switchCodes = {
            'credential-already-in-use',
            'email-already-in-use',
            'provider-already-linked',
            'account-exists-with-different-credential',
          };
          debugPrint('linkWithCredential: ${e.code} ${e.message}');
          if (switchCodes.contains(e.code)) {
            result = await FirebaseAuth.instance.signInWithCredential(
              e.credential ?? credential,
            );
          } else if (e.code == 'unknown' || e.code == 'internal-error') {
            await FirebaseAuth.instance.signOut();
            result = await FirebaseAuth.instance.signInWithCredential(credential);
          } else {
            rethrow;
          }
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
    } on FirebaseAuthException catch (e) {
      _lastError = e.code == 'invalid-credential' || e.code == 'operation-not-allowed'
          ? 'config'
          : 'failed';
      _lastErrorDetail = '${e.code} ${e.message ?? ''}'.trim();
      debugPrint('Firebase credential sign-in failed: $_lastErrorDetail');
      return false;
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

  /// Deletes the signed-in Firebase user, profile, and cloud room data.
  /// A Google or Apple session is required. Anonymous-only sessions are not
  /// deleted here, so a logged-out tap cannot wipe the wrong account.
  Future<bool> deleteAccount() async {
    if (_busy) return false;
    _busy = true;
    _lastError = null;
    _lastErrorDetail = null;
    notifyListeners();
    try {
      if (!_ready) await initialize();
      if (!CloudConsent.accepted) {
        await CloudConsent.accept();
      }
      if (!_sessionStarted) {
        await _startCloudSession(restoreGoogle: false);
      }

      var user = await _userForDeletion();
      if (user == null) {
        _lastError = 'failed';
        return false;
      }

      final lastSignIn = user.metadata.lastSignInTime;
      final stale = lastSignIn == null ||
          DateTime.now().difference(lastSignIn) > const Duration(minutes: 5);
      if (stale) {
        await _reauthenticate(user);
        user = FirebaseAuth.instance.currentUser ?? user;
      }

      await UserProfileSync.deleteRemoteAccount(user.uid);
      await _deleteAuthUser(user);

      await _stopRemoteSession();
      try {
        await _client.disconnect();
      } catch (_) {}
      await _clearUser();
      await CloudConsent.accept();
      // Do not restore the Google account that was just deleted.
      await _startCloudSession(restoreGoogle: false);
      return true;
    } catch (e) {
      debugPrint('deleteAccount: $e');
      _lastError = 'failed';
      _lastErrorDetail = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Google/Apple Firebase user to delete. Links Google when the current
  /// session is still anonymous.
  Future<User?> _userForDeletion() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null && !current.isAnonymous) return current;
    final account = await _client.signIn();
    if (account == null) return null;
    final linked = await _linkFirebase(account);
    final user = FirebaseAuth.instance.currentUser;
    if (!linked || user == null || user.isAnonymous) return null;
    return user;
  }

  Future<void> _deleteAuthUser(User user) async {
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      await _reauthenticate(user);
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh == null) rethrow;
      await fresh.delete();
    }
  }

  Future<void> _reauthenticate(User user) async {
    final ids = user.providerData.map((info) => info.providerId).toSet();
    if (ids.contains('apple.com') && !ids.contains('google.com')) {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      await user.reauthenticateWithProvider(provider);
      return;
    }
    final account = await _client.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'canceled',
      );
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Saves a friend-facing nickname and mirrors it to Firebase after consent.
  Future<bool> setNickname(String raw) async {
    final name = raw.trim();
    if (name.isEmpty || name.length > 16) return false;
    _nickname = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsNickname, name);
    notifyListeners();
    if (!CloudConsent.accepted) return true;
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
    if (!CloudConsent.accepted) return;
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
