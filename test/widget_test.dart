import 'package:flutter_test/flutter_test.dart';
import 'package:quotation/main.dart';

void main() {
  testWidgets('Home screen shows Daily Word title', (tester) async {
    await tester.pumpWidget(const QuotationApp());

    expect(find.text('DAILY WORD'), findsOneWidget);
    expect(find.text('오늘의 운세'), findsOneWidget);
    expect(find.text('어떤 문장을 읽고 싶나요?'), findsOneWidget);
    expect(find.text('위로와 응원'), findsOneWidget);
    expect(find.text('설정'), findsWidgets);
  });
}
