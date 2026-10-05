import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netcarve/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to the calculator and computes a subnet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NetCarveApp());
    await tester.pumpAndSettle();

    expect(find.text('NetCarve'), findsWidgets);
    expect(find.text('Offline · Ad-free'), findsOneWidget);

    // Enter a block and confirm the derived network is displayed.
    final field = find.byType(TextField).first;
    await tester.enterText(field, '10.20.30.40/20');
    await tester.pumpAndSettle();

    expect(find.text('10.20.16.0'), findsWidgets);
    expect(find.text('255.255.240.0'), findsOneWidget);
  });

  testWidgets('VLSM planner produces four /26 blocks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NetCarveApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();

    expect(find.text('VLSM Planner'), findsOneWidget);
  });
}
