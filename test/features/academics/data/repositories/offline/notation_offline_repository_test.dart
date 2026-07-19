import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notes_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  late AcademicsLocalDataSource local;
  late AcademicsRefLocalDataSource refLocal;
  late NotationOfflineRepositoryImpl repo;

  var idSeq = 0;

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    refLocal = AcademicsRefLocalDataSource(db);
    idSeq = 0;
    final notesRepo = NotesOfflineRepositoryImpl(
      localDataSource: local,
      idGenerator: _SeqIdGenerator(() => 'n${idSeq++}'),
      currentUser: CurrentUserContext()..set('teacher'),
      now: () => 5000,
    );
    repo = NotationOfflineRepositoryImpl(
      localDataSource: local,
      refLocalDataSource: refLocal,
      rosterDataSource: ClassroomLocalDataSource(db),
      notesRepository: notesRepo,
    );

    // Cours co1 dans la classe class-1.
    await db.insert('ref_cours', {
      'id': 'co1',
      'classroom_id': 'class-1',
      'ligne_bareme_id': 'lb-1',
      'synced_at': 1,
    });
    // Évaluation ev-1 (SYNCED, pullée).
    await db.insert('evaluation', {
      'id': 'ev-1',
      'cours_id': 'co1',
      'type': 'INTERRO',
      'eval_date': 1,
      'max_points': 20.0,
      'poids': 1,
      'updated_at': 1,
      'sync_status': 'SYNCED',
    });
    // Roster : 2 ACTIVE + 1 INACTIVE.
    for (final m in [
      ('m1', 's1', 'Amina', 'Kalala', 'ACTIVE'),
      ('m2', 's2', 'Jean', 'Dupont', 'ACTIVE'),
      ('m3', 's3', 'Parti', 'Ailleurs', 'INACTIVE'),
    ]) {
      await db.insert('ref_classroom_members', {
        'id': m.$1,
        'student_id': m.$2,
        'classroom_id': 'class-1',
        'academic_year_id': 'ay-1',
        'student_first_name': m.$3,
        'student_last_name': m.$4,
        'status': m.$5,
      });
    }
  });

  tearDown(() async => db.close());

  group('getNotesEleves (composition roster + notes locales)', () {
    test('une ligne par élève ACTIF ; note surchargée, sinon nulle', () async {
      // s1 a déjà une note locale ; s2 non ; s3 inactif exclu.
      await db.insert('note_evaluation', {
        'id': 'nx',
        'evaluation_id': 'ev-1',
        'student_id': 's1',
        'points_obtenus': 14.5,
        'statut': 'NOTEE',
        'updated_at': 10,
        'sync_status': 'SYNCED',
      });

      final result = await repo.getNotesEleves('ev-1');

      final eleves = result.getOrElse(() => fail('Left'));
      expect(eleves.length, 2, reason: 's3 INACTIVE exclu');
      final byId = {for (final e in eleves) e.studentId: e};
      expect(byId['s1']!.pointsObtenus, 14.5);
      expect(byId['s1']!.statut, StatutNote.notee);
      expect(byId['s2']!.pointsObtenus, isNull, reason: 'pas encore saisi');
      expect(byId['s2']!.statut, isNull);
    });

    test('évaluation absente → NotFoundFailure', () async {
      final result = await repo.getNotesEleves('inconnue');
      expect(result.isLeft(), isTrue);
    });
  });

  group('saisirNote (écriture → outbox régime C)', () {
    test(
      'persiste la note PENDING + enfile un lot, renvoie la NoteEvaluation',
      () async {
        final result = await repo.saisirNote(
          'ev-1',
          SaisirNoteRequest.forStatut(
            studentId: 's2',
            statut: StatutNote.notee,
            pointsObtenus: 16,
          ),
        );

        final note = result.getOrElse(() => fail('Left'));
        expect(note.studentId, 's2');
        expect(note.pointsObtenus, 16);
        expect(note.statut, StatutNote.notee);

        final stored = await local.getNotesForEvaluation('ev-1');
        expect(stored.single.studentId, 's2');
        expect(stored.single.syncState, SyncState.pendingSync);
      },
    );
  });
}

class _SeqIdGenerator implements IdGenerator {
  final String Function() _next;
  const _SeqIdGenerator(this._next);
  @override
  String newId() => _next();
}
