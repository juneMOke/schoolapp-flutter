import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_rows.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart'
    show kAcademicsCoursBootstrapPrefix;
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart'
    show kGradesReferentialResource;
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/chapitre_option.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_groupe.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/examen_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/ligne_bareme_plafonds.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/moyenne_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';

/// Implémentation **offline-first** de [CourseRepository].
///
/// - [getMyCourses] : jointure locale `ref_cours` → `ref_ligne_bareme` →
///   `ref_branche`, triée par classe puis par ordre du barème (guide
///   fonctionnel §4). **Aucun filtre d'identité côté client** : le pull cours
///   est scopé enseignant côté serveur (dérivé du token, commit back
///   `1ec6be3` — DF-K), donc tout ce qui est en local appartient déjà au prof
///   connecté. Une classe dont la ligne de barème/branche n'est pas encore en
///   cache est masquée par le `JOIN`. Repli online tant que `ref_cours` ou le
///   bundle `grades-referential` n'ont pas terminé leur premier cycle — sinon
///   un résultat local partiel afficherait à tort « aucun cours ».
/// - [getCoursNotationDetail] : arbre période→sous-période **composé** depuis
///   le bundle `grades-referential` (`ref_periode`/`ref_sous_periode`, statut
///   ouvert/clôturé — seule source, le squelette `ref_cours_notation` est
///   retiré) + les **évaluations locales** groupées par type. La **moyenne de
///   cours** (`moyenneClasse`/`moyenneGenerale`) est **dérivée en local**,
///   optimiste et indicative (ADR-006 : « le prof a toutes les notes de son
///   cours ») — Σ(points/max × poids) / Σ poids par élève, `ABSENT_JUSTIFIE`
///   exclu, `ABSENT_NON_JUSTIFIE` compté 0, `EN_ATTENTE` exclu. Ce n'est PAS
///   la moyenne officielle MINEDUC (pondération complète interros→sous-
///   période→période+examen) ni un rang — ceux-là restent **serveur**. Le
///   taux de saisie est aussi DÉRIVÉ des notes locales. Repli online si un
///   maillon manque (cours/ligne de barème/bundle pas encore pullé).
/// - [createEvaluation] : déléguée au [EvaluationOfflineRepositoryImpl] (régime A,
///   insert-only + outbox).
class CourseOfflineRepositoryImpl implements CourseRepository {
  final CourseRepository _online;
  final AcademicsLocalDataSource _academicsLocal;
  final AcademicsRefLocalDataSource _academicsRefLocal;
  final ClassroomLocalDataSource _classroomLocal;
  final EvaluationOfflineRepositoryImpl _evaluationRepo;
  final SyncMetaDao _syncMetaDao;

  const CourseOfflineRepositoryImpl({
    required CourseRepository online,
    required AcademicsLocalDataSource academicsLocalDataSource,
    required AcademicsRefLocalDataSource academicsRefLocalDataSource,
    required ClassroomLocalDataSource classroomLocalDataSource,
    required EvaluationOfflineRepositoryImpl evaluationRepository,
    required SyncMetaDao syncMetaDao,
  }) : _online = online,
       _academicsLocal = academicsLocalDataSource,
       _academicsRefLocal = academicsRefLocalDataSource,
       _classroomLocal = classroomLocalDataSource,
       _evaluationRepo = evaluationRepository,
       _syncMetaDao = syncMetaDao;

  // ── Mes cours (jointure locale ref_cours → ref_ligne_bareme → ref_branche) ──

