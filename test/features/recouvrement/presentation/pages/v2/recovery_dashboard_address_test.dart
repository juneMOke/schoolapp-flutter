import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_address.dart';

void main() {
  test("l'adresse garde frais, périmètre, règle, montant, onglet, recherche, "
      'seuil et frais du classement (A1)', () {
    const address = RecoveryDashboardAddress(
      feeCodes: ['TUITION', 'BOOKS'],
      scope: RecoveryScopeKind.classroom,
      scopeId: 'c-7',
      rankingFeeCode: 'BOOKS',
      rule: RecoveryRuleKind.atLeast,
      thresholdInCents: 15000,
      tab: RecoveryTab.inOrder,
      search: 'kab',
      unmanageableBelow: 75,
    );
    final query = {
      for (final e in address.toQueryParameters().entries)
        if (e.value != null) e.key: e.value!,
    };
    expect(RecoveryDashboardAddress.fromQueryParameters(query), address);
  });

  test('les défauts ne s’écrivent pas dans l’adresse', () {
    final query = const RecoveryDashboardAddress(
      feeCodes: ['TUITION'],
    ).toQueryParameters();
    expect(
      {
        for (final e in query.entries)
          if (e.value != null) e.key: e.value,
      },
      {'frais': 'TUITION'},
    );
  });

  test('sans frais, pas de question ; un seuil hors bornes revient à 60', () {
    expect(
      RecoveryDashboardAddress.fromQueryParameters({'regle': 'x'}),
      isNull,
    );
    final a = RecoveryDashboardAddress.fromQueryParameters({
      'frais': 'TUITION',
      'seuil': '95',
      'perimetre': 'nimporte',
    })!;
    expect(a.unmanageableBelow, 60);
    expect(a.scope, RecoveryScopeKind.school);
    expect(
      RecoveryDashboardAddress.fromQueryParameters({
        'frais': 'TUITION',
        'seuil': '47',
      })!.unmanageableBelow,
      45,
    );
  });
}
