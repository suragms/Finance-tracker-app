import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'ledger_database.g.dart';

/// Row lifecycle for optimistic offline writes.
enum LedgerSyncStatus {
  /// Matches server; safe to overwrite from pull.
  synced,

  /// Local edits not yet acknowledged by server.
  pendingPush,

  /// Delete queued; hidden from list until server confirms.
  pendingDelete,

  /// Server and client both changed the same entity; needs user resolution (sample: flagged in payload).
  conflict,
}

class CachedIncomes extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get clientRevisionAt => dateTime()();
  DateTimeColumn get lastKnownServerAt => dateTime().nullable()();
  DateTimeColumn get incomeSortDate => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get clientRevisionAt => dateTime()();
  DateTimeColumn get lastKnownServerAt => dateTime().nullable()();
  DateTimeColumn get expenseSortDate => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get clientRevisionAt => dateTime()();
  DateTimeColumn get lastKnownServerAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get monthKey => text()();
  TextColumn get payloadJson => text()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get clientRevisionAt => dateTime()();
  DateTimeColumn get lastKnownServerAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedRecurringExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get clientRevisionAt => dateTime()();
  DateTimeColumn get lastKnownServerAt => dateTime().nullable()();
  DateTimeColumn get nextDate => dateTime()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncOutbox extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get opCode => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

class LedgerKv extends Table {
  TextColumn get k => text()();
  TextColumn get v => text()();

  @override
  Set<Column<Object>> get primaryKey => {k};
}

