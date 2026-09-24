import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/expense/local/expense_type_local_model.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/exchange_rate_reader.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_type_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _Ids implements IdGenerator {
  @override
  String newId() => 'e-new';
}

/// ⚠️ [_Ids] rend TOUJOURS le même identifiant : deux gestes de suite y
/// porteraient le même uuid, et le second serait jugé rejeu — inerte. Les
/// gestes prennent donc celui-ci.
class _SeqIds implements IdGenerator {
  int _next = 0;
  @override
  String newId() => 'm-${++_next}';
}

class _MockEngine extends Mock implements SyncEngine {}

class _Rates implements ExchangeRateReader {
  final List<ExchangeRate> rates;
  const _Rates(this.rates);
  @override
  Future<List<ExchangeRate>> forCurrentSchool() async => rates;
}

// Samedi 12 septembre 2026, 15 h.
final _now = DateTime(2026, 9, 12, 15);

ExpenseDraft _draft({String? id, DateTime? day}) => ExpenseDraft(
  id: id,
  typeId: 't-elec',
  title: '  Facture SNEL  ',
  description: '   ',
  amountInCents: 38500000,
  currency: 'cdf',
  expenseDate: day ?? DateTime(2026, 9, 3, 18, 30),
  supplier: 'SNEL',
  recordedByName: 'Moke Junior',
);

