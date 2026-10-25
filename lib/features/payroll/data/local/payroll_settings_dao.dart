import 'dart:convert';

import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

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
      'currencyRules': _decode(row['by_currency']),
      'workDaysDivisor': row['work_days_divisor'],
      'absenceDeductionEnabled': row['absence_deduction_enabled'] == 1,
      // Q8 : rangés seulement une fois servis ; `NULL` les tait.
      if (row['childcare_enabled'] != null) ...{
        'cnssEmployerPermille': row['cnss_employer_permille'],
        'inppPermille': row['inpp_permille'],
        'onemPermille': row['onem_permille'],
        'advanceMaxPercent': row['advance_max_percent'],
        'loanMaxMonths': row['loan_max_months'],
        'childcareEnabled': row['childcare_enabled'] == 1,
      },
      'signatureBeneficiaryLabel': row['signature_beneficiary_label'],
      'signatureDirectorLabel': row['signature_director_label'],
      'signatureCashierLabel': row['signature_cashier_label'],
    });
    if (seed == null) return PayrollSettings.defaults;
    return toEntity(
      seed,
      syncState: RecordSyncState.fromDb(row['sync_status'] as String?),
    );
  }

  /// La section du socle. Des réglages modifiés sur la tablette et encore en
  /// file ne sont pas écrasés ; des réglages **refusés** cèdent.
  Future<void> applySeed(
    PayrollSettingsSeed seed, {
    required String schoolId,
    required int nowMs,
  }) => _store.transaction((txn) async {
    if (await PayrollStore.isPending(
      txn,
      table,
      _key(schoolId),
      saisieType: PayrollOutbox.settings,
      saisieKey: schoolId,
    )) {
      return;
    }
    await PayrollStore.upsert(txn, table, _key(schoolId), {
      ..._columns(seed),
      'sync_status': RecordSyncState.synced.dbValue,
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
      'by_currency': jsonEncode(json['currencyRules']),
      'work_days_divisor': seed.workDaysDivisor,
      'absence_deduction_enabled': seed.absenceDeductionEnabled ? 1 : 0,
      // Q8 tus (pas servis, ou saisis sur un écran qui ne les avait pas
      // encore) : les colonnes gardent ce qu'elles ont. Écrire `NULL` par-
      // dessus des valeurs servies rallumerait la PC/E d'ici l'accusé.
      if (seed.servesWideSettings) ...{
        'cnss_employer_permille': seed.cnssEmployerPermille,
        'inpp_permille': seed.inppPermille,
        'onem_permille': seed.onemPermille,
        'advance_max_percent': seed.advanceMaxPercent,
        'loan_max_months': seed.loanMaxMonths,
        'childcare_enabled': seed.childcareEnabled! ? 1 : 0,
        'signature_beneficiary_label': seed.signatureBeneficiaryLabel,
        'signature_director_label': seed.signatureDirectorLabel,
        'signature_cashier_label': seed.signatureCashierLabel,
      },
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
    RecordSyncState syncState = RecordSyncState.synced,
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
          iprFlatInCents: currency.iprFlatInCents,
          cnssPermille: currency.cnssPermille,
        ),
    },
    workDaysDivisor: seed.workDaysDivisor,
    absenceDeductionEnabled: seed.absenceDeductionEnabled,
    cnssEmployerPermille:
        seed.cnssEmployerPermille ??
        PayrollSettings.defaultCnssEmployerPermille,
    inppPermille: seed.inppPermille ?? PayrollSettings.defaultInppPermille,
    onemPermille: seed.onemPermille ?? PayrollSettings.defaultOnemPermille,
    advanceMaxPercent:
        seed.advanceMaxPercent ?? PayrollSettings.defaultAdvanceMaxPercent,
    loanMaxMonths: seed.loanMaxMonths ?? PayrollSettings.defaultLoanMaxMonths,
    childcareEnabled: seed.childcareEnabled ?? true,
    signatureBeneficiaryLabel: seed.signatureBeneficiaryLabel,
    signatureDirectorLabel: seed.signatureDirectorLabel,
    signatureCashierLabel: seed.signatureCashierLabel,
    wideSettingsServed: seed.servesWideSettings,
    syncState: syncState,
  );

  /// La forme du fil de réglages saisis sur la tablette.
  static PayrollSettingsSeed toSeed(
    PayrollSettings settings,
  ) => PayrollSettingsSeed(
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
          defaultOvertimeRateInCents: entry.value.defaultOvertimeRateInCents,
          overtimeRateStepInCents: entry.value.overtimeRateStepInCents,
          iprFlatInCents: entry.value.iprFlatInCents,
          cnssPermille: entry.value.cnssPermille,
        ),
    ],
    workDaysDivisor: settings.workDaysDivisor,
    absenceDeductionEnabled: settings.absenceDeductionEnabled,
    // Pas servis : tus, le serveur garde les siens.
    cnssEmployerPermille: settings.wideSettingsServed
        ? settings.cnssEmployerPermille
        : null,
    inppPermille: settings.wideSettingsServed ? settings.inppPermille : null,
    onemPermille: settings.wideSettingsServed ? settings.onemPermille : null,
    advanceMaxPercent: settings.wideSettingsServed
        ? settings.advanceMaxPercent
        : null,
    loanMaxMonths: settings.wideSettingsServed ? settings.loanMaxMonths : null,
    childcareEnabled: settings.wideSettingsServed
        ? settings.childcareEnabled
        : null,
    signatureBeneficiaryLabel: settings.signatureBeneficiaryLabel,
    signatureDirectorLabel: settings.signatureDirectorLabel,
    signatureCashierLabel: settings.signatureCashierLabel,
  );
}
