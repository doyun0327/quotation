import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:quotation/screens/dday_accept_invite_screen.dart';

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
