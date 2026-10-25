import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_draft.dart';

/// Le brouillon du barème n'invente rien et n'écrase rien : une devise que
/// l'école n'a pas réglée n'apparaît pas, et un champ intact suit le barème
/// servi quand un autre poste le change.
void main() {
  const usdOnly = PayrollSettings(
    monthlyHoursDivisor: 173,
    overtimeMultiplierPermille: 1325,
    allowanceEligibleKinds: {},
    byCurrency: {
      'USD': PayrollCurrencySettings(
        childAllowanceInCents: 500,
        defaultOvertimeRateInCents: 300,
        overtimeRateStepInCents: 50,
      ),
    },
  );

  test('une école en dollars seulement : ni champ ni règle en francs', () {
    final draft = PayrollSettingsDraft(usdOnly);
    addTearDown(draft.dispose);

    expect(draft.currencies, ['USD']);
    expect(draft.isDirty, isFalse);
    expect(draft.settings!.byCurrency.keys, ['USD']);
    // 1325 ‰ n'est pas arrondi à 1320 tant que personne n'y touche.
    expect(draft.settings!.overtimeMultiplierPermille, 1325);
  });

  test('un autre poste change le barème : les champs intacts suivent, la '
      'saisie en cours reste', () {
    final draft = PayrollSettingsDraft(usdOnly);
    addTearDown(draft.dispose);
    draft.hours.text = '160';

    draft.rebase(
      usdOnly.copyWith(
        overtimeMultiplierPermille: 1500,
        byCurrency: {
          'USD': const PayrollCurrencySettings(
            childAllowanceInCents: 500,
            defaultOvertimeRateInCents: 300,
            overtimeRateStepInCents: 50,
            iprFlatInCents: 200,
          ),
        },
      ),
    );

    final saved = draft.settings!;
    expect(saved.monthlyHoursDivisor, 160);
    expect(saved.overtimeMultiplierPermille, 1500);
    expect(saved.of('USD').iprFlatInCents, 200);
  });
}
