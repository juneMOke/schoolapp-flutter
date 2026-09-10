import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/data/models/relance_list_request_model.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

LocalRecoveryLine line(
  String studentId, {
  List<(String feeCode, String currency, int expected, int paid)> charges =
      const [('TUITION', 'USD', 30000, 12000)],
}) => LocalRecoveryLine(
  schoolLevelId: 'lvl-1',
  studentId: studentId,
  charges: [
    for (final (feeCode, currency, expected, paid) in charges)
      RecoveryChargePosition(
        feeCode: feeCode,
        position: FeeChargePosition(
          currency: currency,
          expectedInCents: expected,
          paidMirrorInCents: paid,
          paidPendingInCents: 0,
        ),
      ),
  ],
);

Map<String, dynamic> body({
  RelanceScope? scope,
  List<LocalRecoveryLine>? lines,
  RecouvrementCriterion criterion = RecouvrementCriterion.noPayment,
  int? thresholdInCents,
  String? thresholdCurrency,
  int? pendingWrites,
}) => RelanceListRequestModel.of(
  scope: scope ?? RelanceScope.schoolLevel('lvl-1'),
  feeCodes: const ['TUITION'],
  criterion: criterion,
  lines: lines ?? [line('s1')],
  arretedAt: DateTime.utc(2026, 9, 10, 8, 5),
  thresholdInCents: thresholdInCents,
  thresholdCurrency: thresholdCurrency,
  pendingWrites: pendingWrites,
).toJson();

void main() {
  group('ce que le corps porte', () {
    test('un identifiant et TROIS SACS, rien de plus', () {
      final json = body();
      final row = (json['lines'] as List).single as Map<String, dynamic>;

      expect(
        row.keys,
        containsAll(['studentId', 'due', 'paid', 'outstanding']),
      );
      expect(
        row.keys,
        isNot(contains('displayName')),
        reason:
            'le nom est résolu SERVEUR — une tablette ne titre pas le '
            'papier de l\'école',
      );
      expect(row.keys, isNot(contains('matricule')));
      expect(row.keys, isNot(contains('classroomName')));
    });

    test('les montants sont des tableaux, une entrée par devise', () {
      final json = body(
        lines: [
          line(
            's1',
            charges: const [
              ('TUITION', 'USD', 30000, 12000),
              ('REGISTRATION', 'CDF', 5000000, 1000000),
            ],
          ),
        ],
      );
      final row = (json['lines'] as List).single as Map<String, dynamic>;

      expect(row['due'], hasLength(2));
      expect((row['due'] as List).map((e) => (e as Map)['currency']), [
        'CDF',
        'USD',
      ]);
    });

    test('un élève SOLDÉ part avec une entrée à zéro, pas un sac vide', () {
      final json = body(
        lines: [
          line('s1', charges: const [('TUITION', 'USD', 30000, 30000)]),
        ],
      );
      final row = (json['lines'] as List).single as Map<String, dynamic>;

      expect(
        row['outstanding'],
        hasLength(1),
        reason:
            'le sac vide dit « aucun montant », le zéro dit « il ne reste '
            'rien en dollars »',
      );
      expect(((row['outstanding'] as List).single as Map)['amountInCents'], 0);
    });

    test('la date d\'arrêté part en UTC ISO-8601', () {
      expect(body()['arretedAt'], '2026-09-10T08:05:00.000Z');
    });
  });

  group('le périmètre', () {
    test('chaque genre porte son nom de fil', () {
      expect(
        (body(scope: RelanceScope.classroom('c1'))['scope'] as Map)['kind'],
        'CLASSROOM',
      );
      expect(
        (body(scope: RelanceScope.schoolLevelGroup('g1'))['scope']
            as Map)['kind'],
        'SCHOOL_LEVEL_GROUP',
      );
    });

    test('« non affectés » ne porte AUCUN identifiant', () {
      final scope = body(scope: RelanceScope.unassigned)['scope'] as Map;

      expect(scope['kind'], 'UNASSIGNED');
      expect(
        scope.containsKey('id'),
        isFalse,
        reason: 'il ne désigne aucune entité du référentiel',
      );
    });
  });

  group('les champs facultatifs', () {
    test('absents du corps quand ils sont nuls, jamais à null', () {
      final json = body();

      expect(json.containsKey('thresholdInCents'), isFalse);
      expect(json.containsKey('thresholdCurrency'), isFalse);
      expect(json.containsKey('pendingWrites'), isFalse);
    });

    test('le plancher voyage avec SA devise', () {
      final json = body(
        criterion: RecouvrementCriterion.belowThreshold,
        thresholdInCents: 12000,
        thresholdCurrency: 'USD',
      );

      expect(json['criterion'], 'BELOW_THRESHOLD');
      expect(json['thresholdInCents'], 12000);
      expect(json['thresholdCurrency'], 'USD');
    });

    test('le compte d\'écritures en attente part tel quel', () {
      expect(body(pendingWrites: 3)['pendingWrites'], 3);
    });
  });

  group('le critère', () {
    test('chaque valeur porte son nom de fil', () {
      expect(body()['criterion'], 'NO_PAYMENT');
      expect(
        body(criterion: RecouvrementCriterion.notSettled)['criterion'],
        'NOT_SETTLED',
      );
    });
  });
}
