import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_groupe.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/examen_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_recurring_session_row.dart';

/// Implémentation **offline-first** de [CourseRepository].
///
/// - [getMyCourses] : cours de l'enseignant connecté composés depuis l'emploi du
///   temps (`ref_recurring_sessions`, filtre `teacher_id == uid`), classe résolue
///   via `ref_classrooms`.
/// - [getCoursNotationDetail] : arbre période→sous-période depuis le **squelette
///   caché** (`ref_cours_notation`, statut ouvert/clôturé) + les **évaluations
///   locales** groupées par type. Les moyennes d'ensemble (moyenneClasse, rang,
///   moyennesEleves) restent **serveur** (ADR-006) → null/0 hors ligne ; le taux
///   de saisie est DÉRIVÉ des notes locales. Repli online si le squelette n'a pas
///   encore été caché.
/// - [createEvaluation] : déléguée au [EvaluationOfflineRepositoryImpl] (régime A,
///   insert-only + outbox).
///
/// ⚠ Hypothèse `CurrentUserContext.uid == teacher_id` (à VÉRIFIER en revue).
class CourseOfflineRepositoryImpl implements CourseRepository {
  final CourseRepository _online;
  final AcademicsLocalDataSource _academicsLocal;
  final AcademicsRefLocalDataSource _academicsRefLocal;
  final ScheduleRefLocalDataSource _scheduleRefLocal;
  final ClassroomLocalDataSource _classroomLocal;
  final EvaluationOfflineRepositoryImpl _evaluationRepo;
  final CurrentUserContext? _currentUser;
  final BootstrapLocalRepository? _bootstrapRepository;
  final String _bootstrapKey;

  const CourseOfflineRepositoryImpl({
    required CourseRepository online,
    required AcademicsLocalDataSource academicsLocalDataSource,
    required AcademicsRefLocalDataSource academicsRefLocalDataSource,
    required ScheduleRefLocalDataSource scheduleRefLocalDataSource,
    required ClassroomLocalDataSource classroomLocalDataSource,
    required EvaluationOfflineRepositoryImpl evaluationRepository,
    CurrentUserContext? currentUser,
    BootstrapLocalRepository? bootstrapRepository,
    String bootstrapKey = AppConstants.bootstrapPayloadKey,
  }) : _online = online,
       _academicsLocal = academicsLocalDataSource,
       _academicsRefLocal = academicsRefLocalDataSource,
       _scheduleRefLocal = scheduleRefLocalDataSource,
       _classroomLocal = classroomLocalDataSource,
       _evaluationRepo = evaluationRepository,
       _currentUser = currentUser,
       _bootstrapRepository = bootstrapRepository,
       _bootstrapKey = bootstrapKey;

  // ── Mes cours (composé depuis l'emploi du temps) ────────────────────────────

