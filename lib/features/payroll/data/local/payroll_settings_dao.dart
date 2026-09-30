import 'dart:convert';

import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les réglages de paie d'une école (`ref_payroll_settings`) : semés par le
/// socle, modifiables sur la tablette (dernier écrit gagne).
class PayrollSettingsDao {
  final PayrollStore _store;

  PayrollSettingsDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'ref_payroll_settings';

  static PayrollRowKey _key(String schoolId) => {'school_id': schoolId};

  /// Les réglages de l'école ; les défauts quand elle n'a rien posé.
  Future<PayrollSettings> read(String schoolId) async {
    final rows = await _store.db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      limit: 1,
    );
    if (rows.isEmpty) return PayrollSettings.defaults;
    final row = rows.single;
    final seed = PayrollSettingsSeed.tryParse({
      'monthlyHoursDivisor': row['monthly_hours_divisor'],
      'overtimeMultiplierPermille': row['overtime_multiplier_permille'],
      'allowanceEligibleKinds': _decode(row['allowance_eligible_kinds']),
      'byCurrency': _decode(row['by_currency']),
    });
    if (seed == null) return PayrollSettings.defaults;
    return toEntity(
      seed,
      syncState: StaffSyncState.fromDb(row['sync_status'] as String?),
    );
  }

  /// La section du socle. Des réglages modifiés sur la tablette et encore en
  /// file ne sont pas écrasés ; des réglages **refusés** cèdent.
  Future<void> applySeed(
    PayrollSettingsSeed seed, {
    required String schoolId,
    required int nowMs,
  }) => _store.transaction((txn) async {
    if (await PayrollStore.isPending(txn, table, _key(schoolId))) return;
    await PayrollStore.upsert(txn, table, _key(schoolId), {
      ..._columns(seed),
      'sync_status': StaffSyncState.synced.dbValue,
      'sync_error': null,
      'sync_error_code': null,
      'updated_at': nowMs,
    });
  });

  /// Enregistre les réglages et les met en file (entrée unique par école).
  Future<void> save(
    PayrollSettingsRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) => _store.write(
    table,
    _key(schoolId),
    {
      ..._columns(request.settings),
      'client_updated_at': request.clientUpdatedAt,
      'updated_at': nowMs,
    },
    PayrollQueued(
      entryId: PayrollOutbox.saisieId(
        PayrollOutbox.settings,
        schoolId,
        request.clientUpdatedAt,
      ),
      aggregateType: PayrollOutbox.settings,
      aggregateId: schoolId,
      payload: request.toJson(),
    ),
    schoolId: schoolId,
    nowMs: nowMs,
  );

  Future<bool> settle(
    String schoolId, {
    required String sentClientUpdatedAt,
    required bool failed,
    PayrollSettingsSeed? retained,
    String? code,
    String? reason,
  }) => _store.settleLww(
    table,
    _key(schoolId),
    sentClientUpdatedAt: sentClientUpdatedAt,
    failed: failed,
    code: code,
    reason: reason,
    serverColumns: retained == null ? const {} : _columns(retained),
  );

  static Map<String, Object?> _columns(PayrollSettingsSeed seed) {
    final json = seed.toJson();
    return {
      'monthly_hours_divisor': seed.monthlyHoursDivisor,
      'overtime_multiplier_permille': seed.overtimeMultiplierPermille,
      'allowance_eligible_kinds': jsonEncode(json['allowanceEligibleKinds']),
      'by_currency': jsonEncode(json['byCurrency']),
    };
  }

  static Object? _decode(Object? raw) {
    if (raw is! String) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static PayrollSettings toEntity(
    PayrollSettingsSeed seed, {
    StaffSyncState syncState = StaffSyncState.synced,
  }) => PayrollSettings(
    monthlyHoursDivisor: seed.monthlyHoursDivisor,
    overtimeMultiplierPermille: seed.overtimeMultiplierPermille,
    allowanceEligibleKinds: {
      for (final kind in seed.allowanceEligibleKinds)
        ?StaffContractKind.fromWire(kind),
    },
    byCurrency: {
      for (final currency in seed.byCurrency)
        currency.currency: PayrollCurrencySettings(
          childAllowanceInCents: currency.childAllowanceInCents,
          defaultOvertimeRateInCents: currency.defaultOvertimeRateInCents,
          overtimeRateStepInCents: currency.overtimeRateStepInCents,
        ),
    },
    syncState: syncState,
  );

  /// La forme du fil de réglages saisis sur la tablette.
  static PayrollSettingsSeed toSeed(PayrollSettings settings) =>
      PayrollSettingsSeed(
        monthlyHoursDivisor: settings.monthlyHoursDivisor,
        overtimeMultiplierPermille: settings.overtimeMultiplierPermille,
        allowanceEligibleKinds: [
          for (final kind in StaffContractKind.values)
            if (settings.allowanceEligibleKinds.contains(kind)) kind.wire,
        ],
        byCurrency: [
          for (final entry
              in (settings.byCurrency.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key))))
            (
              currency: entry.key,
              childAllowanceInCents: entry.value.childAllowanceInCents,
              defaultOvertimeRateInCents:
                  entry.value.defaultOvertimeRateInCents,
              overtimeRateStepInCents: entry.value.overtimeRateStepInCents,
            ),
        ],
      );
}
