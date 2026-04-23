import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../../../core/providers.dart';

final recurringProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (kNoApiMode) {
    return const <Map<String, dynamic>>[];
  }
  final dio = ref.read(dioProvider);
  final res = await dio.get<dynamic>('/recurring');
  return List<Map<String, dynamic>>.from(res.data['data'] ?? const []);
});
