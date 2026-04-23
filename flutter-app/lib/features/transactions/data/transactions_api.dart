import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class TransactionsApi {
  TransactionsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createTransaction({
    required String type,
    required double amount,
    String? categoryId,
    required String accountId,
    String? toAccountId,
    String? note,
    required String dateIso,
  }) async {
    final res = await _dio.post<dynamic>(
      '/transactions',
      data: {
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'to_account_id': toAccountId,
        'note': note,
        'date': dateIso,
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }
}

final transactionsApiProvider = Provider<TransactionsApi>(
  (ref) => TransactionsApi(ref.watch(dioProvider)),
);
