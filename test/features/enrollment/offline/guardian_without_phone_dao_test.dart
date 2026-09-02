import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';

import '../../offline_full_db.dart';

/// Ce que le rapprochement par nom garantit **à travers le DAO**, et que la
/// règle pure ne prouve pas seule : le rejeu.
///
/// Sans numéro, `upsertParentByPhone` n'a plus de clé et insérerait une fiche
/// neuve à chaque passage sur l'étape Tuteurs. Le dossier accumulerait des
/// doublons du même parent, un par sauvegarde — et l'opérateur n'a aucune raison
/// de repasser sur cette étape une seule fois.
///
/// Le piège que ces tests gardent : `student_parent` est purgé AVANT la boucle
/// d'upsert. La photo des tuteurs doit être prise avant, sinon la règle ne voit
/// jamais personne et ne rapproche jamais rien — verte en unitaire, inerte en
/// vrai.
void main() {
  late Database db;
  late EnrollmentDraftDao draftDao;

  setUp(() async {
    db = await openFullOfflineDb();
    draftDao = EnrollmentDraftDao(db);
  });

  tearDown(() async => db.close());

  ParentLocalModel parent({
    required String id,
    String firstName = 'Willy',
    String lastName = 'Ndombo',
    String? surname,
    String? phoneNumber,
  }) => ParentLocalModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    phoneNumber: phoneNumber,
    updatedAt: 100,
  );

  ParentDraft draft(ParentLocalModel p) =>
      ParentDraft(parent: p, relationshipType: 'FATHER');

  Future<List<Map<String, Object?>>> parentsInDb() =>
      db.query('parents', orderBy: 'id');

  Future<List<Map<String, Object?>>> linksOf(String studentId) => db.query(
    'student_parent',
    where: 'student_id = ?',
    whereArgs: [studentId],
  );

  test(
    'un tuteur sans numéro s\'enregistre, et le rejeu ne le double pas',
    () async {
      await draftDao.replaceDraftParents('stu-1', [
        draft(parent(id: 'par-1')),
      ], nowMs: 100);

      expect(await parentsInDb(), hasLength(1));

      // Deuxième passage sur l'étape Tuteurs : l'UI forge un id neuf pour une
      // saisie qu'elle croit neuve. C'est la règle de nom, et elle seule, qui
      // reconnaît le tuteur déjà au dossier.
      await draftDao.replaceDraftParents('stu-1', [
        draft(parent(id: 'par-2')),
      ], nowMs: 200);

      final rows = await parentsInDb();
      expect(rows, hasLength(1), reason: 'le rejeu a créé un doublon');
      expect(rows.single['id'], 'par-1');
      expect(rows.single['phone_number'], isNull);

      final links = await linksOf('stu-1');
      expect(links, hasLength(1));
      expect(links.single['parent_id'], 'par-1');
    },
  );

  /// La conséquence assumée de la V117, et il faut qu'elle soit visible : le
  /// téléphone prouvait qu'un tuteur de deux fratries était la même personne ;
  /// son absence ne prouve plus rien.
  test('un tuteur sans numéro n\'est JAMAIS partagé avec la fratrie', () async {
    await draftDao.replaceDraftParents('stu-1', [
      draft(parent(id: 'par-1')),
    ], nowMs: 100);
    await draftDao.replaceDraftParents('stu-2', [
      draft(parent(id: 'par-2')),
    ], nowMs: 200);

    final rows = await parentsInDb();
    expect(rows, hasLength(2), reason: 'deux dossiers, deux fiches');
    expect((await linksOf('stu-1')).single['parent_id'], 'par-1');
    expect((await linksOf('stu-2')).single['parent_id'], 'par-2');
  });

  /// Le contrepoint : AVEC un numéro, rien ne change. Le get-or-create reste
  /// global à la tablette, et la dédup fratrie continue de fonctionner.
  test('AVEC un numéro, la dédup fratrie est inchangée', () async {
    await draftDao.replaceDraftParents('stu-1', [
      draft(parent(id: 'par-1', phoneNumber: '+243810220145')),
    ], nowMs: 100);
    await draftDao.replaceDraftParents('stu-2', [
      draft(parent(id: 'par-2', phoneNumber: '0810220145')),
    ], nowMs: 200);

    final rows = await parentsInDb();
    expect(rows, hasLength(1), reason: 'même numéro écrit autrement');
    expect((await linksOf('stu-2')).single['parent_id'], 'par-1');
  });

  test('deux tuteurs sans numéro et de noms différents cohabitent', () async {
    await draftDao.replaceDraftParents('stu-1', [
      draft(parent(id: 'par-1', firstName: 'Willy', lastName: 'Ndombo')),
      draft(parent(id: 'par-2', firstName: 'Jeanne', lastName: 'Kabongo')),
    ], nowMs: 100);

    expect(await parentsInDb(), hasLength(2));
    expect(await linksOf('stu-1'), hasLength(2));
  });

  /// Le tuteur nommé rejoint celui qui n'a pas de numéro sans l'écraser : deux
  /// personnes, deux fiches.
  test(
    'un tuteur nommé et un tuteur sans numéro ne se confondent pas',
    () async {
      await draftDao.replaceDraftParents('stu-1', [
        draft(parent(id: 'par-1')),
        draft(parent(id: 'par-2', phoneNumber: '+243810220145')),
      ], nowMs: 100);

      final rows = await parentsInDb();
      expect(rows, hasLength(2));
      expect(
        rows.map((r) => r['phone_number']).toList(),
        containsAll(<Object?>[null, '+243810220145']),
      );
    },
  );
}
