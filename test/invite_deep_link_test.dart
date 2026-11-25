import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotation/data/invite_deep_link.dart';
import 'package:quotation/data/terms_consent.dart';

class _Pushes extends NavigatorObserver {
  int count = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The first route is the home screen.
    if (previousRoute != null) count++;
  }
}

void main() {
  testWidgets('invite waits for the terms and opens once', (tester) async {
    TermsConsent.accepted = false;
    final key = GlobalKey<NavigatorState>();
    final pushes = _Pushes();
    InviteDeepLink.navigatorKey = key;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [pushes],
        home: const SizedBox(),
      ),
    );

    final link = Uri.parse('dearly://invite/ABC234');
    InviteDeepLink.handle(link);
    InviteDeepLink.handle(link);
    await tester.pump(const Duration(minutes: 11));
    expect(pushes.count, 0);

    TermsConsent.accepted = true;
    await tester.pump(const Duration(seconds: 1));
    expect(pushes.count, 1);
  });
}
