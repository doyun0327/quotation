import 'package:flutter_test/flutter_test.dart';
import 'package:quotation/data/app_update_check.dart';

void main() {
  test('store version newer than install', () {
    expect(AppUpdateCheck.isNewer('1.0.3', '1.0.2'), isTrue);
    expect(AppUpdateCheck.isNewer('1.0.10', '1.0.9'), isTrue);
    expect(AppUpdateCheck.isNewer('1.1', '1.0.15'), isTrue);
  });

  test('same or older store version', () {
    expect(AppUpdateCheck.isNewer('1.0.2', '1.0.2'), isFalse);
    expect(AppUpdateCheck.isNewer('1.0.2', '1.0.15'), isFalse);
    expect(AppUpdateCheck.isNewer('1.0', '1.0.0'), isFalse);
  });
}
