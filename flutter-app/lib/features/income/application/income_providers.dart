import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';

final incomesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) {
  if (kNoApiMode) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }
  return ref.watch(ledgerDatabaseProvider).watchIncomesForList();
});
