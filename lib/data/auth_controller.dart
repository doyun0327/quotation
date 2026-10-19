import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  factory AuthUser.fromGoogle(GoogleSignInAccount account) {
    return AuthUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  Map<String, String> toPrefs() => {
        'id': id,
        'email': email,
        if (displayName != null) 'displayName': displayName!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
      };

  static AuthUser? fromPrefs(SharedPreferences prefs) {
    final id = prefs.getString(_prefsId);
    final email = prefs.getString(_prefsEmail);
    if (id == null || email == null) return null;
    return AuthUser(
      id: id,
      email: email,
      displayName: prefs.getString(_prefsName),
      photoUrl: prefs.getString(_prefsPhoto),
    );
  }
}

const _prefsId = 'auth_google_id';
const _prefsEmail = 'auth_google_email';
const _prefsName = 'auth_google_name';
const _prefsPhoto = 'auth_google_photo';

class AuthController extends ChangeNotifier {
  AuthUser? _user;
  bool _busy = false;
  bool _ready = false;
  String? _lastError;
  String? _lastErrorDetail;
  GoogleSignIn? _googleSignIn;

  AuthUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _busy;
  bool get isReady => _ready;
  String? get lastError => _lastError;
  String? get lastErrorDetail => _lastErrorDetail;

  GoogleSignIn get _client {
    // Local profile login only needs the Android OAuth client (package + SHA-1).
    // Passing a mismatched Web serverClientId commonly breaks Android with
    // DEVELOPER_ERROR / "canceled", so we omit it unless explicitly required later.
    return _googleSignIn ??= GoogleSignIn(
      scopes: const <String>['email', 'profile'],
    );
  }

  Future<void> initialize() async {
    if (_ready) return;

    final prefs = await SharedPreferences.getInstance();
    _user = AuthUser.fromPrefs(prefs);
    notifyListeners();

    try {
      final existing = await _client.signInSilently();
      if (existing != null) {
        await _setUser(AuthUser.fromGoogle(existing));
      }
    } catch (e) {
      debugPrint('Google silent sign-in: $e');
    }

    _ready = true;
    notifyListeners();
  }

  Future<bool> signIn() async {
    if (_busy) return false;
    _busy = true;
    _lastError = null;
    _lastErrorDetail = null;
    notifyListeners();

    try {
      if (!_ready) await initialize();

      final account = await _client.signIn();
      if (account == null) {
        _lastError = 'canceled';
        return false;
      }
      await _setUser(AuthUser.fromGoogle(account));
      return true;
    } on PlatformException catch (e) {
      // ApiException 10 = DEVELOPER_ERROR (SHA-1 / package / OAuth client).
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

  Future<void> signOut() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await _client.signOut();
      await _client.disconnect();
    } catch (e) {
      debugPrint('Google sign-out: $e');
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
    notifyListeners();
  }
}

final authController = AuthController();
