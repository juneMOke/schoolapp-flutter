import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_settings_bounds.dart';

/// Les bornes du barème sont celles du serveur (`PayrollSettingsInput`) : un
/// barème hors bornes ne part jamais dans la file.
void main() {
  const defaults = PayrollSettings.defaults;

  PayrollSettings withRule(PayrollCurrencySettings usd) =>
      defaults.copyWith(byCurrency: {...defaults.byCurrency, 'USD': usd});

  test('les valeurs de la spec sont dans les bornes', () {
    expect(PayrollSettingsBounds.isValid(defaults), isTrue);
  });

  test('heures et majoration hors bornes sont refusées', () {
    for (final invalid in [
      defaults.copyWith(monthlyHoursDivisor: 0),
      defaults.copyWith(monthlyHoursDivisor: 745),
      defaults.copyWith(overtimeMultiplierPermille: 999),
      defaults.copyWith(overtimeMultiplierPermille: 5001),
    ]) {
      expect(PayrollSettingsBounds.isValid(invalid), isFalse);
    }
    expect(
      PayrollSettingsBounds.isValid(
        defaults.copyWith(overtimeMultiplierPermille: 1325),
      ),
      isTrue,
    );
  });

  test('un pas d arrondi nul, une CNSS au-delà de 1000 ‰ sont refusés', () {
    const usd = PayrollCurrencySettings(
      childAllowanceInCents: 500,
      defaultOvertimeRateInCents: 300,
      overtimeRateStepInCents: 0,
    );
    expect(PayrollSettingsBounds.isValid(withRule(usd)), isFalse);
    expect(
      PayrollSettingsBounds.isValid(
        withRule(
          const PayrollCurrencySettings(
            childAllowanceInCents: 500,
            defaultOvertimeRateInCents: 300,
            overtimeRateStepInCents: 50,
            cnssPermille: 1001,
          ),
        ),
      ),
      isFalse,
    );
  });

  test('un barème relu « en attente » n est pas une modification', () {
    const pending = PayrollSettings(
      monthlyHoursDivisor: 173,
      overtimeMultiplierPermille: 1300,
      allowanceEligibleKinds: {},
      byCurrency: {},
      syncState: RecordSyncState.pending,
    );
    const synced = PayrollSettings(
      monthlyHoursDivisor: 173,
      overtimeMultiplierPermille: 1300,
      allowanceEligibleKinds: {},
      byCurrency: {},
    );
    expect(pending.sameRulesAs(synced), isTrue);
    expect(pending == synced, isFalse);
    expect(
      synced.sameRulesAs(synced.copyWith(monthlyHoursDivisor: 160)),
      isFalse,
    );
  });
}
