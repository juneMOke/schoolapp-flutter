import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';

/// Hydrate le référentiel Classe complet — classes (`ref_classrooms`), roster
/// (`ref_classroom_members`) **et** transferts (`classroom_transfers`) — au
/// montage des scopes qui **consomment** le roster sans l'afficher (Présence,
/// Contrôle des frais).
///
/// **Ne tire plus les repositories en direct** (ADR-015 F6) : tout passe par le
/// `PullCoordinator`. Ce qui vivait ici et vit maintenant dans le socle, pour
/// tout le monde : la pré-garde de connectivité, la sonde de crédentiels, le
/// filtre de permission, l'isolation des échecs par ressource et la diffusion
/// sur le `PullCompletionBus`. Il ne reste que **de quelles ressources ces
/// scopes ont besoin**.
///
/// ## Ce qui a disparu d'ici sans disparaître du produit
///
///  - **la résolution de l'année** : ce use case interrogeait
///    `EnrollmentReferentialDao` parce qu'il appelait un repository qui exige un
///    `academicYearId`. Les deux handlers Classe résolvent la même année par la
///    même ligne de DAO ; le détour n'a plus d'objet ;
///  - **l'ordre classes → transferts** : il vient maintenant de l'ordre du
///    registre du coordinateur, où `classrooms` est enregistré avant
///    `classroom_transfers` (ancré par
///    `test/core/di/offline_pull_registration_order_test.dart`). L'invariant
///    était de toute façon plus doux que son commentaire : `school_level_id` est
///    résolu depuis `ref_classrooms` à l'application du delta, mais ce champ
///    n'est **pas lu** sur une ligne SYNCED — et le pull n'écrit que du SYNCED ;
///  - **l'isolation d'un échec des transferts** : le coordinateur isole par
///    handler, et l'arête classes → transferts n'est pas `blocking`. Un échec des
///    classes ne prive donc toujours pas les transferts de leur cycle.
///
/// ## Ce qui devait survivre, et qui survit : le marqueur de bootstrap
///
/// Ce use case était le SEUL porteur de montage du marqueur de bootstrap des
/// transferts, sans lequel l'onglet Présence de la fiche élève reste à vie sur
/// « Synchronisation en attente » (ADR-015 §6-D) : `classroom.transfers` ne
/// descendait sinon qu'au retour *online*, jamais vu par une tablette démarrée
/// déjà connectée.
///
/// Le marqueur n'a jamais été posé par ce use case : il l'est par
/// `ClassroomTransferPullRepositoryImpl._runCycle`, qui écrit
/// `classroom_transfers_bootstrap` dès qu'un cycle atteint `hasMore = false`.
/// `ClassroomTransferPullHandler.pull()` appelle **exactement** la même
/// `syncTransfers()`. Le chemin est identique ; seul l'appelant change. La
/// justification survit donc au repli — à une condition, désormais réelle : que
/// la session ait `classroom.read`, sinon le coordinateur saute la ressource.
/// Ce n'est pas une régression (le serveur garde le même endpoint sur le même
/// droit : l'ancien appel direct partait en 403, sans marqueur non plus), mais
/// c'est un refus qui devient **local et silencieux** au lieu de venir du
/// serveur.
class SyncClassroomReferentialUseCase {
  /// Les trois ressources du référentiel Classe. `classroom_transfers` n'est pas
  /// décoratif : c'est lui qui pose le marqueur de bootstrap (cf. docstring).
  static const Set<String> resources = {
    kClassroomsResource,
    kClassroomMembersResource,
    kClassroomTransfersResource,
  };

  final PullCoordinator _coordinator;

  const SyncClassroomReferentialUseCase(this._coordinator);

  /// Best-effort : ne lève pas, et aucun appelant n'observe le rapport — les
  /// deux scopes l'appellent en `unawaited`, l'UI lit le local de toute façon.
  Future<PullRunReport> call() => _coordinator.pullSubset(resources);
}
