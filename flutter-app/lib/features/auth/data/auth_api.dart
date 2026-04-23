import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class MoneyFlowUser {
  const MoneyFlowUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory MoneyFlowUser.fromJson(Map<String, dynamic> json) {
    return MoneyFlowUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

typedef AuthResponse = ({
  String access,
  String refresh,
  String? sessionId,
  MoneyFlowUser? user,
});

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthResponse> login(
    String email,
    String password,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    return _tokensFrom(res.data);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    return _tokensFrom(res.data);
  }

  AuthResponse _tokensFrom(Map<String, dynamic>? raw) {
    final data = unwrapApiMap(raw) ?? raw ?? <String, dynamic>{};
    final access = data['access'] as String? ?? '';
    final refresh = data['refresh'] as String? ?? '';
    final sessionId = data['sessionId'] as String?;
    
    if (access.isEmpty) throw StateError('No access token in response');

    MoneyFlowUser? user;
    final userJson = data['user'];
    if (userJson is Map<String, dynamic>) {
      user = MoneyFlowUser.fromJson(userJson);
    }

    return (
      access: access,
      refresh: refresh,
      sessionId: sessionId,
      user: user,
    );
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);
