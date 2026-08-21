import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';

/// Hydrate les caches Notes/Cours au montage des FeatureScopes `academics` et
/// `schedule` (ADR-015 F6).
///
/// **Ne tire plus les repositories en direct.** Ce déclencheur passe désormais
/// par le `PullCoordinator`, qui reste seul à connaître l'ordre, les droits et —
/// bientôt — le plan de synchronisation. Tant que des écrans tiraient à côté, la
/// largeur effective du pull était l'union du coordinateur et d'une douzaine de
/// portes dérobées, aucune filtrée par une permission : faire du plan l'autorité
/// du seul coordinateur n'aurait rien resserré.
///
/// Ce qui vivait ici et vit maintenant dans le socle, pour tout le monde : la
/// pré-garde de connectivité, la sonde de crédentiels, le filtre de permission,
/// l'abandon sur dépendance bloquée, l'isolation des échecs et la diffusion sur
/// le `PullCompletionBus`. Ce use case ne porte plus qu'une chose — **de quelles
/// ressources ces écrans ont besoin** — et c'est la seule qui lui appartienne
/// vraiment. En particulier, la diffusion n'a plus lieu qu'**une fois** : la
/// notifier ici en plus du cycle ferait relire chaque écran deux fois par pull.
///
/// **L'ordre change, et il vient d'ailleurs.** Ce use case tenait sa propre
/// séquence (créneaux → séances → barème → cours → évaluations → notes) ;
/// `pullSubset` itère le REGISTRE, où le barème est enregistré en tête des six.
/// Les deux honorent l'arête barème → cours (ADR-015 K) — le détail d'un cours
/// et la composition des évaluations lisent le barème — mais ce n'est plus la
/// même séquence, et c'est celle de la DI qui fait foi désormais (figée par
/// `test/core/di/offline_pull_registration_order_test.dart`).
///
/// Le second déclencheur reste le cycle complet du coordinateur (ouverture de
/// session, retour online). Les deux sont nécessaires : une tablette posée sur
/// le Wi-Fi de l'école ne verrait aucun retour online de la journée.
class SyncAcademicsPullsUseCase {
  final PullCoordinator _coordinator;

  const SyncAcademicsPullsUseCase(this._coordinator);

  /// Les six ressources que ces écrans lisent — **un ensemble, jamais une
  /// séquence** : l'ordre d'exécution est celui du registre, pas celui de ces
  /// accolades (cf. `PullCoordinator.pullSubset`).
  ///
  /// Les deux scopes demandent les six, et c'est justifié des deux côtés :
  /// l'emploi du temps ouvre le détail d'un cours dans son propre volet
  /// (`ScheduleCoordinatorPage`), qui compose `ref_cours` × barème ×
  /// évaluations, puis la saisie qui lit les notes. Restreindre `schedule` aux
  /// deux ressources de la grille laisserait ce détail sur un cache froid.
  static const Set<String> resources = {
    kScheduleTimeSlotsResource,
    kScheduleSessionsResource,
    kGradesReferentialResource,
    kAcademicsCoursResourcePrefix,
    kAcademicsEvaluationsResourcePrefix,
    kAcademicsNotesResourcePrefix,
  };

  Future<PullRunReport> call() => _coordinator.pullSubset(resources);
}
