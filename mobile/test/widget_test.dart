import 'package:flutter_test/flutter_test.dart';
import 'package:mine_guardian/core/network/api_client.dart';
import 'package:mine_guardian/main.dart';

void main() {
  testWidgets('MineGuardian smoke test', (WidgetTester tester) async {
    final apiClient = ApiClient();
    await tester.pumpWidget(MineGuardianApp(apiClient: apiClient));
    expect(find.byType(MineGuardianApp), findsOneWidget);
  });
}