  @override
  Future<Either<Failure, List<CourseSummary>>> getMyCourses() async {
    try {
      final coursReady =
          await _syncMetaDao.getCursor(kAcademicsCoursBootstrapPrefix) != null;
      final referentialReady =
          await _syncMetaDao.getCursor(kGradesReferentialResource) != null;
      // Hydratation encore en cours (pull lancé en `unawaited` au montage du
      // scope) : un résultat local partiel serait un « aucun cours » trompeur
      // (guide §4). Repli online, cohérent avec getCoursNotationDetail.
      if (!coursReady || !referentialReady) {
        return _online.getMyCourses();
      }

      final rows = await _academicsRefLocal.getMyCoursesJoined();
      final coursesByClassroom = <String, List<CourseRef>>{};
      for (final row in rows) {
        final classroomId = row['classroom_id'] as String;
        coursesByClassroom
            .putIfAbsent(classroomId, () => <CourseRef>[])
            .add(
              CourseRef(
                id: row['cours_id'] as String,
                label: row['branche_nom'] as String,
              ),
            );
      }

      final summaries = <CourseSummary>[];
      for (final entry in coursesByClassroom.entries) {
        final classroomId = entry.key;
        final dto = await _classroomLocal.getClassroomById(classroomId);
        final classroom = dto == null
            ? ClassroomSummary(
                id: classroomId,
                schoolLevelId: '',
                name: '',
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
        summaries.add(
          CourseSummary(classroom: classroom, courses: entry.value),
        );
      }
      return Right(summaries);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  // ── Détail cours (composé depuis le bundle + évaluations locales) ───────────

  @override
  Future<Either<Failure, CoursNotationDetail>> getCoursNotationDetail(
    String coursId,
  ) async {
    try {
      final cours = await _academicsRefLocal.getCours(coursId);
      // Cours pas encore pullé → repli online (best-effort).
      if (cours == null) return _online.getCoursNotationDetail(coursId);

      final ligneBareme = await _academicsRefLocal.getLigneBareme(
        cours.ligneBaremeId,
      );
      final classroom = await _classroomLocal.getClassroomById(
        cours.classroomId,
      );
      final schoolLevelGroupId = classroom?.schoolLevelGroupId;
      // Ligne de barème ou groupe de niveau pas encore en cache (bundle /
      // classe pas pullés) → repli online, pas de détail dégradé.
      if (ligneBareme == null ||
          classroom == null ||
          schoolLevelGroupId == null) {
        return _online.getCoursNotationDetail(coursId);
      }

      final branche = await _academicsRefLocal.getBranche(
        ligneBareme.brancheId,
      );

      final periodeRows = await _academicsRefLocal.getPeriodesForGroup(
        classroom.academicYearId,
        schoolLevelGroupId,
      );
      final sousPeriodeRows = await _academicsRefLocal
          .getSousPeriodesForPeriodes(
            periodeRows.map((p) => p.id).toList(growable: false),
          );
      final sousByPeriode = <String, List<RefSousPeriodeRow>>{};
      for (final sp in sousPeriodeRows) {
        (sousByPeriode[sp.periodeScolaireId] ??= []).add(sp);
      }

      final chapitreRows = await _academicsRefLocal.getChapitresForCours(
        coursId,
      );
      final chapitreTitles = {for (final c in chapitreRows) c.id: c.titre};
      final chapitresDisponibles = chapitreRows
          .map((c) => ChapitreOption(id: c.id, titre: c.titre, ordre: c.ordre))
          .toList(growable: false);

      final roster = await _classroomLocal.getRoster(cours.classroomId);
      final effectif = roster.length;

      final evals = await _academicsLocal.getEvaluationsForCours(coursId);
      final noted = await _academicsLocal.notedCountByEvaluation(
        evals.map((e) => e.id).toList(growable: false),
      );
      final notesByEvaluation = await _academicsLocal.getNotesForEvaluations(
        evals.map((e) => e.id).toList(growable: false),
      );

      final bySousPeriode = <String, List<EvaluationRow>>{};
      // `PeriodeNotation.examen` (comme le modèle ONLINE, `CoursNotationDetailModel`)
      // n'a qu'UN slot examen par période — limite de modèle déjà connue et
      // documentée (cf. `EvalCreationForm._examenPlafondReached`, qui traite
      // « un examen existe » comme le plafond atteint). Si plusieurs examens
      // existent malgré tout pour une période (`maxExamenParPeriodeScolaire`
      // > 1), on garde le PREMIER par date (`evals` est trié `eval_date ASC`)
      // plutôt que le dernier lu — un nouvel examen ne doit jamais faire
      // disparaître de l'arbre un examen déjà noté par le prof.
      final examenByPeriode = <String, EvaluationRow>{};
      for (final e in evals) {
        final isExamen =
            TypeEvaluationX.fromApiValue(e.type) == TypeEvaluation.examen;
        if (isExamen && e.periodeScolaireId != null) {
          examenByPeriode.putIfAbsent(e.periodeScolaireId!, () => e);
        } else if (e.sousPeriodeId != null) {
          (bySousPeriode[e.sousPeriodeId!] ??= []).add(e);
        }
      }

      final periodes = periodeRows
          .map((p) {
            final sousPeriodes =
                (sousByPeriode[p.id] ?? const <RefSousPeriodeRow>[])
                    .map((sp) {
                      final spEvals = bySousPeriode[sp.id] ?? const [];
                      final byType =
                          <TypeEvaluation, List<EvaluationSummary>>{};
                      for (final ev in spEvals) {
                        final t = TypeEvaluationX.fromApiValue(ev.type);
                        (byType[t] ??= []).add(
                          _evalSummary(ev, effectif, noted, chapitreTitles),
                        );
                      }
                      final moyennesEleves = _moyennesEleves(
                        spEvals,
                        notesByEvaluation,
                        roster,
                      );
                      final classAverage = _classAverage(moyennesEleves);
                      return SousPeriodeNotation(
                        sousPeriodeId: sp.id,
                        ordre: sp.ordre,
                        statut: StatutPeriodeX.fromApiValue(sp.statut),
                        moyenneClasse: classAverage.moyenne,
                        nombreElevesNotes: classAverage.nombreElevesNotes,
                        nombreEleves50: classAverage.nombreEleves50,
                        moyennesEleves: moyennesEleves,
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

            final examenRow = examenByPeriode[p.id];
            return PeriodeNotation(
              periodeScolaireId: p.id,
              ordre: p.ordre,
              statut: StatutPeriodeX.fromApiValue(p.statut),
              sousPeriodes: sousPeriodes,
              examen: examenRow == null
                  ? null
                  : _examen(
                      examenRow,
                      effectif,
                      noted,
                      notesByEvaluation,
                      roster,
                    ),
            );
          })
          .toList(growable: false);

      return Right(
        CoursNotationDetail(
          coursId: coursId,
          classroomId: cours.classroomId,
          brancheNom: branche?.nom,
          effectif: effectif,
          periodes: periodes,
          plafonds: LigneBaremePlafonds(
            maxJournalierParSousPeriode:
                ligneBareme.maxJournalierParSousPeriode,
            maxExamenParPeriodeScolaire:
                ligneBareme.maxExamenParPeriodeScolaire,
          ),
          chapitresDisponibles: chapitresDisponibles,
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
      chapitreIds: request.chapitreIds,
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
          chapitreIds: row.chapitreIds,
        ),
      ),
    );
  }

  // ── Helpers de composition ──────────────────────────────────────────────────

  /// Titres des chapitres couverts par [row], résolus depuis le bundle
  /// (`chapitreTitles`). Un id sans correspondance (chapitre supprimé /
  /// bundle pas encore rafraîchi) est silencieusement omis.
  List<String> _chapitreTitresFor(
    EvaluationRow row,
    Map<String, String> chapitreTitles,
  ) => row.chapitreIds
      .map((id) => chapitreTitles[id])
      .whereType<String>()
      .toList(growable: false);

  EvaluationSummary _evalSummary(
    EvaluationRow row,
    int effectif,
    Map<String, int> noted,
    Map<String, String> chapitreTitles,
  ) {
    final n = noted[row.id] ?? 0;
    return EvaluationSummary(
      id: row.id,
      type: TypeEvaluationX.fromApiValue(row.type),
      nom: _derivedNom(row),
      chapitres: _chapitreTitresFor(row, chapitreTitles),
      date: DateTime.fromMillisecondsSinceEpoch(row.evalDate, isUtc: true),
      maxPoints: row.maxPoints,
      poids: row.poids,
      statutSaisie: _statutSaisie(n, effectif),
      pourcentageSaisie: effectif > 0 ? (n / effectif) * 100 : 0,
      rejectionCode: row.rejectionCode,
    );
  }

  ExamenNotation _examen(
    EvaluationRow row,
    int effectif,
    Map<String, int> noted,
    Map<String, List<NoteEvaluationRow>> notesByEvaluation,
    List<ClassroomMemberDto> roster,
  ) {
    final n = noted[row.id] ?? 0;
    final classAverage = _classAverage(
      _moyennesEleves([row], notesByEvaluation, roster),
    );
    return ExamenNotation(
      evaluationId: row.id,
      nom: _derivedNom(row),
      date: DateTime.fromMillisecondsSinceEpoch(row.evalDate, isUtc: true),
      poids: row.poids,
      maxPoints: row.maxPoints,
      moyenneGenerale: classAverage.moyenne,
      statutSaisie: _statutSaisie(n, effectif),
      pourcentageSaisie: effectif > 0 ? (n / effectif) * 100 : 0,
      rejectionCode: row.rejectionCode,
    );
  }

  StatutSaisieEvaluation _statutSaisie(int noted, int effectif) {
    if (noted == 0) return StatutSaisieEvaluation.nonSaisie;
    if (effectif > 0 && noted >= effectif) {
      return StatutSaisieEvaluation.complete;
    }
    return StatutSaisieEvaluation.enAttente;
  }

  /// Moyenne **indicative** (ADR-006/FRONT §8) de chaque élève du roster sur
  /// [evals] : `Σ(points/max × poids) / Σ poids`, en pourcentage.
  /// `ABSENT_JUSTIFIE` exclu (ne pèse pas comme zéro) ; `ABSENT_NON_JUSTIFIE`
  /// compte 0 ; `EN_ATTENTE`/pas de ligne = exclu. `moyenne` reste `null` pour
  /// un élève sans aucune note comptée (jamais confondu avec 0).
  List<MoyenneEleve> _moyennesEleves(
    List<EvaluationRow> evals,
    Map<String, List<NoteEvaluationRow>> notesByEvaluation,
    List<ClassroomMemberDto> roster,
  ) {
    final numerByStudent = <String, double>{};
    final denomByStudent = <String, int>{};
    for (final eval in evals) {
      if (eval.maxPoints <= 0) continue;
      for (final note in notesByEvaluation[eval.id] ?? const []) {
        // ABSENT_JUSTIFIE et EN_ATTENTE (ou tout statut inconnu, parsing
        // tolérant) : exclus du numérateur ET du dénominateur.
        double? contribution;
        if (note.statut == 'NOTEE' && note.pointsObtenus != null) {
          contribution = (note.pointsObtenus! / eval.maxPoints) * eval.poids;
        } else if (note.statut == 'ABSENT_NON_JUSTIFIE') {
          contribution = 0;
        }
        if (contribution == null) continue;
        numerByStudent.update(
          note.studentId,
          (v) => v + contribution!,
          ifAbsent: () => contribution!,
        );
        denomByStudent.update(
          note.studentId,
          (v) => v + eval.poids,
          ifAbsent: () => eval.poids,
        );
      }
    }
    return roster
        .map((m) {
          final denom = denomByStudent[m.studentId];
          final moyenne = (denom == null || denom == 0)
              ? null
              : (numerByStudent[m.studentId]! / denom) * 100;
          return MoyenneEleve(
            studentId: m.studentId,
            firstName: m.studentFirstName,
            lastName: m.studentLastName,
            middleName: m.studentMiddleName,
            moyenne: moyenne,
          );
        })
        .toList(growable: false);
  }

  _ClassAverage _classAverage(List<MoyenneEleve> moyennesEleves) {
    final notes = moyennesEleves
        .map((m) => m.moyenne)
        .whereType<double>()
        .toList(growable: false);
    if (notes.isEmpty) return const _ClassAverage(null, 0, 0);
    final moyenne = notes.reduce((a, b) => a + b) / notes.length;
    final above50 = notes.where((n) => n >= 50).length;
    return _ClassAverage(moyenne, notes.length, above50);
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

/// Agrégat de classe (%) dérivé des [MoyenneEleve] retenus (`moyenne` non
/// `null`) — `moyenne` reste `null` si aucun élève n'a de note comptée.
class _ClassAverage {
  final double? moyenne;
  final int nombreElevesNotes;
  final int nombreEleves50;

  const _ClassAverage(
    this.moyenne,
    this.nombreElevesNotes,
    this.nombreEleves50,
  );
}
