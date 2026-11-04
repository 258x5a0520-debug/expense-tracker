import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders Expense Tracker title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    // Verify that the title text is rendered.
    expect(find.text('Expense Tracker'), findsWidgets);
  });

  test('Expense model serialization test', () {
    final original = Expense(
      id: '101',
      title: 'Lunch',
      amount: 150.0,
      category: 'Food',
      date: DateTime(2026, 11, 4),
      note: 'Cafeteria lunch',
    );
    final json = original.toJson();
    final restored = Expense.fromJson(json);

    expect(restored.id, '101');
    expect(restored.title, 'Lunch');
    expect(restored.amount, 150.0);
    expect(restored.category, 'Food');
  });
}
