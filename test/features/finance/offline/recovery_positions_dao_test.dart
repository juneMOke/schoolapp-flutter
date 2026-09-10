import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';

import '../../offline_full_db.dart';

class _SeqIdGenerator extends IdGenerator {
  _SeqIdGenerator() : super(const Uuid());
  int _i = 0;
  @override
  String newId() => 'id-${_i++}';
}

/// `getRecoveryPositions` — la lecture unique du tableau de bord du
/// Recouvrement : toute la population, sur une SÉLECTION de frais, ventilée par
/// niveau et gardant le détail poste par poste.
void main() {
  late Database db;
  late FinanceLocalDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FinanceLocalDao(db, _SeqIdGenerator());
  });

  tearDown(() async => db.close());

  Future<void> charge(
    String id,
    String studentId,
    String feeCode, {
    int expected = 30000,
    int paid = 0,
    String currency = 'USD',
    String? level = 'lvl-1',
    String? group = 'grp-1',
    String? year = 'ay-1',
  }) => db.insert('student_charges', {
    'id': id,
    'student_id': studentId,
    'academic_year_id': year,
    'school_level_id': level,
    'school_level_group_id': group,
    'fee_code': feeCode,
    'label': feeCode,
    'expected_amount_in_cents': expected,
    'amount_paid_in_cents': paid,
    'optimistic_paid_in_cents': 0,
    'currency': currency,
    'status': 'DUE',
    'sync_status': 'SYNCED',
  });

  /// Un encaissement imputé sur une créance.
  ///
  /// Le montant vit sur l'IMPUTATION, jamais sur le paiement : c'est ce qui
  /// rend la lecture juste quand un versement solde plusieurs postes d'un coup.
  /// Et `cancelled_at` est un epoch, pas une chaîne.
  Future<void> payment(
    String paymentId,
    String chargeId, {
    required String studentId,
    required int amount,
    String feeCode = 'TUITION',
    String syncStatus = 'PENDING_SYNC',
    int? cancelledAt,
  }) async {
    await db.insert('payments', {
      'id': paymentId,
      'client_uuid': paymentId,
      'student_id': studentId,
      'method': 'CASH',
      'paid_at': '2026-09-10T08:00:00Z',
      'cancelled_at': cancelledAt,
      'sync_status': syncStatus,
    });
    await db.insert('payment_allocations', {
      'id': 'alloc-$paymentId',
      'client_uuid': 'alloc-$paymentId',
      'payment_id': paymentId,
      'student_charge_id': chargeId,
      'fee_code': feeCode,
      'student_charge_label': feeCode,
      'amount_in_cents': amount,
      'currency': 'USD',
    });
  }

  Future<List<LocalRecoveryLine>> read({
    List<String> feeCodes = const ['TUITION', 'BOOKS'],
    String? group,
  }) => dao.getRecoveryPositions(
    academicYearId: 'ay-1',
    feeCodes: feeCodes,
    schoolLevelGroupId: group,
  );

  RecoveryChargePosition posOf(LocalRecoveryLine line, String feeCode) =>
      line.charges.firstWhere((c) => c.feeCode == feeCode);

  group('la maille', () {
    test('une ligne par (élève, niveau), une position par (frais, devise)', () {
      // Deux frais, deux élèves, un seul niveau.
      Future<void> seed() async {
        await charge('c1', 's1', 'TUITION');
        await charge('c2', 's1', 'BOOKS', expected: 10000);
        await charge('c3', 's2', 'TUITION');
      }

      return seed().then((_) async {
        final lines = await read();
        expect(lines, hasLength(2));

        final s1 = lines.firstWhere((l) => l.studentId == 's1');
        expect(s1.schoolLevelId, 'lvl-1');
        expect(s1.charges.map((c) => c.feeCode), ['BOOKS', 'TUITION']);

        final s2 = lines.firstWhere((l) => l.studentId == 's2');
        expect(s2.charges, hasLength(1));
      });
    });

    test(
      'le même élève sur DEUX niveaux donne deux lignes — il doit à chacun',
      () async {
        await charge('c1', 's1', 'TUITION', level: 'lvl-1');
        await charge('c2', 's1', 'TUITION', level: 'lvl-2');

        final lines = await read(feeCodes: const ['TUITION']);

        expect(lines, hasLength(2));
        expect(
          lines.map((l) => l.schoolLevelId).toSet(),
          {'lvl-1', 'lvl-2'},
          reason: 'le total de la page doit rester la somme de ses niveaux',
        );
      },
    );

    test(
      'une créance SANS niveau garde sa ligne, sous un groupe nul',
      () async {
        await charge('c1', 's1', 'TUITION', level: null);

        final lines = await read(feeCodes: const ['TUITION']);

        expect(lines, hasLength(1));
        expect(
          lines.single.schoolLevelId,
          isNull,
          reason: 'la filtrer ferait disparaître un élève sans rien dire',
        );
      },
    );

    test('deux devises sur le même frais font deux positions', () async {
      await charge('c1', 's1', 'TUITION', currency: 'USD', expected: 30000);
      await charge('c2', 's1', 'TUITION', currency: 'CDF', expected: 5000000);

      final lines = await read(feeCodes: const ['TUITION']);

      expect(lines.single.charges, hasLength(2));
      expect(lines.single.charges.map((c) => c.currency), ['CDF', 'USD']);
    });

    test('les créances de la même (nature, devise) se somment', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000, paid: 5000);
      await charge('c2', 's1', 'TUITION', expected: 20000, paid: 1000);

      final lines = await read(feeCodes: const ['TUITION']);

      final pos = lines.single.charges.single;
      expect(pos.expectedInCents, 50000);
      expect(pos.paidTotalInCents, 6000);
    });
  });

  group('le périmètre', () {
    test('la sélection borne les natures rendues', () async {
      await charge('c1', 's1', 'TUITION');
      await charge('c2', 's1', 'BOOKS');
      await charge('c3', 's1', 'CANTEEN');

      final lines = await read(feeCodes: const ['TUITION', 'CANTEEN']);

      expect(lines.single.charges.map((c) => c.feeCode), [
        'CANTEEN',
        'TUITION',
      ]);
    });

    test('le cycle borne la population', () async {
      await charge('c1', 's1', 'TUITION', group: 'grp-1');
      await charge('c2', 's2', 'TUITION', group: 'grp-2');

      final lines = await read(feeCodes: const ['TUITION'], group: 'grp-2');

      expect(lines.map((l) => l.studentId), ['s2']);
    });

    test('une créance sans année est retenue, comme au contrôle', () async {
      await charge('c1', 's1', 'TUITION', year: null);

      expect(await read(feeCodes: const ['TUITION']), hasLength(1));
    });

    test('une créance d\'une AUTRE année est écartée', () async {
      await charge('c1', 's1', 'TUITION', year: 'ay-0');

      expect(await read(feeCodes: const ['TUITION']), isEmpty);
    });

    test(
      'une sélection vide rend une liste vide, sans requête ni erreur',
      () async {
        await charge('c1', 's1', 'TUITION');

        expect(await read(feeCodes: const []), isEmpty);
      },
    );
  });

  group('le payé composé', () {
    test('un encaissement NON remonté déplace le payé', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000, paid: 0);
      await payment(
        'p1',
        'c1',
        studentId: 's1',
        amount: 12000,
        syncStatus: 'PENDING_SYNC',
      );

      final pos = posOf(
        (await read(feeCodes: const ['TUITION'])).single,
        'TUITION',
      );

      expect(pos.paidTotalInCents, 12000);
      expect(pos.remainingInCents, 18000);
    });

    test('un encaissement en ERREUR de synchro compte aussi', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000);
      await payment(
        'p1',
        'c1',
        studentId: 's1',
        amount: 5000,
        syncStatus: 'SYNC_ERROR',
      );

      expect(
        posOf(
          (await read(feeCodes: const ['TUITION'])).single,
          'TUITION',
        ).paidTotalInCents,
        5000,
      );
    });

    test('un encaissement ANNULÉ ne compte pas', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000);
      await payment(
        'p1',
        'c1',
        studentId: 's1',
        amount: 5000,
        cancelledAt: 1757494800000,
      );

      expect(
        posOf(
          (await read(feeCodes: const ['TUITION'])).single,
          'TUITION',
        ).paidTotalInCents,
        0,
      );
    });

    test('un encaissement DÉJÀ remonté n\'est pas compté deux fois', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000, paid: 12000);
      await payment(
        'p1',
        'c1',
        studentId: 's1',
        amount: 12000,
        syncStatus: 'SYNCED',
      );

      expect(
        posOf(
          (await read(feeCodes: const ['TUITION'])).single,
          'TUITION',
        ).paidTotalInCents,
        12000,
        reason: 'le miroir porte déjà ce versement',
      );
    });
  });

  group('le statut, emprunté à la règle du module', () {
    Future<StudentChargeStatus> statusOf() async =>
        (await read()).single.status;

    test('aucun versement nulle part ⇒ rien', () async {
      await charge('c1', 's1', 'TUITION', paid: 0);
      await charge('c2', 's1', 'BOOKS', paid: 0);

      expect(await statusOf(), StudentChargeStatus.due);
    });

    test('plus rien à devoir sur aucune créance ⇒ soldé', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000, paid: 30000);
      await charge('c2', 's1', 'BOOKS', expected: 10000, paid: 10000);

      expect(await statusOf(), StudentChargeStatus.paid);
    });

    test('un geste quelque part, pas partout ⇒ partiel', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000, paid: 12000);
      await charge('c2', 's1', 'BOOKS', expected: 10000, paid: 0);

      expect(await statusOf(), StudentChargeStatus.partial);
    });

    test(
      'le TROP-PERÇU croisé n\'efface pas l\'impayé du poste voisin',
      () async {
        // Le contre-exemple du back : 400 payés sur 300 de scolarité, rien sur
        // 100 de fournitures. Le reste vaut 100, pas 0 — une somme de maxima
        // n'est pas le maximum de la somme.
        await charge('c1', 's1', 'TUITION', expected: 30000, paid: 40000);
        await charge('c2', 's1', 'BOOKS', expected: 10000, paid: 0);

        final line = (await read()).single;

        expect(
          posOf(line, 'TUITION').remainingInCents,
          0,
          reason: 'le trop-perçu est planché à zéro sur SA créance',
        );
        expect(posOf(line, 'BOOKS').remainingInCents, 10000);
        expect(
          line.remaining.amountIn('USD')!.amountInCents,
          10000,
          reason: 'et jamais max(0, 40000 − 40000) = 0',
        );
        expect(line.status, StudentChargeStatus.partial);
      },
    );

    test(
      'un élève à jour en dollars et débiteur en francs n\'est pas en règle',
      () async {
        await charge('c1', 's1', 'TUITION', expected: 30000, paid: 30000);
        await charge(
          'c2',
          's1',
          'BOOKS',
          currency: 'CDF',
          expected: 5000000,
          paid: 0,
        );

        expect(await statusOf(), StudentChargeStatus.partial);
      },
    );
  });

  group('les sacs de l\'élève', () {
    test('jamais deux devises additionnées', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000, paid: 12000);
      await charge(
        'c2',
        's1',
        'BOOKS',
        currency: 'CDF',
        expected: 5000000,
        paid: 1000000,
      );

      final line = (await read()).single;

      expect(line.expected.entries, hasLength(2));
      expect(line.expected.amountIn('USD')!.amountInCents, 30000);
      expect(line.expected.amountIn('CDF')!.amountInCents, 5000000);
      expect(line.remaining.amountIn('USD')!.amountInCents, 18000);
      expect(line.remaining.amountIn('CDF')!.amountInCents, 4000000);
    });

    test('un élève soldé garde une entrée À ZÉRO, pas un sac vide', () async {
      await charge('c1', 's1', 'TUITION', expected: 30000, paid: 30000);

      final line = (await read(feeCodes: const ['TUITION'])).single;

      expect(
        line.remaining.entries,
        hasLength(1),
        reason:
            'le sac vide dit « aucun montant », le zéro dit « il ne reste '
            'rien en dollars » — et le corps de la liste de relance part non '
            'élagué',
      );
      expect(line.remaining.amountIn('USD')!.amountInCents, 0);
    });
  });
}