  @override
  Future<Either<Failure, List<CourseSummary>>> getMyCourses() async {
    try {
      final uid = _currentUser?.uid;
      final sessions = await _scheduleRefLocal.getAllSessions();
      // Scope ANNÉE COURANTE (bootstrap local) : après un rollover, les séances
      // d'années révolues accumulées en base ne doivent pas réapparaître dans
      // « Mes cours ». Année irrésolvable → repli sans filtre (premier
      // démarrage, bootstrap pas encore chargé).
      final academicYearId = await _resolveCurrentYear();
      final mine = uid == null
          ? const <RefRecurringSessionRow>[]
          : sessions.where(
              (s) =>
                  s.teacherId == uid &&
                  (academicYearId == null ||
                      s.academicYearId == academicYearId),
            );

      final byClassroom = <String, Map<String, String>>{};
      final classroomLabel = <String, String>{};
      for (final s in mine) {
        classroomLabel[s.classroomId] = s.classroomLabel;
        (byClassroom[s.classroomId] ??= {})[s.coursId] = s.subjectLabel;
      }

      final summaries = <CourseSummary>[];
      for (final entry in byClassroom.entries) {
        final classroomId = entry.key;
        final courses = entry.value.entries
            .map((c) => CourseRef(id: c.key, label: c.value))
            .toList(growable: false);
        final dto = await _classroomLocal.getClassroomById(classroomId);
        final classroom = dto == null
            ? ClassroomSummary(
                id: classroomId,
                schoolLevelId: '',
                name: classroomLabel[classroomId] ?? '',
                capacity: 0,
                totalCount: 0,
                femaleCount: 0,
                maleCount: 0,
              )
            : ClassroomSummary(
                id: dto.id,
                version: dto.version,
                schoolLevelId: dto.schoolLevelId ?? '',
                name: dto.name,
                capacity: dto.capacity ?? 0,
                totalCount: dto.totalCount,
                femaleCount: dto.femaleCount,
                maleCount: dto.maleCount,
              );
        summaries.add(CourseSummary(classroom: classroom, courses: courses));
      }
      return Right(summaries);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  // ── Détail cours (squelette caché + évaluations locales) ────────────────────

  @override
  Future<Either<Failure, CoursNotationDetail>> getCoursNotationDetail(
    String coursId,
  ) async {
    try {
      final skeleton = await _academicsRefLocal.getCoursNotation(coursId);
      // Squelette pas encore caché → repli online (best-effort ; caché ensuite
      // par le pull NF-7a).
      if (skeleton == null) return _online.getCoursNotationDetail(coursId);

      final evals = await _academicsLocal.getEvaluationsForCours(coursId);
      final noted = await _academicsLocal.notedCountByEvaluation(
        evals.map((e) => e.id).toList(growable: false),
      );
      final effectif = skeleton.effectif;

      final bySousPeriode = <String, List<EvaluationRow>>{};
      final examenByPeriode = <String, EvaluationRow>{};
      for (final e in evals) {
        final isExamen =
            TypeEvaluationX.fromApiValue(e.type) == TypeEvaluation.examen;
        if (isExamen && e.periodeScolaireId != null) {
          examenByPeriode[e.periodeScolaireId!] = e;
        } else if (e.sousPeriodeId != null) {
          (bySousPeriode[e.sousPeriodeId!] ??= []).add(e);
        }
      }

      final periodes = skeleton.periodes
          .map((p) {
            final sousPeriodes = p.sousPeriodes
                .map((sp) {
                  final spEvals = bySousPeriode[sp.sousPeriodeId] ?? const [];
                  final byType = <TypeEvaluation, List<EvaluationSummary>>{};
                  for (final ev in spEvals) {
                    final t = TypeEvaluationX.fromApiValue(ev.type);
                    (byType[t] ??= []).add(_evalSummary(ev, effectif, noted));
                  }
                  return SousPeriodeNotation(
                    sousPeriodeId: sp.sousPeriodeId,
                    ordre: sp.ordre,
                    statut: StatutPeriodeX.fromApiValue(sp.statut),
                    nombreElevesNotes: 0,
                    nombreEleves50: 0,
                    moyennesEleves: const [],
                    evaluationsParType: byType.entries
                        .map(
                          (g) => EvaluationGroupe(
                            type: g.key,
                            evaluations: g.value,
                          ),
                        )
                        .toList(growable: false),
                  );
                })
                .toList(growable: false);

            final examenRow = examenByPeriode[p.periodeScolaireId];
            return PeriodeNotation(
              periodeScolaireId: p.periodeScolaireId,
              ordre: p.ordre,
              statut: StatutPeriodeX.fromApiValue(p.statut),
              sousPeriodes: sousPeriodes,
              examen: examenRow == null
                  ? null
                  : _examen(examenRow, effectif, noted),
            );
          })
          .toList(growable: false);

      return Right(
        CoursNotationDetail(
          coursId: coursId,
          classroomId: skeleton.classroomId ?? '',
          brancheNom: skeleton.brancheNom,
          effectif: effectif,
          periodes: periodes,
        ),
      );
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  // ── Création d'évaluation (régime A, offline) ───────────────────────────────

  @override
  Future<Either<Failure, Evaluation>> createEvaluation(
    String coursId,
    CreateEvaluationRequest request,
  ) async {
    final result = await _evaluationRepo.createEvaluation(
      coursId: coursId,
      type: request.type.toApiValue(),
      date: request.date,
      maxPoints: request.maxPoints,
      poids: request.poids ?? 1,
      sousPeriodeId: request.sousPeriodeId,
      periodeScolaireId: request.periodeScolaireId,
    );
    return result.fold(
      Left.new,
      (row) => Right(
        Evaluation(
          id: row.id,
          coursId: row.coursId,
          type: TypeEvaluationX.fromApiValue(row.type),
          date: DateTime.fromMillisecondsSinceEpoch(row.evalDate, isUtc: true),
          maxPoints: row.maxPoints,
          poids: row.poids,
          sousPeriodeId: row.sousPeriodeId,
          periodeScolaireId: row.periodeScolaireId,
        ),
      ),
    );
  }

  // ── Helpers de composition ──────────────────────────────────────────────────

  EvaluationSummary _evalSummary(
    EvaluationRow row,
    int effectif,
    Map<String, int> noted,
  ) {
    final n = noted[row.id] ?? 0;
    return EvaluationSummary(
      id: row.id,
      type: TypeEvaluationX.fromApiValue(row.type),
      nom: _derivedNom(row),
      chapitres: const [],
      date: DateTime.fromMillisecondsSinceEpoch(row.evalDate, isUtc: true),
      maxPoints: row.maxPoints,
      poids: row.poids,
      statutSaisie: _statutSaisie(n, effectif),
      pourcentageSaisie: effectif > 0 ? (n / effectif) * 100 : 0,
    );
  }

  ExamenNotation _examen(
    EvaluationRow row,
    int effectif,
    Map<String, int> noted,
  ) {
    final n = noted[row.id] ?? 0;
    return ExamenNotation(
      evaluationId: row.id,
      nom: _derivedNom(row),
      date: DateTime.fromMillisecondsSinceEpoch(row.evalDate, isUtc: true),
      poids: row.poids,
      maxPoints: row.maxPoints,
      statutSaisie: _statutSaisie(n, effectif),
      pourcentageSaisie: effectif > 0 ? (n / effectif) * 100 : 0,
    );
  }

  StatutSaisieEvaluation _statutSaisie(int noted, int effectif) {
    if (noted == 0) return StatutSaisieEvaluation.nonSaisie;
    if (effectif > 0 && noted >= effectif) {
      return StatutSaisieEvaluation.complete;
    }
    return StatutSaisieEvaluation.enAttente;
  }

  /// Résout l'année scolaire courante depuis le bootstrap local ; null si le
  /// bootstrap n'est pas disponible (jamais d'erreur).
  Future<String?> _resolveCurrentYear() async {
    final repo = _bootstrapRepository;
    if (repo == null) return null;
    try {
      final bootstrap = await repo.getStoredBootstrap(_bootstrapKey);
      final id = bootstrap.fold((_) => null, (b) => b.academicYear.id);
      return (id == null || id.isEmpty) ? null : id;
    } catch (_) {
      return null;
    }
  }

  /// Nom dérivé (la table locale `evaluation` ne stocke aucun libellé — le nom
  /// est TOUJOURS dérivé, avant comme après pull) : type + date `jj/MM`.
  String _derivedNom(EvaluationRow row) {
    final d = DateTime.fromMillisecondsSinceEpoch(row.evalDate, isUtc: true);
    final jj = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '${row.type} $jj/$mm';
  }
}
