import 'package:flutter_test/flutter_test.dart';
import 'package:moneyflow_ai/core/services/smart_categorization_service.dart';

void main() {
  group('SmartCategorizationService Tests', () {
    final mockCategories = [
      {'id': 'offline_cat_food', 'name': 'Food & Dining'},
      {'id': 'offline_cat_transport', 'name': 'Transport'},
      {'id': 'offline_cat_home', 'name': 'Home & Utilities'},
    ];

    test('Suggests food category for Swiggy/Zomato notes', () {
      expect(
        SmartCategorizationService.suggestCategoryId('Order from Swiggy', mockCategories),
        'offline_cat_food',
      );
      expect(
        SmartCategorizationService.suggestCategoryId('Dinner with friends', mockCategories),
        'offline_cat_food',
      );
    });

    test('Suggests transport category for Uber/Ola', () {
      expect(
        SmartCategorizationService.suggestCategoryId('Uber ride to office', mockCategories),
        'offline_cat_transport',
      );
    });

    test('Fallbacks to exact name match if keyword fails', () {
      expect(
        SmartCategorizationService.suggestCategoryId('Payment for Home & Utilities', mockCategories),
        'offline_cat_home',
      );
    });

    test('Returns null for empty or unknown notes', () {
      expect(
        SmartCategorizationService.suggestCategoryId('', mockCategories),
        isNull,
      );
      expect(
        SmartCategorizationService.suggestCategoryId('Random transaction', mockCategories),
        isNull,
      );
    });

    test('Case insensitivity check', () {
      expect(
        SmartCategorizationService.suggestCategoryId('UBER RIDE', mockCategories),
        'offline_cat_transport',
      );
    });
  });
}
