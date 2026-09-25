import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

/// Le fil d'une demande : lecture ordonnée, et un ajout qui ne touche à rien
/// d'autre que la fraîcheur.
void main() {
  late Database db;
  late ExpenseMessageDao dao;

  const clock = '2026-09-20T08:00:00.000Z';

  Future<void> seedExpense(String id) => db.insert('expenses', {
    'id': id,
    'school_id': 'school-1',
    'type_id': 't-elec',
    'title': 'Facture SNEL',
    'amount_in_cents': 38500000,
    'currency': 'CDF',
    'status': 'PENDING',
    'expense_date': '2026-09-03',
    'client_updated_at': clock,
    'sync_status': ExpenseSyncState.synced.dbValue,
    'updated_at': 42,
  });

  ExpenseMessageLocalModel message(
    String id, {
    required String createdAt,
    String expenseId = 'e-1',
    ExpenseAct? act,
    String body = 'Un mot',
    String? authorId = 'u-1',
  }) => ExpenseMessageLocalModel(
    id: id,
    schoolId: 'school-1',
    expenseId: expenseId,
    body: body,
    act: act?.wireValue,
    authorId: authorId,
    authorName: 'Mbala Thérèse',
    createdAt: createdAt,
  );

  Future<Map<String, Object?>> expenseRow(String id) async =>
      (await db.query('expenses', where: 'id = ?', whereArgs: [id])).single;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ExpenseMessageDao(db);
    await seedExpense('e-1');
  });

  tearDown(() => db.close());

  group('threadFor', () {
    test('le fil se lit du plus ancien au plus récent', () async {
      await dao.append(
        message('m-2', createdAt: '2026-09-20T09:00:00.000Z', body: 'second'),
      );
      await dao.append(
        message('m-1', createdAt: '2026-09-20T08:30:00.000Z', body: 'premier'),
      );

      final thread = await dao.threadFor('e-1', schoolId: 'school-1');

      expect([for (final m in thread) m.body], ['premier', 'second']);
    });

    test('deux messages sur la même horloge se classent par identifiant : sans '
        'cela, leur ordre dépendrait du plan de SQLite', () async {
      const same = '2026-09-20T08:30:00.000Z';
      await dao.append(message('m-b', createdAt: same, body: 'b'));
      await dao.append(message('m-a', createdAt: same, body: 'a'));

      final thread = await dao.threadFor('e-1', schoolId: 'school-1');

      expect([for (final m in thread) m.body], ['a', 'b']);
    });

    test('le fil d’une AUTRE ÉCOLE ne s’y invite pas non plus', () async {
      await db.insert('expense_messages', {
        'id': 'm-ailleurs',
        'school_id': 'school-2',
        'expense_id': 'e-1',
        'body': 'chez le voisin',
        'created_at': clock,
      });

      expect(await dao.threadFor('e-1', schoolId: 'school-1'), isEmpty);
    });

    test('le fil d’une autre demande ne s’y invite pas', () async {
      await seedExpense('e-2');
      await dao.append(message('m-1', createdAt: clock));
      await dao.append(
        message('m-2', createdAt: clock, expenseId: 'e-2', body: 'ailleurs'),
      );

      final thread = await dao.threadFor('e-1', schoolId: 'school-1');

      expect(thread, hasLength(1));
      expect(thread.single.id, 'm-1');
    });
  });

  group('append', () {
    test('le message entre, la fraîcheur du fil monte — et le CONTENU de la '
        'demande ne bouge pas d’un octet', () async {
      await dao.append(
        message(
          'm-1',
          createdAt: '2026-09-20T09:00:00.000Z',
          act: ExpenseAct.approval,
        ),
      );

      final row = await expenseRow('e-1');
      expect(row['last_message_at'], '2026-09-20T09:00:00.000Z');
      // C'est le défaut du fil de la Discipline, et il est interdit ici : un
      // message qui salit le contenu le repousserait pour rien, et surtout
      // ferait perdre une décision à l'arbitrage.
      expect(row['client_updated_at'], clock);
      expect(row['sync_status'], ExpenseSyncState.synced.dbValue);
      expect(row['updated_at'], 42);
    });

    test('rejouer le même message est inerte : l’uuid est la clé '
        'd’idempotence du geste', () async {
      final only = message('m-1', createdAt: clock, act: ExpenseAct.reminder);
      await dao.append(only);
      await dao.append(only);

      expect(await dao.threadFor('e-1', schoolId: 'school-1'), hasLength(1));
    });

    test('la fraîcheur du fil ne recule JAMAIS — un message plus ancien '
        'appliqué après ne rend pas la demande plus calme', () async {
      await dao.append(message('m-2', createdAt: '2026-09-20T09:00:00.000Z'));
      await dao.append(message('m-1', createdAt: '2026-09-20T08:30:00.000Z'));

      expect(
        (await expenseRow('e-1'))['last_message_at'],
        '2026-09-20T09:00:00.000Z',
      );
    });

    test('un message sur une demande inconnue s’écrit quand même : c’est le '
        'pull qui posera la ligne, et le fil ne se perd pas', () async {
      await dao.append(
        message('m-1', createdAt: clock, expenseId: 'e-inconnue'),
      );

      expect(
        await dao.threadFor('e-inconnue', schoolId: 'school-1'),
        hasLength(1),
      );
    });
  });

  group('appendGesture', () {
    test('la demande bouge et le fil s\u2019allonge, dans la m\u00eame '
        'transaction', () async {
      final applique = await dao.appendGesture(
        message('m-1', createdAt: clock, act: ExpenseAct.approval),
        columns: const {
          'status': 'APPROVED',
          'decided_by_id': 'u-direction',
          'decided_at': clock,
        },
      );

      final row = await expenseRow('e-1');
      expect(applique, isTrue);
      expect(row['status'], 'APPROVED');
      expect(row['decided_by_id'], 'u-direction');
      expect(row['last_message_at'], clock);
      expect(await dao.threadFor('e-1', schoolId: 'school-1'), hasLength(1));
    });

    test('un geste ne touche ni au contenu ni \u00e0 la synchro de la '
        'd\u00e9pense', () async {
      await dao.appendGesture(
        message('m-1', createdAt: clock, act: ExpenseAct.payment),
        columns: const {'status': 'PAID', 'paid_on': '2026-09-20'},
      );

      final row = await expenseRow('e-1');
      // Le geste voyage seul (Q1) : repousser le contenu lui ferait perdre
      // une d\u00e9cision \u00e0 l'arbitrage du dernier \u00e9crit.
      expect(row['client_updated_at'], clock);
      expect(row['sync_status'], ExpenseSyncState.synced.dbValue);
      expect(row['updated_at'], 42);
    });

    test('relancer monte le compteur d\u2019un, et deux relances comptent '
        'deux', () async {
      await dao.appendGesture(
        message('m-1', createdAt: clock, act: ExpenseAct.reminder),
        bumpsReminder: true,
      );
      expect((await expenseRow('e-1'))['reminder_count'], 1);

      await dao.appendGesture(
        message(
          'm-2',
          createdAt: '2026-09-21T08:00:00.000Z',
          act: ExpenseAct.reminder,
        ),
        bumpsReminder: true,
      );
      expect((await expenseRow('e-1'))['reminder_count'], 2);
    });

    test('rejouer le m\u00eame geste est INERTE : le compteur ne compte pas '
        'double', () async {
      // L'uuid du message est la cl\u00e9 d'idempotence du geste (Q3), la
      // m\u00eame que celle du serveur. C'est ce qui s\u00e9pare
      // `appendGesture` d'`append`, qui \u00e9crase d\u00e9lib\u00e9r\u00e9ment
      // parce qu'il sert le pull.
      final relance = message(
        'm-1',
        createdAt: clock,
        act: ExpenseAct.reminder,
      );
      expect(await dao.appendGesture(relance, bumpsReminder: true), isTrue);
      expect(await dao.appendGesture(relance, bumpsReminder: true), isFalse);

      expect((await expenseRow('e-1'))['reminder_count'], 1);
      expect(await dao.threadFor('e-1', schoolId: 'school-1'), hasLength(1));
    });

    test('un rejeu ne d\u00e9fait pas non plus la colonne d\u00e9j\u00e0 '
        '\u00e9crite', () async {
      final geste = message('m-1', createdAt: clock, act: ExpenseAct.approval);
      await dao.appendGesture(geste, columns: const {'status': 'APPROVED'});
      await dao.appendGesture(geste, columns: const {'status': 'PENDING'});

      expect((await expenseRow('e-1'))['status'], 'APPROVED');
    });

    test(
      'commenter n\u2019\u00e9crit que le fil et sa fra\u00eecheur',
      () async {
        await dao.appendGesture(message('m-1', createdAt: clock));

        final row = await expenseRow('e-1');
        expect(row['status'], 'PENDING');
        expect(row['last_message_at'], clock);
      },
    );

    test('la fra\u00eecheur ne recule pas davantage par un geste', () async {
      await dao.appendGesture(
        message('m-2', createdAt: '2026-09-20T09:00:00.000Z'),
      );
      await dao.appendGesture(
        message('m-1', createdAt: '2026-09-20T08:30:00.000Z'),
      );

      expect(
        (await expenseRow('e-1'))['last_message_at'],
        '2026-09-20T09:00:00.000Z',
      );
    });
  });
}