QueryExecutor _defaultLedgerExecutor() {
  if (kIsWeb) {
    return driftDatabase(
      name: 'ledger_offline',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
  return driftDatabase(name: 'ledger_offline');
}

@DriftDatabase(
  tables: [
    CachedExpenses,
    CachedAccounts,
    CachedBudgets,
    SyncOutbox,
    LedgerKv,
    CachedIncomes,
    CachedRecurringExpenses,
  ],
)
class LedgerDatabase extends _$LedgerDatabase {
  LedgerDatabase([QueryExecutor? executor])
      : super(executor ?? _defaultLedgerExecutor());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(ledgerKv);
          }
          if (from < 3) {
            await m.createTable(cachedIncomes);
          }
          if (from < 4) {
            await m.createTable(cachedRecurringExpenses);
          }
        },
      );

  Stream<List<Map<String, dynamic>>> watchIncomesForList() {
    return (select(cachedIncomes)
          ..where(
            (t) =>
                t.syncStatus.isNotValue(LedgerSyncStatus.pendingDelete.index),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.incomeSortDate)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) =>
                    Map<String, dynamic>.from(jsonDecode(r.payloadJson) as Map),
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchExpensesForList() {
    return (select(cachedExpenses)
          ..where(
            (t) =>
                t.syncStatus.isNotValue(LedgerSyncStatus.pendingDelete.index),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.expenseSortDate)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) =>
                    Map<String, dynamic>.from(jsonDecode(r.payloadJson) as Map),
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchAccountsPayloads() {
    return (select(
      cachedAccounts,
    )..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) =>
                    Map<String, dynamic>.from(jsonDecode(r.payloadJson) as Map),
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchBudgetsForMonth(String monthKey) {
    return (select(cachedBudgets)
          ..where((t) => t.monthKey.equals(monthKey))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) =>
                    Map<String, dynamic>.from(jsonDecode(r.payloadJson) as Map),
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchRecurringExpenses() {
    return (select(cachedRecurringExpenses)
          ..where(
            (t) =>
                t.syncStatus.isNotValue(LedgerSyncStatus.pendingDelete.index),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.nextDate)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) =>
                    Map<String, dynamic>.from(jsonDecode(r.payloadJson) as Map),
              )
              .toList(),
        );
  }

  Future<void> upsertExpenseFromServer(
    Map<String, dynamic> row, {
    LedgerSyncStatus status = LedgerSyncStatus.synced,
  }) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = _parseIso(row['updatedAt'] as String?);
    final sort = _expenseSortDate(row);
    await into(cachedExpenses).insertOnConflictUpdate(
      CachedExpensesCompanion(
        id: Value(id),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(status.index),
        clientRevisionAt: Value(serverAt ?? DateTime.now().toUtc()),
        lastKnownServerAt: Value(serverAt),
        expenseSortDate: Value(sort),
      ),
    );
  }

  void batchUpsertExpense(Batch batch, Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = _parseIso(row['updatedAt'] as String?);
    final sort = _expenseSortDate(row);
    batch.insert(
      cachedExpenses,
      CachedExpensesCompanion(
        id: Value(id),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(LedgerSyncStatus.synced.index),
        clientRevisionAt: Value(serverAt ?? DateTime.now().toUtc()),
        lastKnownServerAt: Value(serverAt),
        expenseSortDate: Value(sort),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<Set<String>> getExpenseIdsToSkip(List<String> ids) async {
    if (ids.isEmpty) return {};
    final q = select(cachedExpenses)..where((t) => t.id.isIn(ids));
    final rows = await q.get();
    return rows
        .where((r) {
          final s = LedgerSyncStatus.values[r.syncStatus];
          return s == LedgerSyncStatus.pendingPush ||
              s == LedgerSyncStatus.pendingDelete ||
              s == LedgerSyncStatus.conflict;
        })
        .map((r) => r.id)
        .toSet();
  }

  Future<void> replaceExpenseId(
    String oldId,
    Map<String, dynamic> serverRow,
  ) async {
    final newId = serverRow['id']?.toString() ?? '';
    if (newId.isEmpty) return;
    await transaction(() async {
      await (delete(cachedExpenses)..where((t) => t.id.equals(oldId))).go();
      await upsertExpenseFromServer(serverRow, status: LedgerSyncStatus.synced);
    });
  }

  Future<void> markExpenseConflict(
    String id,
    Map<String, dynamic> serverRow,
  ) async {
    final existing = await (select(
      cachedExpenses,
    )..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) return;
    final local = Map<String, dynamic>.from(
      jsonDecode(existing.payloadJson) as Map,
    );
    local['_syncConflict'] = true;
    local['_serverSnapshot'] = serverRow;
    await (update(cachedExpenses)..where((t) => t.id.equals(id))).write(
      CachedExpensesCompanion(
        payloadJson: Value(jsonEncode(local)),
        syncStatus: Value(LedgerSyncStatus.conflict.index),
        lastKnownServerAt: Value(_parseIso(serverRow['updatedAt'] as String?)),
      ),
    );
  }

  Future<int> enqueueOutbox({
    required String opCode,
    required String entityId,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) {
    return into(syncOutbox).insert(
      SyncOutboxCompanion.insert(
        opCode: opCode,
        entityId: entityId,
        payloadJson: jsonEncode(payload),
        idempotencyKey: idempotencyKey,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<SyncOutboxData>> pendingOutbox() {
    return (select(
      syncOutbox,
    )..orderBy([(t) => OrderingTerm.asc(t.localId)]))
        .get();
  }

  Future<void> removeOutbox(int localId) {
    return (delete(syncOutbox)..where((t) => t.localId.equals(localId))).go();
  }

  Future<void> bumpOutboxError(int localId, int attempts, String err) {
    return (update(syncOutbox)..where((t) => t.localId.equals(localId))).write(
      SyncOutboxCompanion(attempts: Value(attempts), lastError: Value(err)),
    );
  }

  Future<void> upsertAccountFromServer(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = _parseIso(row['updatedAt'] as String?);
    await into(cachedAccounts).insertOnConflictUpdate(
      CachedAccountsCompanion(
        id: Value(id),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(LedgerSyncStatus.synced.index),
        clientRevisionAt: Value(serverAt ?? DateTime.now().toUtc()),
        lastKnownServerAt: Value(serverAt),
      ),
    );
  }

  void batchUpsertAccount(Batch batch, Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = _parseIso(row['updatedAt'] as String?);
    batch.insert(
      cachedAccounts,
      CachedAccountsCompanion(
        id: Value(id),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(LedgerSyncStatus.synced.index),
        clientRevisionAt: Value(serverAt ?? DateTime.now().toUtc()),
        lastKnownServerAt: Value(serverAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<Set<String>> getAccountIdsToSkip(List<String> ids) async {
    if (ids.isEmpty) return {};
    final q = select(cachedAccounts)..where((t) => t.id.isIn(ids));
    final rows = await q.get();
    return rows
        .where((r) {
          final s = LedgerSyncStatus.values[r.syncStatus];
          return s == LedgerSyncStatus.pendingPush ||
              s == LedgerSyncStatus.pendingDelete ||
              s == LedgerSyncStatus.conflict;
        })
        .map((r) => r.id)
        .toSet();
  }

  Future<void> upsertBudgetFromServer(
    Map<String, dynamic> row,
    String monthKey,
  ) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = DateTime.now().toUtc();
    await into(cachedBudgets).insertOnConflictUpdate(
      CachedBudgetsCompanion(
        id: Value(id),
        monthKey: Value(monthKey),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(LedgerSyncStatus.synced.index),
        clientRevisionAt: Value(serverAt),
        lastKnownServerAt: Value(serverAt),
      ),
    );
  }

  void batchUpsertBudget(Batch batch, Map<String, dynamic> row, String monthKey) {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = DateTime.now().toUtc();
    batch.insert(
      cachedBudgets,
      CachedBudgetsCompanion(
        id: Value(id),
        monthKey: Value(monthKey),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(LedgerSyncStatus.synced.index),
        clientRevisionAt: Value(serverAt),
        lastKnownServerAt: Value(serverAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<Set<String>> getBudgetIdsToSkip(List<String> ids) async {
    if (ids.isEmpty) return {};
    final q = select(cachedBudgets)..where((t) => t.id.isIn(ids));
    final rows = await q.get();
    return rows
        .where((r) {
          final s = LedgerSyncStatus.values[r.syncStatus];
          return s == LedgerSyncStatus.pendingPush ||
              s == LedgerSyncStatus.pendingDelete ||
              s == LedgerSyncStatus.conflict;
        })
        .map((r) => r.id)
        .toSet();
  }

  Future<void> upsertKv(String key, String value) async {
    await into(
      ledgerKv,
    ).insertOnConflictUpdate(LedgerKvCompanion.insert(k: key, v: value));
  }

  Future<String?> readKv(String key) async {
    final row = await (select(
      ledgerKv,
    )..where((t) => t.k.equals(key)))
        .getSingleOrNull();
    return row?.v;
  }

  Future<void> insertPendingExpense({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toUtc();
    await into(cachedExpenses).insert(
      CachedExpensesCompanion.insert(
        id: id,
        payloadJson: jsonEncode(payload),
        syncStatus: LedgerSyncStatus.pendingPush.index,
        clientRevisionAt: now,
        expenseSortDate: LedgerDatabase._expenseSortDate(payload),
      ),
    );
  }

  Future<void> markExpensePendingDelete(String id) async {
    await (update(cachedExpenses)..where((t) => t.id.equals(id))).write(
      CachedExpensesCompanion(
        syncStatus: Value(LedgerSyncStatus.pendingDelete.index),
        clientRevisionAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  static DateTime? parseServerIso(String? raw) => _parseIso(raw);

  static DateTime expenseSortDateFromPayload(Map<String, dynamic> row) =>
      _expenseSortDate(row);

  static DateTime? _parseIso(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static DateTime _expenseSortDate(Map<String, dynamic> row) {
    final d = row['date'];
    if (d is String) {
      return DateTime.tryParse(d)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<void> upsertIncomeFromServer(
    Map<String, dynamic> row, {
    LedgerSyncStatus status = LedgerSyncStatus.synced,
  }) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = _parseIso(row['updatedAt'] as String?);
    final sort = _incomeSortDate(row);
    await into(cachedIncomes).insertOnConflictUpdate(
      CachedIncomesCompanion(
        id: Value(id),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(status.index),
        clientRevisionAt: Value(serverAt ?? DateTime.now().toUtc()),
        lastKnownServerAt: Value(serverAt),
        incomeSortDate: Value(sort),
      ),
    );
  }

  void batchUpsertIncome(Batch batch, Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = _parseIso(row['updatedAt'] as String?);
    final sort = _incomeSortDate(row);
    batch.insert(
      cachedIncomes,
      CachedIncomesCompanion(
        id: Value(id),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(LedgerSyncStatus.synced.index),
        clientRevisionAt: Value(serverAt ?? DateTime.now().toUtc()),
        lastKnownServerAt: Value(serverAt),
        incomeSortDate: Value(sort),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<Set<String>> getIncomeIdsToSkip(List<String> ids) async {
    if (ids.isEmpty) return {};
    final q = select(cachedIncomes)..where((t) => t.id.isIn(ids));
    final rows = await q.get();
    return rows
        .where((r) {
          final s = LedgerSyncStatus.values[r.syncStatus];
          return s == LedgerSyncStatus.pendingPush ||
              s == LedgerSyncStatus.pendingDelete ||
              s == LedgerSyncStatus.conflict;
        })
        .map((r) => r.id)
        .toSet();
  }

  Future<void> replaceIncomeId(String oldId, Map<String, dynamic> serverRow) async {
    final newId = serverRow['id']?.toString() ?? '';
    if (newId.isEmpty) return;
    await transaction(() async {
      await (delete(cachedIncomes)..where((t) => t.id.equals(oldId))).go();
      await upsertIncomeFromServer(serverRow, status: LedgerSyncStatus.synced);
    });
  }

  Future<void> markIncomeConflict(String id, Map<String, dynamic> serverRow) async {
    final existing = await (select(cachedIncomes)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return;
    final local = Map<String, dynamic>.from(jsonDecode(existing.payloadJson) as Map);
    local['_syncConflict'] = true;
    local['_serverSnapshot'] = serverRow;
    await (update(cachedIncomes)..where((t) => t.id.equals(id))).write(
      CachedIncomesCompanion(
        payloadJson: Value(jsonEncode(local)),
        syncStatus: Value(LedgerSyncStatus.conflict.index),
        lastKnownServerAt: Value(_parseIso(serverRow['updatedAt'] as String?)),
      ),
    );
  }

  Future<void> insertPendingIncome({required String id, required Map<String, dynamic> payload}) async {
    final now = DateTime.now().toUtc();
    await into(cachedIncomes).insert(
      CachedIncomesCompanion.insert(
        id: id,
        payloadJson: jsonEncode(payload),
        syncStatus: LedgerSyncStatus.pendingPush.index,
        clientRevisionAt: now,
        incomeSortDate: LedgerDatabase._incomeSortDate(payload),
      ),
    );
  }

  Future<void> markIncomePendingDelete(String id) async {
    await (update(cachedIncomes)..where((t) => t.id.equals(id))).write(
      CachedIncomesCompanion(
        syncStatus: Value(LedgerSyncStatus.pendingDelete.index),
        clientRevisionAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> upsertRecurringFromServer(
    Map<String, dynamic> row, {
    LedgerSyncStatus status = LedgerSyncStatus.synced,
  }) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = _parseIso(row['updatedAt'] as String?);
    final nextDate = _parseIso(row['nextDate'] as String?) ?? DateTime.now();
    await into(cachedRecurringExpenses).insertOnConflictUpdate(
      CachedRecurringExpensesCompanion(
        id: Value(id),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(status.index),
        clientRevisionAt: Value(serverAt ?? DateTime.now().toUtc()),
        lastKnownServerAt: Value(serverAt),
        nextDate: Value(nextDate),
        active: Value(row['active'] == true),
      ),
    );
  }

  void batchUpsertRecurring(Batch batch, Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final serverAt = _parseIso(row['updatedAt'] as String?);
    final nextDate = _parseIso(row['nextDate'] as String?) ?? DateTime.now();
    batch.insert(
      cachedRecurringExpenses,
      CachedRecurringExpensesCompanion(
        id: Value(id),
        payloadJson: Value(jsonEncode(row)),
        syncStatus: Value(LedgerSyncStatus.synced.index),
        clientRevisionAt: Value(serverAt ?? DateTime.now().toUtc()),
        lastKnownServerAt: Value(serverAt),
        nextDate: Value(nextDate),
        active: Value(row['active'] == true),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> insertPendingRecurring({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toUtc();
    final next = _parseIso(payload['nextDate'] as String?) ?? now;
    await into(cachedRecurringExpenses).insert(
      CachedRecurringExpensesCompanion.insert(
        id: id,
        payloadJson: jsonEncode(payload),
        syncStatus: LedgerSyncStatus.pendingPush.index,
        clientRevisionAt: now,
        nextDate: next,
        active: Value(payload['active'] == true),
      ),
    );
  }

  Future<void> markRecurringPendingDelete(String id) async {
    await (update(cachedRecurringExpenses)..where((t) => t.id.equals(id))).write(
      CachedRecurringExpensesCompanion(
        syncStatus: Value(LedgerSyncStatus.pendingDelete.index),
        clientRevisionAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  static DateTime incomeSortDateFromPayload(Map<String, dynamic> row) => _incomeSortDate(row);

  static DateTime _incomeSortDate(Map<String, dynamic> row) {
    final d = row['date'];
    if (d is String) {
      return DateTime.tryParse(d)?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
