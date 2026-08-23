import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart'
    show kAcademicsCoursBootstrapPrefix;
import 'package:school_app_flutter/features/academics/data/repositories/offline/course_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart'
    show kGradesReferentialResource;
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';

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
  late SyncMetaDao syncMetaDao;
  late CourseOfflineRepositoryImpl repo;
  var idSeq = 0;

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    refLocal = AcademicsRefLocalDataSource(db);
    syncMetaDao = SyncMetaDao(db);
    idSeq = 0;
    repo = CourseOfflineRepositoryImpl(
      online: MockOnlineCourse(),
      academicsLocalDataSource: local,
      academicsRefLocalDataSource: refLocal,
      classroomLocalDataSource: ClassroomLocalDataSource(db),
      evaluationRepository: EvaluationOfflineRepositoryImpl(
        localDataSource: local,
        idGenerator: _SeqId(() => 'ev${idSeq++}'),
        currentUser: CurrentUserContext()..set('me'),
        now: () => 1000,
      ),
      syncMetaDao: syncMetaDao,
      referentialDao: EnrollmentReferentialDao(db),
      currentUser: CurrentUserContext()..set(null, schoolId: 'school-1'),
    );
  });

  tearDown(() async => db.close());

  /// Marque `ref_cours` et le bundle `grades-referential` comme ayant terminé
  /// leur premier cycle — sinon `getMyCourses` replie sur l'online (guide §4).
  Future<void> markReferentialsBootstrapped() async {
    await syncMetaDao.setCursor(
      kAcademicsCoursBootstrapPrefix,
      cursor: 'DONE',
      syncedAt: 1,
    );
    await syncMetaDao.setCursor(
      kGradesReferentialResource,
      cursor: 'etag-1',
      syncedAt: 1,
    );
  }

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

  group(
    'getMyCourses (jointure ref_cours → ref_ligne_bareme → ref_branche)',
    () {
      test(
        'groupe par classe, triés par ordre du barème, sans filtre d\'identité '
        'côté client (DF-K, ref_cours déjà scopé enseignant par le pull)',
        () async {
          await markReferentialsBootstrapped();
          await db.insert('ref_branche', {'id': 'b1', 'nom': 'Maths'});
          await db.insert('ref_branche', {'id': 'b2', 'nom': 'Français'});
          await db.insert('ref_ligne_bareme', {
            'id': 'lb1',
            'grille_id': 'g1',
            'rubrique_id': 'r1',
            'branche_id': 'b1',
            'ordre': 2,
            'max_journalier_par_sous_periode': 2,
          });
          await db.insert('ref_ligne_bareme', {
            'id': 'lb2',
            'grille_id': 'g1',
            'rubrique_id': 'r2',
            'branche_id': 'b2',
            'ordre': 1,
            'max_journalier_par_sous_periode': 2,
          });
          await db.insert('ref_cours', {
            'id': 'co-maths',
            'classroom_id': 'class-1',
            'ligne_bareme_id': 'lb1',
            'synced_at': 1,
          });
          await db.insert('ref_cours', {
            'id': 'co-francais',
            'classroom_id': 'class-1',
            'ligne_bareme_id': 'lb2',
            'synced_at': 1,
          });
          await db.insert('ref_classrooms', {
            'id': 'class-1',
            'academic_year_id': 'ay-1',
            'name': '3ème A',
            'total_count': 30,
          });

          final summaries = (await repo.getMyCourses()).getOrElse(
            () => fail('Left'),
          );

          expect(summaries.single.classroom.name, '3ème A');
          // Ordre du BARÈME (lb2 ordre=1 avant lb1 ordre=2), pas l'uuid.
          expect(summaries.single.courses.map((c) => c.id).toList(), [
            'co-francais',
            'co-maths',
          ]);
        },
      );

      test(
        'cours sans ligne de barème/branche en cache → classe masquée',
        () async {
          await markReferentialsBootstrapped();
          await db.insert('ref_cours', {
            'id': 'co-orphan',
            'classroom_id': 'class-1',
            'ligne_bareme_id': 'lb-unknown',
            'synced_at': 1,
          });

          final summaries = (await repo.getMyCourses()).getOrElse(
            () => fail('Left'),
          );
          expect(summaries, isEmpty);
        },
      );

      test(
        'un cours porté par une classe d\'une année PRÉCÉDENTE ne remonte pas '
        '(ref_cours n\'a pas d\'année : elle vient de la classe)',
        () async {
          await markReferentialsBootstrapped();
          // Le référentiel sait quelle année est courante.
          await db.insert('ref_academic_years', {
            'id': 'ay-courante',
            'name': '2026-2027',
            'is_current': 1,
            'school_id': 'school-1',
          });
          await db.insert('ref_academic_years', {
            'id': 'ay-passee',
            'name': '2025-2026',
            'is_current': 0,
            'school_id': 'school-1',
          });
          await db.insert('ref_branche', {'id': 'b1', 'nom': 'Maths'});
          await db.insert('ref_ligne_bareme', {
            'id': 'lb1',
            'grille_id': 'g1',
            'rubrique_id': 'r1',
            'branche_id': 'b1',
            'ordre': 1,
            'max_journalier_par_sous_periode': 2,
          });
          // Un cours de l'an dernier, resté en cache : le pull cours est un
          // delta et ne retire jamais rien hors rejeu bootstrap.
          await db.insert('ref_cours', {
            'id': 'co-an-dernier',
            'classroom_id': 'class-an-dernier',
            'ligne_bareme_id': 'lb1',
            'synced_at': 1,
          });
          await db.insert('ref_classrooms', {
            'id': 'class-an-dernier',
            'academic_year_id': 'ay-passee',
            'name': '3ème A (2025-2026)',
            'total_count': 30,
          });

          final summaries = (await repo.getMyCourses()).getOrElse(
            () => fail('Left'),
          );

          expect(
            summaries,
            isEmpty,
            reason: 'la classe appartient à ay-passee, pas à ay-courante',
          );
        },
      );

      test(
        'année courante NON résolue → aucun filtrage (année absente ≠ vide)',
        () async {
          await markReferentialsBootstrapped();
          // Aucune ligne dans ref_academic_years : référentiel pas encore
          // synchronisé pour cette école. Filtrer viderait l'écran d'un prof
          // dont tous les cours sont pourtant légitimes.
          await db.insert('ref_branche', {'id': 'b1', 'nom': 'Maths'});
          await db.insert('ref_ligne_bareme', {
            'id': 'lb1',
            'grille_id': 'g1',
            'rubrique_id': 'r1',
            'branche_id': 'b1',
            'ordre': 1,
            'max_journalier_par_sous_periode': 2,
          });
          await db.insert('ref_cours', {
            'id': 'co1',
            'classroom_id': 'class-1',
            'ligne_bareme_id': 'lb1',
            'synced_at': 1,
          });
          await db.insert('ref_classrooms', {
            'id': 'class-1',
            'academic_year_id': 'ay-quelconque',
            'name': '3ème A',
            'total_count': 30,
          });

          final summaries = (await repo.getMyCourses()).getOrElse(
            () => fail('Left'),
          );

          expect(summaries.single.classroom.name, '3ème A');
          expect(summaries.single.classroomUnsynced, isFalse);
        },
      );

      test('classe absente du cache → cours signalé « non synchronisé », '
          'jamais confondu avec un cours d\'une autre année', () async {
        await markReferentialsBootstrapped();
        await db.insert('ref_academic_years', {
          'id': 'ay-courante',
          'name': '2026-2027',
          'is_current': 1,
          'school_id': 'school-1',
        });
        await db.insert('ref_branche', {'id': 'b1', 'nom': 'Maths'});
        await db.insert('ref_ligne_bareme', {
          'id': 'lb1',
          'grille_id': 'g1',
          'rubrique_id': 'r1',
          'branche_id': 'b1',
          'ordre': 1,
          'max_journalier_par_sous_periode': 2,
        });
        // Le pull des cours a devancé celui des classes.
        await db.insert('ref_cours', {
          'id': 'co-en-attente',
          'classroom_id': 'class-pas-encore-pullee',
          'ligne_bareme_id': 'lb1',
          'synced_at': 1,
        });

        final summaries = (await repo.getMyCourses()).getOrElse(
          () => fail('Left'),
        );

        // Il remonte — sinon l'écran tairait un cours qui n'attend qu'un
        // pull — mais porté par son drapeau, pas par une classe anonyme.
        expect(summaries.single.classroomUnsynced, isTrue);
        expect(summaries.single.courses.single.id, 'co-en-attente');
        expect(summaries.single.classroom.name, isEmpty);
      });

      test(
        'ref_cours ou grades-referential pas encore bootstrappés → repli online',
        () async {
          final online = MockOnlineCourse();
          final repo2 = CourseOfflineRepositoryImpl(
            online: online,
            academicsLocalDataSource: local,
            academicsRefLocalDataSource: refLocal,
            classroomLocalDataSource: ClassroomLocalDataSource(db),
            evaluationRepository: EvaluationOfflineRepositoryImpl(
              localDataSource: local,
              idGenerator: _SeqId(() => 'x'),
              now: () => 1,
            ),
            syncMetaDao: syncMetaDao,
            referentialDao: EnrollmentReferentialDao(db),
          );
          when(
            () => online.getMyCourses(),
          ).thenAnswer((_) async => const Right([]));

          final result = (await repo2.getMyCourses()).getOrElse(
            () => fail('Left'),
          );

          expect(result, isEmpty);
          verify(() => online.getMyCourses()).called(1);
        },
      );
    },
  );

  group('getCoursNotationDetail (bundle grades-referential + évals locales)', () {
    setUp(() async {
      await db.insert('ref_cours', {
        'id': 'co1',
        'classroom_id': 'class-1',
        'ligne_bareme_id': 'lb1',
        'synced_at': 1,
      });
      await db.insert('ref_classrooms', {
        'id': 'class-1',
        'academic_year_id': 'ay-1',
        'school_level_group_id': 'g1',
        'name': '3ème A',
        'total_count': 2,
      });
      await db.insert('ref_classroom_members', {
        'id': 'm-s1',
        'classroom_id': 'class-1',
        'academic_year_id': 'ay-1',
        'student_id': 's1',
        'student_first_name': 'A',
        'student_last_name': 'B',
        'status': 'ACTIVE',
      });
      await db.insert('ref_classroom_members', {
        'id': 'm-s2',
        'classroom_id': 'class-1',
        'academic_year_id': 'ay-1',
        'student_id': 's2',
        'student_first_name': 'C',
        'student_last_name': 'D',
        'status': 'ACTIVE',
      });
      await db.insert('ref_branche', {'id': 'b1', 'nom': 'Maths'});
      await db.insert('ref_ligne_bareme', {
        'id': 'lb1',
        'grille_id': 'g1',
        'rubrique_id': 'r1',
        'branche_id': 'b1',
        'ordre': 1,
        'max_journalier_par_sous_periode': 2,
        'max_examen_par_periode_scolaire': 1,
      });
      await db.insert('ref_periode', {
        'id': 'p1',
        'academic_year_id': 'ay-1',
        'school_level_group_id': 'g1',
        'ordre': 1,
        'statut': 'OUVERTE',
      });
      await db.insert('ref_sous_periode', {
        'id': 'sp1',
        'periode_scolaire_id': 'p1',
        'ordre': 1,
        'statut': 'OUVERTE',
      });
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
      'compose l\'arbre + taux de saisie dérivé ; moyenne de classe '
      'indicative dérivée localement (ADR-006 : la saisie va offline)',
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
        // s1 et s2 : 12/20 (poids 1) chacun → moyenne de classe 60 %.
        expect(sp.moyenneClasse, 60);
        expect(sp.nombreElevesNotes, 2);
        expect(sp.nombreEleves50, 2);
        expect(sp.moyennesEleves.map((m) => m.moyenne).toSet(), {60.0});
        final groupe = sp.evaluationsParType.single;
        expect(groupe.type, TypeEvaluation.interro);
        final interro = groupe.evaluations.single;
        expect(interro.id, 'e-int');
        expect(interro.statutSaisie, StatutSaisieEvaluation.complete);
        expect(interro.pourcentageSaisie, 100);

        // L'examen est rattaché à la période, taux dérivé (0 note → nonSaisie).
        expect(periode.examen!.evaluationId, 'e-exam');
        expect(periode.examen!.statutSaisie, StatutSaisieEvaluation.nonSaisie);

        // Plafonds + chapitres résolus depuis le bundle.
        expect(detail.plafonds!.maxJournalierParSousPeriode, 2);
        expect(detail.plafonds!.maxExamenParPeriodeScolaire, 1);
      },
    );

    test('moyenne indicative : ABSENT_JUSTIFIE exclu, ABSENT_NON_JUSTIFIE=0, '
        'EN_ATTENTE exclu, élève sans note = moyenne null', () async {
      // s1 : NOTEE 12/20 sur l'interro (déjà en place, setUp) — moyenne 60.
      // s2 : ABSENT_JUSTIFIE sur l'interro (remplace la note NOTEE du
      // setUp) — exclu entièrement, pas de moyenne.
      await db.update(
        'note_evaluation',
        {'statut': 'ABSENT_JUSTIFIE', 'points_obtenus': null},
        where: 'id = ?',
        whereArgs: ['n-s2'],
      );
      // Un 2e cours de la même classe (autre élève 's3' ABSENT_NON_JUSTIFIE
      // sur une 2e interro) exercerait un scénario séparé — ici on ajoute
      // simplement une 2e évaluation à la même sous-période avec s1 en
      // ABSENT_NON_JUSTIFIE pour vérifier le poids 0 dans la moyenne.
      await insertEval('e-int2', 'INTERRO', 'co1', sousPeriode: 'sp1');
      await db.insert('note_evaluation', {
        'id': 'n-s1-int2',
        'evaluation_id': 'e-int2',
        'student_id': 's1',
        'points_obtenus': null,
        'statut': 'ABSENT_NON_JUSTIFIE',
        'updated_at': 1,
        'sync_status': 'SYNCED',
      });
      // s2 : EN_ATTENTE sur la 2e interro — exclu.
      await db.insert('note_evaluation', {
        'id': 'n-s2-int2',
        'evaluation_id': 'e-int2',
        'student_id': 's2',
        'points_obtenus': null,
        'statut': 'EN_ATTENTE',
        'updated_at': 1,
        'sync_status': 'SYNCED',
      });

      final detail = (await repo.getCoursNotationDetail(
        'co1',
      )).getOrElse(() => fail('Left'));

      final sp = detail.periodes.single.sousPeriodes.single;
      final byStudent = {for (final m in sp.moyennesEleves) m.studentId: m};
      // s1 : (12/20*1 [NOTEE] + 0/1*1 [ABSENT_NON_JUSTIFIE]) / (1+1) = 30%.
      expect(byStudent['s1']!.moyenne, 30);
      // s2 : NOTEE remplacée par ABSENT_JUSTIFIE (exclu) + EN_ATTENTE
      // (exclu) → aucune note comptée.
      expect(byStudent['s2']!.moyenne, isNull);
    });

    test('plusieurs examens sur UNE période (maxExamen > 1) : le PREMIER par '
        'date reste affiché, jamais éclipsé silencieusement par un examen '
        'créé après', () async {
      // e-exam (setUp) : 10/06/2026. On ajoute un 2e examen ANTÉRIEUR
      // (03/06/2026) sur la même période p1 — inséré APRÈS dans la table
      // (ordre d'insertion ≠ ordre de date) pour bien isoler le tri sur
      // eval_date, pas sur l'ordre de lecture SQL.
      await db.insert('evaluation', {
        'id': 'e-exam-early',
        'cours_id': 'co1',
        'type': 'EXAMEN',
        'eval_date': DateTime.utc(2026, 6, 3).millisecondsSinceEpoch,
        'max_points': 20.0,
        'poids': 1,
        'periode_scolaire_id': 'p1',
        'updated_at': 1,
        'sync_status': 'SYNCED',
      });

      final detail = (await repo.getCoursNotationDetail(
        'co1',
      )).getOrElse(() => fail('Left'));

      final periode = detail.periodes.single;
      expect(periode.examen!.evaluationId, 'e-exam-early');
    });

    test('cours absent de ref_cours → délègue à l\'online', () async {
      final online = MockOnlineCourse();
      final repo2 = CourseOfflineRepositoryImpl(
        online: online,
        academicsLocalDataSource: local,
        academicsRefLocalDataSource: refLocal,
        classroomLocalDataSource: ClassroomLocalDataSource(db),
        evaluationRepository: EvaluationOfflineRepositoryImpl(
          localDataSource: local,
          idGenerator: _SeqId(() => 'x'),
          now: () => 1,
        ),
        syncMetaDao: syncMetaDao,
        referentialDao: EnrollmentReferentialDao(db),
      );
      when(
        () => online.getCoursNotationDetail('absent'),
      ).thenAnswer((_) async => const Left(NotFoundFailure('absent')));

      await repo2.getCoursNotationDetail('absent');
      verify(() => online.getCoursNotationDetail('absent')).called(1);
    });

    test('cours connu mais ligne de barème pas encore dans le bundle → '
        'délègue à l\'online (pas de détail dégradé)', () async {
      await db.insert('ref_cours', {
        'id': 'co-no-bundle',
        'classroom_id': 'class-1',
        'ligne_bareme_id': 'lb-unknown',
        'synced_at': 1,
      });
      final online = MockOnlineCourse();
      final repo2 = CourseOfflineRepositoryImpl(
        online: online,
        academicsLocalDataSource: local,
        academicsRefLocalDataSource: refLocal,
        classroomLocalDataSource: ClassroomLocalDataSource(db),
        evaluationRepository: EvaluationOfflineRepositoryImpl(
          localDataSource: local,
          idGenerator: _SeqId(() => 'x'),
          now: () => 1,
        ),
        syncMetaDao: syncMetaDao,
        referentialDao: EnrollmentReferentialDao(db),
      );
      when(
        () => online.getCoursNotationDetail('co-no-bundle'),
      ).thenAnswer((_) async => const Left(NotFoundFailure('nope')));

      await repo2.getCoursNotationDetail('co-no-bundle');
      verify(() => online.getCoursNotationDetail('co-no-bundle')).called(1);
    });

    test(
      'chapitres couverts résolus depuis le bundle (titres, pas ids)',
      () async {
        await db.insert('ref_chapitre', {
          'id': 'ch1',
          'cours_id': 'co1',
          'titre': 'Fractions',
          'ordre': 1,
        });
        await db.update(
          'evaluation',
          {'chapitre_ids_json': '["ch1","ch-unknown"]'},
          where: 'id = ?',
          whereArgs: ['e-int'],
        );

        final detail = (await repo.getCoursNotationDetail(
          'co1',
        )).getOrElse(() => fail('Left'));

        expect(detail.chapitresDisponibles.single.titre, 'Fractions');
        final interro = detail
            .periodes
            .single
            .sousPeriodes
            .single
            .evaluationsParType
            .single
            .evaluations
            .single;
        // 'ch-unknown' n'a pas de correspondance dans le bundle → omis.
        expect(interro.chapitres, ['Fractions']);
      },
    );
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