void main() {
  late Database db;
  late ExpenseRepositoryImpl repo;
  late CurrentUserContext user;

  ExpenseRepositoryImpl build({SyncEngine? engine, IdGenerator? ids}) =>
      ExpenseRepositoryImpl(
        reader: ExpenseReadDao(db),
        writer: ExpenseWriteDao(db),
        types: ExpenseTypeDao(db),
        messages: ExpenseMessageDao(db),
        currentUser: user,
        ids: ids ?? _Ids(),
        rates: _Rates([
          ExchangeRate(
            base: 'USD',
            quote: 'CDF',
            rateMicros: 2800 * ExchangeRate.scale,
            effectiveFrom: DateTime.utc(2026, 9, 1),
          ),
        ]),
        schoolYearStart: () async => DateTime(2025, 9, 7),
        syncEngine: engine,
        now: () => _now,
      );

  setUp(() async {
    db = await openFullOfflineDb();
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    repo = build();
  });
  tearDown(() async => db.close());

  Future<List<Map<String, Object?>>> outbox() =>
      db.query('outbox', orderBy: 'created_at');

  Future<Expense> saved(ExpenseDraft draft) async =>
      (await repo.save(draft)).fold((f) => fail('$f'), (e) => e);

  group('save', () {
    test('dépôt : la demande naît EN ATTENTE, sans date de règlement, et UNE '
        'entrée d’outbox portant l’auteur', () async {
      final expense = await saved(_draft());

      expect(expense.id, 'e-new');
      expect(expense.title, 'Facture SNEL');
      expect(expense.description, isNull);
      expect(expense.currency, 'CDF');
      // D8 : le statut n'est pas une saisie, et rien n'est décaissé avant
      // approbation — la date de règlement viendra du geste de paiement.
      expect(expense.status, ExpenseStatus.pending);
      expect(expense.paidOn, isNull);
      expect(expense.isFirm, isFalse);
      expect(expense.syncState, ExpenseSyncState.pending);
      expect(expense.number, isNull, reason: 'A3 : numéro en attente');

      final entries = await outbox();
      expect(entries, hasLength(1));
      expect(entries.single['id'], 'EXPENSE:e-new');
      final payload = jsonDecode(entries.single['payload'] as String) as Map;
      expect(payload['authorId'], 'u-1');
      expect(payload['expense']['expenseDate'], '2026-09-03');
      expect(payload['expense']['paidOn'], isNull);
      expect(payload['expense']['amountInCents'], 38500000);
    });

    test(
      'corriger une demande déjà tranchée ne touche NI au statut NI au '
      'règlement : le circuit ne se contourne pas par le formulaire',
      () async {
        await saved(_draft());
        // Le serveur a approuvé puis constaté le paiement pendant ce temps.
        await db.update('expenses', {
          'status': 'PAID',
          'paid_on': '2026-09-10',
          'decided_by_name': 'Nsimba Patrick',
          'decided_at': '2026-09-08T09:12:40.000Z',
          'reminder_count': 2,
        });

        final edited = await saved(
          _draft(id: 'e-new', day: DateTime(2026, 9, 4)),
        );

        expect(edited.status, ExpenseStatus.paid);
        expect(edited.paidOn, DateTime(2026, 9, 10));
        expect(edited.decidedByName, 'Nsimba Patrick');
        expect(edited.reminderCount, 2);
        expect(
          edited.expenseDate,
          DateTime(2026, 9, 4),
          reason: 'le contenu, si',
        );
        // Toujours une seule entrée : chaque geste remplace le précédent.
        expect(await outbox(), hasLength(1));
      },
    );

    test('sans école : refus local, rien d’écrit', () async {
      user.clear();
      expect((await repo.save(_draft())).isLeft(), isTrue);
      expect(await outbox(), isEmpty);
    });

    test('sans agent connecté : refus local — une entrée sans auteur serait '
        'refusée, donc perdue', () async {
      final expense = await saved(_draft());
      user.set(null, schoolId: 'school-1');

      expect((await repo.save(_draft())).isLeft(), isTrue);
      expect((await repo.withdraw(expense)).isLeft(), isTrue);
      expect(await outbox(), hasLength(1), reason: 'la seule création d’avant');
    });

    test('chaque écriture pousse sans attendre le battement', () async {
      final engine = _MockEngine();
      when(
        () => engine.flush(),
      ).thenAnswer((_) async => const SyncFlushReport.skipped());
      final pushing = build(engine: engine);

      final expense = (await pushing.save(
        _draft(),
      )).fold((f) => fail('$f'), (e) => e);
      await db.update('expenses', {'expense_number': 'DEP-1'});
      await pushing.withdraw(expense);

      verify(() => engine.flush()).called(2);
    });
  });

  group('retrait', () {
    test('dépense connue du serveur : retrait local + geste en file', () async {
      final expense = await saved(_draft());
      await db.update('expenses', {'expense_number': 'DEP-1'});

      await repo.withdraw(expense);

      final row = (await ExpenseReadDao(db).find('e-new'))!;
      expect(row.deletedAt, isNotNull);
      expect(row.withdrawalPendingAt, row.deletedAt);
      final withdrawal = (await outbox()).firstWhere(
        (e) => e['aggregate_type'] == 'EXPENSE_WITHDRAWAL',
      );
      expect(jsonDecode(withdrawal['payload'] as String)['deleted'], isTrue);
    });

    test('jamais acceptée : retrait sur le poste seul, l’envoi refusé est '
        'neutralisé — rien n’attendra un numéro qui ne viendra pas', () async {
      final expense = await saved(_draft());
      await db.update('expenses', {'sync_status': 'SYNC_ERROR'});
      await db.update('outbox', {'status': 'SYNC_ERROR'});

      await repo.withdraw(expense);

      final entries = await outbox();
      expect(entries.map((e) => e['aggregate_type']), ['EXPENSE']);
      expect(entries.single['status'], 'ACKED');
      expect((await ExpenseReadDao(db).find('e-new'))!.deletedAt, isNotNull);

      await repo.restore(expense);
      expect((await ExpenseReadDao(db).find('e-new'))!.deletedAt, isNull);
      expect(
        await outbox(),
        hasLength(1),
        reason: 'restaurer ne remet rien en file',
      );
    });
  });

  test('loadRegister : types, registre, taux du jour et rentrée', () async {
    await ExpenseTypeDao(db).replaceForSchool([
      const ExpenseTypeLocalModel(
        id: 't-elec',
        schoolId: 'school-1',
        code: 'ELECTRICITE',
        label: 'Électricité & eau',
        shortLabel: '',
        icon: 'power',
        color: '#D9A24E',
        softColor: '#FBF3E3',
        defaultCurrency: 'CDF',
      ),
    ], schoolId: 'school-1');
    await saved(_draft());

    final snapshot = (await repo.loadRegister()).fold(
      (f) => fail('$f'),
      (s) => s,
    );

    expect(snapshot.types.single.shortLabel, 'Électricité & eau');
    expect(snapshot.expenses.single.id, 'e-new');
    expect(snapshot.usdToCdf?.rateMicros, 2800 * ExchangeRate.scale);
    expect(snapshot.anchor.month, 9);
    expect(snapshot.anchor.day, 7);
  });

  group('thread', () {
    Future<void> writeMessage(
      String id, {
      required String createdAt,
      String? act,
      String body = 'Un mot',
    }) => db.insert('expense_messages', {
      'id': id,
      'school_id': 'school-1',
      'expense_id': 'e-new',
      'body': body,
      'act': act,
      'author_id': 'u-1',
      'author_name': 'Moke Junior',
      'created_at': createdAt,
      'sync_status': 'SYNCED',
    });

    test('le fil remonte en entités, du plus ancien au plus récent', () async {
      await saved(_draft());
      await writeMessage(
        'm-2',
        createdAt: '2026-09-20T09:00:00.000Z',
        act: 'APPROVAL',
        body: 'Accordée',
      );
      await writeMessage(
        'm-1',
        createdAt: '2026-09-20T08:00:00.000Z',
        act: 'DEPOSIT',
        body: 'Déposée',
      );

      final thread = (await repo.thread(
        'e-new',
      )).fold((f) => fail('$f'), (m) => m);

      expect([for (final m in thread) m.body], ['Déposée', 'Accordée']);
      expect(thread.first.act, ExpenseAct.deposit);
      expect(thread.last.act, ExpenseAct.approval);
    });

    test('un message dont l’horloge est illisible est ÉCARTÉ, pas placé au '
        'hasard', () async {
      await saved(_draft());
      await writeMessage('m-ok', createdAt: '2026-09-20T08:00:00.000Z');
      await writeMessage('m-cassé', createdAt: 'hier');

      final thread = (await repo.thread(
        'e-new',
      )).fold((f) => fail('$f'), (m) => m);

      expect(thread, hasLength(1));
      expect(thread.single.id, 'm-ok');
    });

    test('une demande sans message rend un fil VIDE — pas une panne', () async {
      await saved(_draft());

      expect(
        (await repo.thread('e-new')).fold((f) => fail('$f'), (m) => m),
        isEmpty,
      );
    });
  });

  group('applyGesture', () {
    late ExpenseRepositoryImpl gestes;

    setUp(() => gestes = build(ids: _SeqIds()));

    Future<Map<String, Object?>> row(String id) async =>
        (await db.query('expenses', where: 'id = ?', whereArgs: [id])).single;

    Future<List<Map<String, Object?>>> fil() =>
        db.query('expense_messages', orderBy: 'created_at, id');

    /// La demande est déposée par `u-1` ; le décideur se connecte ensuite.
    Future<Expense> deposeeParUnCollegue() async {
      final expense = await saved(_draft());
      user.set('u-direction', schoolId: 'school-1');
      return expense;
    }

    test('approuver déplace la demande ET écrit son acte au fil', () async {
      final expense = await deposeeParUnCollegue();

      final result = await gestes.applyGesture(
        expense,
        ExpenseGesture.approve,
        actorName: 'Mbala Thérèse',
      );

      expect(result.isRight(), isTrue);
      final ligne = await row('e-new');
      expect(ligne['status'], ExpenseStatus.approved.wireValue);
      expect(ligne['decided_by_id'], 'u-direction');
      expect(ligne['decided_by_name'], 'Mbala Thérèse');
      expect(ligne['decided_at'], _now.toUtc().toIso8601String());

      final messages = await fil();
      expect(messages, hasLength(1));
      expect(messages.single['act'], ExpenseAct.approval.wireValue);
      expect(messages.single['author_id'], 'u-direction');
      expect(messages.single['sync_status'], ExpenseSyncState.pending.dbValue);
    });

    test(
      'un geste ne met RIEN en file : la remontée arrive à DEP-14',
      () async {
        final expense = await deposeeParUnCollegue();
        final avant = (await outbox()).length;

        await gestes.applyGesture(expense, ExpenseGesture.approve);

        // Une entrée d'outbox posée ici partirait sur une route que le serveur
        // ne sert pas encore, pour un 400 terminal.
        expect((await outbox()).length, avant);
      },
    );

    test('refuser SANS motif est refusé sur place, et n\'écrit rien', () async {
      final expense = await deposeeParUnCollegue();

      final result = await gestes.applyGesture(expense, ExpenseGesture.refuse);

      // Le miroir local du `422 REASON_REQUIRED` : laisser partir le geste
      // fabriquerait une ligne « à corriger » pour une faute de saisie.
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(await fil(), isEmpty);
      expect((await row('e-new'))['status'], ExpenseStatus.pending.wireValue);
    });

    test(
      'refuser porte son motif sur la ligne ET dans le corps du message',
      () async {
        final expense = await deposeeParUnCollegue();

        await gestes.applyGesture(
          expense,
          ExpenseGesture.refuse,
          note: '  Devis non joint  ',
        );

        expect((await row('e-new'))['decision_reason'], 'Devis non joint');
        expect((await fil()).single['body'], 'Devis non joint');
      },
    );

    test('approuver SA PROPRE demande est refusé — jamais offert, jamais '
        'accepté', () async {
      // A11 : l'auto-approbation est refusée par la direction, sans réglage
      // d'école. L'écran masque les deux boutons ; le dépôt ne s'y fie pas.
      final expense = await saved(_draft());

      final result = await gestes.applyGesture(expense, ExpenseGesture.approve);

      expect(result.fold((f) => f, (_) => null), isA<ConflictFailure>());
      expect(await fil(), isEmpty);
    });

    test('payer après approbation pose la date de règlement, et garde le '
        'décideur', () async {
      final expense = await deposeeParUnCollegue();
      await gestes.applyGesture(
        expense,
        ExpenseGesture.approve,
        actorName: 'Mbala Thérèse',
      );

      final result = await gestes.applyGesture(expense, ExpenseGesture.pay);

      expect(result.isRight(), isTrue);
      final ligne = await row('e-new');
      expect(ligne['status'], ExpenseStatus.paid.wireValue);
      expect(ligne['paid_on'], '2026-09-12');
      // Payer ne décide pas : l'écran continue de nommer qui a accordé.
      expect(ligne['decided_by_name'], 'Mbala Thérèse');
      expect(await fil(), hasLength(2));
    });

    test('relancer sa demande monte le compteur sans la déplacer', () async {
      final expense = await saved(_draft());

      await gestes.applyGesture(expense, ExpenseGesture.remind);

      final ligne = await row('e-new');
      expect(ligne['reminder_count'], 1);
      expect(ligne['status'], ExpenseStatus.pending.wireValue);
    });

    test(
      'annuler la décision efface décideur, motif, règlement et compteur',
      () async {
        final expense = await deposeeParUnCollegue();
        await gestes.applyGesture(
          expense,
          ExpenseGesture.refuse,
          note: 'Devis non joint',
        );

        await gestes.applyGesture(expense, ExpenseGesture.reopen);

        final ligne = await row('e-new');
        expect(ligne['status'], ExpenseStatus.pending.wireValue);
        expect(ligne['decided_by_id'], isNull);
        expect(ligne['decision_reason'], isNull);
        expect(ligne['paid_on'], isNull);
        expect(ligne['reminder_count'], 0);
        // Le retour en attente n'efface JAMAIS le fil : l'historique reste
        // lisible, seule la situation courante est réécrite.
        expect(await fil(), hasLength(2));
      },
    );

    test('un geste jugé sur une copie PÉRIMÉE est abandonné', () async {
      final perimee = await deposeeParUnCollegue();
      await gestes.applyGesture(perimee, ExpenseGesture.approve);

      // `perimee` dit encore « en attente » ; la ligne, elle, est accordée.
      final result = await gestes.applyGesture(perimee, ExpenseGesture.approve);

      // Un CONFLIT, pas une saisie invalide : rien à corriger dans ce que
      // l'agent a tapé, donc l'écran ne doit pas lui dire « Réessayez ».
      expect(result.fold((f) => f, (_) => null), isA<ConflictFailure>());
      expect(await fil(), hasLength(1));
    });

    test('sans agent connecté, aucun geste ne s\'écrit', () async {
      final expense = await saved(_draft());
      user.set(null, schoolId: 'school-1');

      final result = await gestes.applyGesture(expense, ExpenseGesture.remind);

      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(await fil(), isEmpty);
    });

    test('une demande inconnue du registre rend NotFound', () async {
      final expense = await saved(_draft());
      await db.delete('expenses', where: 'id = ?', whereArgs: ['e-new']);

      final result = await gestes.applyGesture(expense, ExpenseGesture.remind);

      expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
    });
  });
}
