import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

final recurringApiProvider = Provider((ref) => RecurringApi(ref.read(dioProvider)));

class RecurringApi {
  RecurringApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> create({
    required double amount,
    required String frequency,
    required String title,
    required String categoryId,
    String? accountId,
    String? note,
    String? nextDateIso,
    String mode = 'auto_create',
  }) async {
    final res = await _dio.post('/recurring', data: {
      'amount': amount,
      'frequency': frequency,
      'title': title,
      'categoryId': categoryId,
      'accountId': accountId,
      'note': note,
      'nextDate': nextDateIso,
      'mode': mode,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> setActive(String id, bool active) async {
    await _dio.patch('/recurring/$id/active', data: {'active': active});
  }

  Future<void> markPaid(String id) async {
    await _dio.post('/recurring/$id/mark-paid');
  }

  Future<Response> rawListResponse() => _dio.get('/recurring');
}
