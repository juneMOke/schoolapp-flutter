import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_notation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/course_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockOnlineCourse extends Mock implements CourseRepository {}

class _SeqId implements IdGenerator {
  final String Function() _n;
  const _SeqId(this._n);
  @override
  String newId() => _n();
}

void main() {
  late Database db;
  late AcademicsLocalDataSource local;
  late AcademicsRefLocalDataSource refLocal;
  late CourseOfflineRepositoryImpl repo;
  var idSeq = 0;

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    refLocal = AcademicsRefLocalDataSource(db);
    idSeq = 0;
    repo = CourseOfflineRepositoryImpl(
      online: MockOnlineCourse(),
      academicsLocalDataSource: local,
      academicsRefLocalDataSource: refLocal,
      scheduleRefLocalDataSource: ScheduleRefLocalDataSource(db),
      classroomLocalDataSource: ClassroomLocalDataSource(db),
      evaluationRepository: EvaluationOfflineRepositoryImpl(
        localDataSource: local,
        idGenerator: _SeqId(() => 'ev${idSeq++}'),
        currentUser: CurrentUserContext()..set('me'),
        now: () => 1000,
      ),
    );
  });

  tearDown(() async => db.close());

  Future<void> insertSession(String cours, String subject) =>
      db.insert('ref_recurring_sessions', {
        'id': 's-$cours',
        'academic_year_id': 'ay-1',
        'cours_id': cours,
        'time_slot_id': 't1',
        'day_of_week': 'MON',
        'teacher_id': 'me',
        'classroom_id': 'class-1',
        'teacher_label': 'M. Moi',
        'classroom_label': '3e A',
        'subject_label': subject,
        'synced_at': 1,
      });

  Future<void> insertEval(
    String id,
    String type,
    String cours, {
    String? sousPeriode,
    String? periode,
  }) => db.insert('evaluation', {
    'id': id,
    'cours_id': cours,
    'type': type,
    'eval_date': DateTime.utc(2026, 6, 10).millisecondsSinceEpoch,
    'max_points': 20.0,
    'poids': 1,
    'sous_periode_id': sousPeriode,
    'periode_scolaire_id': periode,
    'updated_at': 1,
    'sync_status': 'SYNCED',
  });

  test('getMyCourses : groupe par classe, sans filtre d\'identité côté client '
      '(DF-K, sessions déjà scopées enseignant par le pull)', () async {
    await insertSession('co1', 'Maths');
    await db.insert('ref_classrooms', {
      'id': 'class-1',
      'academic_year_id': 'ay-1',
      'name': '3ème A',
      'total_count': 30,
    });

    final summaries = (await repo.getMyCourses()).getOrElse(() => fail('Left'));
    expect(summaries.single.classroom.name, '3ème A');
    expect(summaries.single.courses.single.id, 'co1');
  });

  group('getCoursNotationDetail (squelette + évals locales)', () {
    setUp(() async {
      await refLocal.upsertCoursNotation(
        const RefCoursNotationRow(
          coursId: 'co1',
          classroomId: 'class-1',
          brancheNom: 'Maths',
          effectif: 2,
          periodesJson:
              '[{"periodeScolaireId":"p1","ordre":1,"statut":"OUVERTE",'
              '"sousPeriodes":[{"sousPeriodeId":"sp1","ordre":1,'
              '"statut":"OUVERTE"}]}]',
          syncedAt: 1,
        ),
      );
      await insertEval('e-int', 'INTERRO', 'co1', sousPeriode: 'sp1');
      await insertEval('e-exam', 'EXAMEN', 'co1', periode: 'p1');
      // 2 notes NOTEE sur l'interro (effectif 2 → COMPLETE) ; 0 sur l'examen.
      for (final s in ['s1', 's2']) {
        await db.insert('note_evaluation', {
          'id': 'n-$s',
          'evaluation_id': 'e-int',
          'student_id': s,
          'points_obtenus': 12.0,
          'statut': 'NOTEE',
          'updated_at': 1,
          'sync_status': 'SYNCED',
        });
      }
    });

    test(
      'compose l\'arbre + taux de saisie dérivé ; moyennes null (ADR-006)',
      () async {
        final detail = (await repo.getCoursNotationDetail(
          'co1',
        )).getOrElse(() => fail('Left'));

        expect(detail.effectif, 2);
        expect(detail.brancheNom, 'Maths');
        final periode = detail.periodes.single;
        expect(periode.periodeScolaireId, 'p1');
        expect(periode.statut, StatutPeriode.ouverte);

        final sp = periode.sousPeriodes.single;
        expect(
          sp.moyenneClasse,
          isNull,
          reason: 'calcul d\'ensemble = serveur',
        );
        final groupe = sp.evaluationsParType.single;
        expect(groupe.type, TypeEvaluation.interro);
        final interro = groupe.evaluations.single;
        expect(interro.id, 'e-int');
        expect(interro.statutSaisie, StatutSaisieEvaluation.complete);
        expect(interro.pourcentageSaisie, 100);

        // L'examen est rattaché à la période, taux dérivé (0 note → nonSaisie).
        expect(periode.examen!.evaluationId, 'e-exam');
        expect(periode.examen!.statutSaisie, StatutSaisieEvaluation.nonSaisie);
      },
    );

    test('squelette absent → délègue à l\'online', () async {
      final online = MockOnlineCourse();
      final repo2 = CourseOfflineRepositoryImpl(
        online: online,
        academicsLocalDataSource: local,
        academicsRefLocalDataSource: refLocal,
        scheduleRefLocalDataSource: ScheduleRefLocalDataSource(db),
        classroomLocalDataSource: ClassroomLocalDataSource(db),
        evaluationRepository: EvaluationOfflineRepositoryImpl(
          localDataSource: local,
          idGenerator: _SeqId(() => 'x'),
          now: () => 1,
        ),
      );
      when(
        () => online.getCoursNotationDetail('absent'),
      ).thenAnswer((_) async => const Left(NotFoundFailure('absent')));

      await repo2.getCoursNotationDetail('absent');
      verify(() => online.getCoursNotationDetail('absent')).called(1);
    });
  });

  group('createEvaluation (régime A, offline)', () {
    test('crée la ligne PENDING + renvoie l\'Evaluation', () async {
      final result = await repo.createEvaluation(
        'co1',
        CreateEvaluationRequest.journaliere(
          type: TypeEvaluation.interro,
          date: DateTime.utc(2026, 6, 10),
          maxPoints: 20,
          poids: 1,
          sousPeriodeId: 'sp1',
        ),
      );

      final eval = result.getOrElse(() => fail('Left'));
      expect(eval.coursId, 'co1');
      expect(eval.type, TypeEvaluation.interro);
      final stored = await local.getEvaluation(eval.id);
      expect(stored!.syncState, SyncState.pendingSync);
    });
  });
}
