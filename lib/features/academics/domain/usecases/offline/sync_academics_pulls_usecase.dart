import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notation_ref_pull_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';

/// Hydratation des caches Notes/Cours au montage des FeatureScopes academics et
/// schedule. Le `PullCoordinator` ne se déclenche qu'au RETOUR online : une
/// tablette démarrée déjà connectée ne tirerait jamais — « Mes cours » et
/// l'emploi du temps resteraient vides jusqu'à une coupure réseau fortuite.
/// (Même rôle que `SyncAttendancePullUseCase` / `SyncFinancePullsUseCase`.)
///
/// **Best-effort et ordonné** : réf emploi du temps (créneaux + séances), puis
/// cours (scopé enseignant, DF-K — plus de dépendance à l'année/bootstrap
/// depuis le commit back `1ec6be3`), puis évaluations/notes et squelettes de
/// notation (qui itèrent `ref_cours` — d'où l'ordre). Chaque étape avale ses
/// échecs (les repos ne lèvent jamais ; la lecture UI est locale de toute
/// façon et sera resservie au prochain cycle).
class SyncAcademicsPullsUseCase {
  final SchedulePullRepositoryImpl _schedulePull;
  final AcademicsCoursPullRepositoryImpl _coursPull;
  final AcademicsMetierPullRepositoryImpl _metierPull;
  final NotationRefPullRepositoryImpl _notationRefPull;

  const SyncAcademicsPullsUseCase({
    required SchedulePullRepositoryImpl schedulePullRepository,
    required AcademicsCoursPullRepositoryImpl coursPullRepository,
    required AcademicsMetierPullRepositoryImpl metierPullRepository,
    required NotationRefPullRepositoryImpl notationRefPullRepository,
  }) : _schedulePull = schedulePullRepository,
       _coursPull = coursPullRepository,
       _metierPull = metierPullRepository,
       _notationRefPull = notationRefPullRepository;

  Future<void> call() async {
    // Réf emploi du temps (créneaux école + séances de l'enseignant connecté).
    await _schedulePull.syncTimeSlots();
    await _schedulePull.syncSessions();

    // Cours du prof connecté (scope token, aucun classroomId/année requis).
    await _coursPull.syncCours();

    // Métier (évaluations, notes) + squelettes de notation — itèrent ref_cours.
    await _metierPull.syncEvaluations();
    await _metierPull.syncNotes();
    await _notationRefPull.syncNotationSkeletons();
  }
}
