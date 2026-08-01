import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';

/// Hydratation des caches Notes/Cours au montage des FeatureScopes academics et
/// schedule. Le `PullCoordinator` ne se déclenche qu'au RETOUR online : une
/// tablette démarrée déjà connectée ne tirerait jamais — « Mes cours » et
/// l'emploi du temps resteraient vides jusqu'à une coupure réseau fortuite.
/// (Même rôle que `SyncAttendancePullUseCase` / `SyncFinancePullsUseCase`.)
///
/// **Best-effort et ordonné** : réf emploi du temps (créneaux + séances), puis
/// cours (scopé enseignant, DF-K — plus de dépendance à l'année/bootstrap
/// depuis le commit back `1ec6be3`), puis le bundle `grades-referential`
/// (branches/plafonds/chapitres/périodes, cadré prof — condition de la
/// prévention offline et de la composition du détail cours, MAJ-4), puis
/// évaluations/notes (qui itèrent `ref_cours` — d'où l'ordre). Chaque étape
/// avale ses échecs (les repos ne lèvent jamais ; la lecture UI est locale de
/// toute façon et sera resservie au prochain cycle).
///
/// **Gate crédentiels** : ce déclencheur contourne le `PullCoordinator`
/// (justement pour tirer sans attendre un cycle online→offline→online), donc
/// il n'hérite pas de son gate `SessionCredentialsProbe`. Sans lui, une
/// tablette jamais connectée (ou déconnectée) taperait le réseau à chaque
/// montage du scope Cours — 401 systématiques, silencieux mais inutiles.
///
/// **Gate connectivité** : même raisonnement — sans `ConnectivityService`, une
/// tablette hors-ligne taperait quand même le réseau à chaque montage.
///
/// **Réveil de l'UI** : les ressources effectivement rafraîchies sont diffusées
/// en fin d'hydratation sur le [PullCompletionBus]. Sans ce signal, l'écran a
/// déjà lu le cache local (froid, donc vide) bien avant que le réseau réponde,
/// et rien ne le relit ensuite — cf. la doc du bus.
class SyncAcademicsPullsUseCase {
  final SchedulePullRepositoryImpl _schedulePull;
  final AcademicsCoursPullRepositoryImpl _coursPull;
  final AcademicsMetierPullRepositoryImpl _metierPull;
  final GradesReferentialPullRepositoryImpl _gradesReferentialPull;
  final SessionCredentialsProbe _credentialsProbe;
  final ConnectivityService _connectivity;
  final PullCompletionBus? _completionBus;

  const SyncAcademicsPullsUseCase({
    required SchedulePullRepositoryImpl schedulePullRepository,
    required AcademicsCoursPullRepositoryImpl coursPullRepository,
    required AcademicsMetierPullRepositoryImpl metierPullRepository,
    required GradesReferentialPullRepositoryImpl
    gradesReferentialPullRepository,
    required SessionCredentialsProbe credentialsProbe,
    required ConnectivityService connectivity,
    PullCompletionBus? completionBus,
  }) : _schedulePull = schedulePullRepository,
       _coursPull = coursPullRepository,
       _metierPull = metierPullRepository,
       _gradesReferentialPull = gradesReferentialPullRepository,
       _credentialsProbe = credentialsProbe,
       _connectivity = connectivity,
       _completionBus = completionBus;

  Future<void> call() async {
    if (!await _connectivity.isOnline()) return;
    if (!await _canAuthenticate()) return;

    // Réf emploi du temps (créneaux école + séances de l'enseignant connecté).
    _notify(
      kScheduleTimeSlotsResource,
      await _schedulePull.syncTimeSlots(),
      (o) => o.upserted,
    );
    _notify(
      kScheduleSessionsResource,
      await _schedulePull.syncSessions(),
      (o) => o.upserted,
    );

    // Cours du prof connecté (scope token, aucun classroomId/année requis).
    _notify(
      kAcademicsCoursResourcePrefix,
      await _coursPull.syncCours(),
      (o) => o.upserted,
    );

    // Bundle grades-referential (ETag, cadré prof) — avant les lectures qui en
    // dépendent (prévention offline, composition du détail cours, MAJ-4).
    _notify(
      kGradesReferentialResource,
      await _gradesReferentialPull.syncGradesReferential(),
      (o) => o.upserted,
    );

    // Métier (évaluations, notes) — itèrent ref_cours.
    _notify(
      kAcademicsEvaluationsResourcePrefix,
      await _metierPull.syncEvaluations(),
      (o) => o.upserted,
    );
    _notify(
      kAcademicsNotesResourcePrefix,
      await _metierPull.syncNotes(),
      (o) => o.upserted,
    );
  }

  /// Réveille les écrans dès que [resource] a réellement appliqué des lignes,
  /// **sans attendre la fin de l'hydratation**. Grouper les six notifications à
  /// la fin ferait patienter l'emploi du temps derrière la synchro des notes,
  /// qui itère tous les cours et peut durer — l'écran resterait vide plusieurs
  /// secondes de plus alors que ses séances sont déjà en base.
  ///
  /// Un `Left` (échec réseau) ou un cycle `304` ne réveille personne : rien n'a
  /// changé en local, relire ne ferait que du bruit.
  void _notify<T>(
    String resource,
    Either<Failure, T> result,
    int Function(T) upsertedOf,
  ) {
    result.fold((_) {}, (outcome) {
      if (upsertedOf(outcome) > 0) _completionBus?.notifyUpdated({resource});
    });
  }

  /// Sonde défaillante (storage indisponible…) : ne pas bloquer l'hydratation —
  /// même politique fail-open que `SyncStatusCubit._canAuthenticate()`.
  Future<bool> _canAuthenticate() async {
    try {
      return await _credentialsProbe.canAuthenticate();
    } catch (_) {
      return true;
    }
  }
}
