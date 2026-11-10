import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/terms_consent.dart';
import 'package:quotation/screens/dday_accept_invite_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Listens for `dearly://invite/{code}` and HTTPS invite URLs.
class InviteDeepLink {
  InviteDeepLink._();

  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> start(GlobalKey<NavigatorState> key) async {
    navigatorKey = key;
    await _sub?.cancel();
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      debugPrint('InviteDeepLink initial: $e');
    }
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('InviteDeepLink stream: $e'),
    );
    unawaited(_checkInstallInvite());
  }

  static const _installCheckedKey = 'install_invite_checked_v1';
  static const _pinChannel =
      MethodChannel('com.quotation.quotation/widget_pin');

  /// An invite link that sent someone to the store: Android gets the code
  /// back from Play ("invite_code=ABC123"), iPhone from the clipboard the
  /// invite page filled ("Dearly 초대 코드 ABC123"). Checked once, and only
  /// on a fresh install, so updates never read anyone's clipboard.
  static Future<void> _checkInstallInvite() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_installCheckedKey) == true) return;
      await prefs.setBool(_installCheckedKey, true);
      if (characterController.hasPicked || ddayController.items.isNotEmpty) {
        return;
      }
      String? code;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final referrer =
            await _pinChannel.invokeMethod<String>('installReferrer') ?? '';
        code = RegExp(r'invite_code=([A-Za-z0-9]{6})')
            .firstMatch(Uri.decodeComponent(referrer))
            ?.group(1);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // hasStrings does not show iOS's paste prompt; getData does.
        if (!await Clipboard.hasStrings()) return;
        final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
        code = RegExp(r'Dearly 초대 코드 ([A-Za-z0-9]{6})')
            .firstMatch(text ?? '')
            ?.group(1);
      }
      if (code == null) return;
      // The terms dialog comes first; the invite opens right after it.
      for (var i = 0; i < 600 && !TermsConsent.accepted; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (!TermsConsent.accepted) return;
      _handle(Uri.parse('dearly://invite/${code.toUpperCase()}'));
    } catch (e) {
      debugPrint('InviteDeepLink install: $e');
    }
  }

  static void _handle(Uri uri) {
    final code = extractCode(uri);
    if (code == null) return;
    final nav = navigatorKey?.currentState;
    if (nav == null) {
      // Retry shortly once MaterialApp is up.
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        navigatorKey?.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => DdayAcceptInviteScreen(initialCode: code),
          ),
        );
      });
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => DdayAcceptInviteScreen(initialCode: code),
      ),
    );
  }

  static String? extractCode(Uri uri) {
    // dearly://invite/ABC123
    if (uri.scheme == 'dearly' && uri.host == 'invite') {
      final code = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : uri.path.replaceAll('/', '');
      return code.isEmpty ? null : code.toUpperCase();
    }
    // https://dearly-cf730.web.app/invite/ABC123
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'invite') {
      return uri.pathSegments[1].toUpperCase();
    }
    if (uri.pathSegments.length == 1 &&
        uri.pathSegments.first.length == 6) {
      return uri.pathSegments.first.toUpperCase();
    }
    return null;
  }
}
