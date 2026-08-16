import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';

/// Hydrate l'écran Classes à son montage (ADR-015 F6) : classes
/// (`ref_classrooms`) **et** roster (`ref_classroom_members`).
///
/// **Ne tire plus le repository en direct.** Ce déclencheur passe désormais par
/// le `PullCoordinator`, seul à connaître l'ordre, les droits et — bientôt — le
/// plan de synchronisation. La pré-garde de connectivité, la sonde de
/// crédentiels, le filtre de permission, l'isolation des échecs et la diffusion
/// sur le `PullCompletionBus` sont partis dans le socle, pour tout le monde. Ce
/// use case ne porte plus qu'une chose : **de quelles ressources cet écran a
/// besoin**.
///
/// ## L'année n'est plus passée par l'écran — et c'est un couplage figé
///
/// L'ancien chemin recevait un `academicYearId` **explicite**, celui que l'écran
/// tenait de l'`AcademicYearContextBloc`. Les handlers du coordinateur
/// (`ClassroomPullHandler`, `ClassroomMemberPullHandler`) résolvent l'année
/// **courante** eux-mêmes.
///
/// Les deux coïncident aujourd'hui, et pas par chance : l'écran lit
/// `AcademicYearContextRepositoryImpl.loadCurrentContext()`, qui appelle
/// `EnrollmentReferentialDao.findCurrentAcademicYearId(schoolId)` — la ligne
/// exacte qu'exécutent les deux handlers. Même DAO, même requête
/// (`is_current = 1`, scopée école), même source.
///
/// ⚠️ Ce qui était un paramètre devient donc une **hypothèse** : le jour où
/// l'écran Classes offrirait un sélecteur d'année (consulter l'année
/// précédente), il afficherait cette année-là pendant que ce pull continuerait,
/// en silence, d'hydrater la courante. Aucun test ne rougirait. Ce jour-là, il
/// faudra un pull scopé — pas un `academicYearId` remis dans ce use case, qui
/// n'a plus de main sur ce que fait le handler.
///
/// Le second déclencheur reste le cycle complet du coordinateur (ouverture de
/// session, retour online) : une tablette posée sur le Wi-Fi de l'école ne
/// verrait aucun retour online de la journée.
class SyncClassroomsUseCase {
  /// Les ressources dont l'écran Classes a besoin. Publique parce que le BLoC
  /// doit savoir sur **quoi** interroger `PullRunReport.succeeded` : sans elle,
  /// la présentation importerait les clés de routage de la couche data.
  static const Set<String> resources = {
    kClassroomsResource,
    kClassroomMembersResource,
  };

  final PullCoordinator _coordinator;

  const SyncClassroomsUseCase(this._coordinator);

  Future<PullRunReport> call() => _coordinator.pullSubset(resources);
}
