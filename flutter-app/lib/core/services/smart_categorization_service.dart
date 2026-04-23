/// A service to suggest categories based on transaction notes/descriptions.
/// 
/// This implementation uses keyword matching but is structured to allow
/// future integration with ML models (e.g. TFLite or local inference).
class SmartCategorizationService {
  // Common keyword mapping for automatic categorization
  static final Map<String, List<String>> _keywords = {
    'offline_cat_food': [
      'food', 'dining', 'swiggy', 'zomato', 'restaurant', 'cafe', 'coffee', 
      'starbucks', 'lunch', 'dinner', 'breakfast', 'pizza', 'burger', 'kfc', 'mcdonalds'
    ],
    'offline_cat_transport': [
      'uber', 'ola', 'rapido', 'petrol', 'fuel', 'metro', 'bus', 'train', 
      'flight', 'air', 'ticket', 'taxi', 'parking', 'toll'
    ],
    'offline_cat_home': [
      'rent', 'electricity', 'water', 'gas', 'wifi', 'broadband', 'netflix', 
      'prime', 'grocery', 'bigbasket', 'blinkit', 'zepto', 'maintenance'
    ],
    'offline_cat_other': [
      'misc', 'gift', 'shopping', 'amazon', 'flipkart', 'myntra', 'clothing'
    ],
  };

  /// Predicts a category ID based on the provided [note].
  /// Returns null if no confident match is found.
  static String? suggestCategoryId(String note, List<Map<String, dynamic>> availableCategories) {
    if (note.trim().isEmpty) return null;
    
    final query = note.toLowerCase();
    
    // 1. Exact or keyword match
    for (final entry in _keywords.entries) {
      final catId = entry.key;
      final keywords = entry.value;
      
      if (keywords.any((kw) => query.contains(kw))) {
        // Verify the suggested category actually exists in the available list
        if (availableCategories.any((c) => c['id'] == catId)) {
          return catId;
        }
      }
    }
    
    // 2. Exact name match fallback
    for (final cat in availableCategories) {
      final name = cat['name']?.toString().toLowerCase() ?? '';
      if (name.isNotEmpty && query.contains(name)) {
        return cat['id']?.toString();
      }
    }

    return null;
  }

  /// ML-Ready Placeholder: In a real production app, we would load a 
  /// pre-trained model here and use it for inference.
  static Future<Map<String, double>> getMLConfidenceScores(String note) async {
    // This is where we would invoke a TFLite interpreter or similar
    return {};
  }
}
