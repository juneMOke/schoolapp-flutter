import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';

void main() {
  group('ExpenseAct.fromWire', () {
    test('les neuf actes se relisent', () {
      for (final act in ExpenseAct.values) {
        expect(ExpenseAct.fromWire(act.wireValue), act);
      }
      expect(ExpenseAct.values, hasLength(9));
    });

    test('un acte INCONNU se lit comme un commentaire libre : un serveur plus '
        'récent ne doit pas faire mentir la vignette', () {
      expect(ExpenseAct.fromWire('DELEGATION'), isNull);
    });

    test('absent ou vide : commentaire libre', () {
      expect(ExpenseAct.fromWire(null), isNull);
      expect(ExpenseAct.fromWire('   '), isNull);
    });
  });

  group('ExpenseMessageLocalModel', () {
    test('l’horloge est rangée en UTC, sous une seule forme — c’est ce qui '
        'permet de la comparer comme une chaîne', () {
      final row = ExpenseMessageLocalModel.at(
        DateTime(2026, 9, 20, 11, 30),
        id: 'm-1',
        schoolId: 'school-1',
        expenseId: 'e-1',
        body: 'Un mot',
        act: ExpenseAct.approval,
      );

      expect(row.createdAt, endsWith('Z'));
      expect(DateTime.parse(row.createdAt).isUtc, isTrue);
      expect(row.act, 'APPROVAL');
      expect(row.syncStatus, ExpenseSyncState.pending.dbValue);
    });

    test('une horloge illisible ne devient PAS un message : il tomberait au '
        'hasard entre deux gestes', () {
      const row = ExpenseMessageLocalModel(
        id: 'm-1',
        schoolId: 'school-1',
        expenseId: 'e-1',
        body: 'Un mot',
        createdAt: 'hier',
      );

      expect(row.toEntity(), isNull);
    });

    test('la ligne se relit entière', () {
      const row = ExpenseMessageLocalModel(
        id: 'm-1',
        schoolId: 'school-1',
        expenseId: 'e-1',
        body: 'Motif du refus',
        act: 'REFUSAL',
        authorId: 'u-9',
        authorName: 'Mbala Thérèse',
        createdAt: '2026-09-20T08:00:00.000Z',
        syncStatus: 'SYNCED',
      );

      final message = row.toEntity()!;

      expect(message.act, ExpenseAct.refusal);
      expect(message.authorId, 'u-9');
      expect(message.createdAt, DateTime.utc(2026, 9, 20, 8));
      expect(message.syncState, ExpenseSyncState.synced);
      expect(message.isComment, isFalse);
      expect(message.isPending, isFalse);
    });

    test('le corps du message ne sort pas par toString() : un motif de refus '
        'nomme des fournisseurs et des collègues', () {
      const row = ExpenseMessageLocalModel(
        id: 'm-1',
        schoolId: 'school-1',
        expenseId: 'e-1',
        body: 'Devis SNEL trop cher',
        createdAt: '2026-09-20T08:00:00.000Z',
      );

      expect(row.toEntity()!.toString(), isNot(contains('SNEL')));
    });
  });

  group('isMine', () {
    ExpenseMessage message({String? authorId}) => ExpenseMessage(
      id: 'm-1',
      expenseId: 'e-1',
      body: 'Un mot',
      authorId: authorId,
      createdAt: DateTime.utc(2026, 9, 20, 8),
    );

    test('le même compte : oui', () {
      expect(message(authorId: 'u-1').isMine('u-1'), isTrue);
    });

    test('un autre compte : non', () {
      expect(message(authorId: 'u-2').isMine('u-1'), isFalse);
    });

    test('DEUX identifiants vides ne se ressemblent pas : une session héritée '
        'sans uid ne s’approprie pas tout le fil', () {
      expect(message(authorId: '').isMine(''), isFalse);
      expect(message(authorId: null).isMine(null), isFalse);
      expect(message(authorId: '').isMine('u-1'), isFalse);
    });
  });
}
