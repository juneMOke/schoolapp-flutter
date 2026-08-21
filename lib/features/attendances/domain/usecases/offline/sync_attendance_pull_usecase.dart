import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart';

/// Hydrate la Présence au montage de son FeatureScope (ADR-015 F6).
///
/// **Ne tire plus le repository en direct.** Ce déclencheur passe désormais par
/// le `PullCoordinator`, qui reste seul à connaître l'ordre, les droits et —
/// bientôt — le plan de synchronisation. Tant que des écrans tiraient à côté, la
/// largeur effective du pull était l'union du coordinateur et d'une douzaine de
/// portes dérobées, aucune filtrée par une permission : faire du plan l'autorité
/// du seul coordinateur n'aurait rien resserré.
///
/// Ce qui vivait ici et vit maintenant dans le socle, pour tout le monde : la
/// pré-garde de connectivité, la sonde de crédentiels, le filtre de permission,
/// l'isolation des échecs et la diffusion sur le `PullCompletionBus`. Ce use
/// case ne porte plus qu'une chose — **de quelles ressources cet écran a
/// besoin** — et c'est la seule qui lui appartienne vraiment.
///
/// Le second déclencheur reste le cycle complet du coordinateur (ouverture de
/// session, retour online). Les deux sont nécessaires : une tablette posée sur
/// le Wi-Fi de l'école ne verrait aucun retour online de la journée.
class SyncAttendancePullUseCase {
  final PullCoordinator _coordinator;

  const SyncAttendancePullUseCase(this._coordinator);

  Future<PullRunReport> call() =>
      _coordinator.pullSubset(const {kAttendanceResource});
}
