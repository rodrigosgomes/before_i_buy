import 'package:before_i_buy_mobile/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding gates the creator home', (tester) async {
    await tester.pumpWidget(const BeforeIBuyApp());
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Um pouco de espaço antes de decidir'), findsNothing);
  });
}
