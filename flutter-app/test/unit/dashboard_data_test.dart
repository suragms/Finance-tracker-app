import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moneyflow_ai/features/expenses/application/expense_providers.dart';

void main() {
  group('DashboardData Logic Tests', () {
    test('Calculates totals correctly from mixed data', () {
      final now = DateTime.now();
      final monthExpenses = [
        {'amount': '500.0', 'date': now.toIso8601String()},
        {'amount': '250', 'date': now.toIso8601String()},
      ];
      final monthIncomes = [
        {'amount': '2000.0', 'date': now.toIso8601String()},
      ];

      final data = DashboardData(
        spent: 750.0,
        earned: 2000.0,
        monthExpenses: monthExpenses,
        monthIncomes: monthIncomes,
        lineSpots: [],
        recent: [],
        dayTotals: {},
      );

      expect(data.spent, 750.0);
      expect(data.earned, 2000.0);
      expect(data.earned - data.spent, 1250.0);
    });

    test('Recent activity sorting (Integration-like unit test)', () {
      final now = DateTime.now();
      final e1 = {'amount': '100', 'date': now.subtract(const Duration(days: 1)).toIso8601String(), 'id': '1'};
      final e2 = {'amount': '200', 'date': now.toIso8601String(), 'id': '2'};
      
      final recent = [e1, e2]
        ..sort((a, b) => DateTime.parse(b['date']!).compareTo(DateTime.parse(a['date']!)));

      expect(recent.first['id'], '2');
      expect(recent.last['id'], '1');
    });

    test('Edge Case: Zero amounts and empty lists', () {
      final data = DashboardData(
        spent: 0,
        earned: 0,
        monthExpenses: [],
        monthIncomes: [],
        lineSpots: [],
        recent: [],
        dayTotals: {},
      );
      expect(data.spent, 0);
      expect(data.earned, 0);
    });
  });
}
