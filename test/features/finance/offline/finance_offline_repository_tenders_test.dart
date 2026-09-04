import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../offline_full_db.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

/// Le chemin d'écriture écrit désormais DEUX listes : ce qui a été imputé, et ce
/// qui est entré dans le tiroir.
///
/// La première garde du repo (total déclaré = Σ imputations) compare de l'imputé
/// à de l'imputé et n'est pas concernée. Celle qu'on éprouve ici est la seconde.
const int _taux166667 = 1666670000;

void main() {
  late Database db;
  late FinanceOfflineRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    final syncEngine = MockSyncEngine();
    when(
      () => syncEngine.flush(),
    ).thenAnswer((_) async => const SyncFlushReport());
    repo = FinanceOfflineRepositoryImpl(
      dao: FinanceLocalDao(db, const IdGenerator(Uuid())),
      idGenerator: const IdGenerator(Uuid()),
      syncEngine: syncEngine,
      now: () => 1000,
    );
  });

  tearDown(() async => db.close());

  RecordPaymentDraft draft({
    required List<AllocationDraft> allocations,
    MoneyBag? amounts,
    List<TenderDraft>? tenders,
  }) => RecordPaymentDraft(
    studentId: 's1',
    academicYearId: 'ay-1',
    paidAt: '2026-09-01T10:00:00Z',
    payerFirstName: 'Sarah',
    payerLastName: 'Ngalula',
    amounts: amounts,
    tenders: tenders,
    allocations: allocations,
  );

  const dollars = AllocationDraft(
    feeCode: 'MINERVAL_T1',
    studentChargeLabel: 'Minerval — tranche 1',
    amountInCents: 3000,
    currency: 'USD',
  );

  /// Ce qui part réellement sur le fil pour ce versement.
  Future<Map<String, dynamic>> pushedPayment(String paymentId) async {
    final entry = (await db.query(
      'outbox',
      where: 'aggregate_type = ? AND aggregate_id = ?',
      whereArgs: ['PAYMENT', paymentId],
    )).single;
    final payload =
        jsonDecode(entry['payload'] as String) as Map<String, dynamic>;
    return payload['payment'] as Map<String, dynamic>;
  }

  Future<List<Map<String, Object?>>> tendersOf(String paymentId) => db.query(
    'payment_tenders',
    where: 'payment_id = ?',
    whereArgs: [paymentId],
    orderBy: 'currency',
  );

  test(
    'un règlement dans la devise de la créance écrit une ligne d’identité',
    () async {
      // Le cas courant : aucun taux, aucune arithmétique, et pourtant une ligne
      // de perçu — pour qu'il n'existe jamais qu'UNE voie de lecture.
      final result = await repo.recordPayment(draft(allocations: [dollars]));

      final paymentId = result.getOrElse(() => '');
      final tenders = await tendersOf(paymentId);
      expect(tenders, hasLength(1));
      expect(tenders.single['amount_in_cents'], 3000);
      expect(tenders.single['currency'], 'USD');
      expect(tenders.single['pivot_currency'], 'USD');
      expect(tenders.single['rate_micros'], 1000000);
    },
  );

  test('un versement à deux devises de créance écrit deux lignes', () async {
    final result = await repo.recordPayment(
      draft(
        allocations: [
          dollars,
          const AllocationDraft(
            feeCode: 'FRAIS_VISITE',
            studentChargeLabel: 'Visite médicale',
            amountInCents: 9000000,
            currency: 'CDF',
          ),
        ],
      ),
    );

    final tenders = await tendersOf(result.getOrElse(() => ''));
    expect(tenders.map((t) => t['currency']), ['CDF', 'USD']);
    expect(tenders.map((t) => t['amount_in_cents']), [9000000, 3000]);
  });

  test(
    'un règlement en francs sur une créance en dollars s’écrit avec son taux',
    () async {
      final result = await repo.recordPayment(
        draft(
          allocations: [dollars],
          tenders: const [
            TenderDraft(
              amountInCents: 5000000,
              currency: 'CDF',
              rateMicros: _taux166667,
              pivotCurrency: 'USD',
            ),
          ],
        ),
      );

      expect(result.isRight(), isTrue);
      final paymentId = result.getOrElse(() => '');
      final tenders = await tendersOf(paymentId);
      expect(tenders.single['currency'], 'CDF');
      expect(tenders.single['amount_in_cents'], 5000000);
      expect(tenders.single['pivot_currency'], 'USD');
      expect(tenders.single['rate_micros'], _taux166667);

      // L'imputation, elle, n'a pas bougé d'unité : elle éteint une créance en
      // dollars, et c'est l'axe comptable.
      final allocations = await db.query(
        'payment_allocations',
        where: 'payment_id = ?',
        whereArgs: [paymentId],
      );
      expect(allocations.single['currency'], 'USD');
      expect(allocations.single['amount_in_cents'], 3000);
    },
  );

  test('la fuite du taux est refusée, et rien n’est écrit', () async {
    // 100 000 FC contre une créance de 30 $ au taux annoncé de 1 666,67 :
    // le tiroir a vu le double de ce que la créance vaut.
    final result = await repo.recordPayment(
      draft(
        allocations: [dollars],
        tenders: const [
          TenderDraft(
            amountInCents: 10000000,
            currency: 'CDF',
            rateMicros: _taux166667,
            pivotCurrency: 'USD',
          ),
        ],
      ),
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('le versement aurait dû être refusé'),
    );
    expect(await db.query('payments'), isEmpty);
    expect(await db.query('payment_allocations'), isEmpty);
    expect(await db.query('payment_tenders'), isEmpty);
    // Rien en file non plus : un payload refusé localement ne doit jamais
    // partir, sinon le fail-fast ne servirait à rien.
    expect(await db.query('outbox'), isEmpty);
  });

  test('l’écart d’arrondi du franc reste accepté', () async {
    // 30,00 $ à 1 666,67 valent 50 000,10 FC pour un tiroir qui a vu
    // 50 000 FC : refuser cet écart, c'est refuser un versement juste.
    final result = await repo.recordPayment(
      draft(
        allocations: [dollars],
        tenders: const [
          TenderDraft(
            amountInCents: 5000000,
            currency: 'CDF',
            rateMicros: _taux166667,
            pivotCurrency: 'USD',
          ),
        ],
      ),
    );

    expect(result.isRight(), isTrue);
  });

  test(
    'la première garde reste en place et porte toujours sur l’imputé',
    () async {
      // `amounts` est en devise de CRÉANCE : un total qui ne retombe pas sur les
      // imputations reste refusé, exactement comme avant la V2.
      final result = await repo.recordPayment(
        draft(
          allocations: [dollars],
          amounts: MoneyBag.of(const [Money(50000, 'USD')]),
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(await db.query('payment_tenders'), isEmpty);
    },
  );

  /// Le perçu ne sert à rien tant qu'il reste dans la tablette.
  ///
  /// Le serveur ne refuse pas un versement qui ne déclare rien : il écrit
  /// l'identité — perçu = imputé, taux 1. Se taire, ce n'est donc pas « ne rien
  /// dire », c'est affirmer que le tiroir a vu la devise de la créance. La
  /// caisse du jour, le contrôle de divergence de taux et le second poste
  /// lisent tous cette affirmation-là.
  group('ce que le tiroir a vu part sur le fil', () {
    test(
      'un règlement converti est DÉCLARÉ, avec sa devise et son taux',
      () async {
        final result = await repo.recordPayment(
          draft(
            allocations: [dollars],
            tenders: const [
              TenderDraft(
                amountInCents: 5000000,
                currency: 'CDF',
                rateMicros: _taux166667,
                pivotCurrency: 'USD',
              ),
            ],
          ),
        );

        final paymentId = result.getOrElse(() => '');
        final payment = await pushedPayment(paymentId);
        final tender =
            (payment['tenders'] as List<dynamic>).single
                as Map<String, dynamic>;

        expect(tender['amountInCents'], 5000000);
        expect(tender['currency'], 'CDF');
        expect(tender['pivotCurrency'], 'USD');
        // Le taux voyage en DÉCIMAL (`numeric(18,6)` serveur) : les micro-unités
        // sont une convention locale.
        expect(tender['rate'], closeTo(1666.67, 0.000001));

        // `amounts` n'a pas bougé d'axe : il reste l'IMPUTÉ, en devise de
        // créance. Les deux listes ne se recoupent pas — c'est tout l'intérêt.
        final amounts =
            (payment['amounts'] as List<dynamic>).single
                as Map<String, dynamic>;
        expect(amounts['currency'], 'USD');
        expect(amounts['amountInCents'], 3000);
      },
    );

    test('l\'identité aussi est déclarée — un versement muet ferait écrire au '
        'serveur ce que le tiroir n\'a pas vu', () async {
      final result = await repo.recordPayment(draft(allocations: [dollars]));

      final payment = await pushedPayment(result.getOrElse(() => ''));
      final tender =
          (payment['tenders'] as List<dynamic>).single as Map<String, dynamic>;

      expect(tender['amountInCents'], 3000);
      expect(tender['currency'], 'USD');
      expect(tender['pivotCurrency'], 'USD');
      expect(tender['rate'], 1.0);
    });

    /// Le serveur honore l'uuid client d'une ligne d'encaissement comme celui
    /// d'une allocation. Sans lui, il en invente un, le pull redescend la ligne
    /// sous CET id, et l'upsert local — qui apparie par id — l'INSÈRE à côté de
    /// la nôtre : le versement se relit alors avec deux fois ce qui est entré
    /// dans le tiroir, et le ticket, qui somme cette table, l'imprime.
    test('la ligne poussée porte l\'id de la ligne locale', () async {
      final result = await repo.recordPayment(draft(allocations: [dollars]));

      final paymentId = result.getOrElse(() => '');
      final local = await tendersOf(paymentId);
      final payment = await pushedPayment(paymentId);
      final tender =
          (payment['tenders'] as List<dynamic>).single as Map<String, dynamic>;

      expect(tender['id'], local.single['id']);
      expect(tender['id'], isNotNull);
    });

    test('deux devises de créance font deux lignes sur le fil', () async {
      final result = await repo.recordPayment(
        draft(
          allocations: [
            dollars,
            const AllocationDraft(
              feeCode: 'FRAIS_VISITE',
              studentChargeLabel: 'Visite médicale',
              amountInCents: 9000000,
              currency: 'CDF',
            ),
          ],
        ),
      );

      final payment = await pushedPayment(result.getOrElse(() => ''));
      final tenders = (payment['tenders'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(tenders.map((t) => t['currency']), ['CDF', 'USD']);
      expect(tenders.map((t) => t['amountInCents']), [9000000, 3000]);
    });
  });
}
