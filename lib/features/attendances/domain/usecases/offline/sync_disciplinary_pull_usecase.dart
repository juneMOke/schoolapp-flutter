import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_pull_repository_impl.dart';

/// Hydrate la Discipline au montage de la fiche élève (ADR-015 F6).
///
/// **Ne tire plus le repository en direct.** Ce déclencheur passe désormais par
/// le `PullCoordinator`, qui reste seul à connaître l'ordre, les droits et —
/// bientôt — le plan de synchronisation. Tant que des écrans tiraient à côté, la
/// largeur effective du pull était l'union du coordinateur et d'une douzaine de
/// portes dérobées : faire du plan l'autorité du seul coordinateur n'aurait rien
/// resserré.
///
/// Ce qui vivait ici et vit maintenant dans le socle, pour tout le monde : la
/// pré-garde de connectivité, la sonde de crédentiels, le filtre de permission,
/// l'isolation des échecs et la diffusion sur le `PullCompletionBus`. Ce use
/// case ne porte plus qu'une chose — **de quelles ressources cet écran a
/// besoin**.
///
/// Le second déclencheur reste le cycle complet du coordinateur (ouverture de
/// session, retour online). Les deux sont nécessaires : une tablette posée sur
/// le Wi-Fi de l'école ne verrait aucun retour online de la journée.
///
/// ## La garde de la page reste, et ce n'est pas une redondance
///
/// `DisciplinaryStudentDetailPage` n'appelle ce use case que derrière
/// `PermissionGate.allows(context, [Perm.disciplineRead])`, et le coordinateur
/// filtre maintenant sur la même permission (`DisciplinaryPullHandler`). On
/// garde les deux, pour trois raisons qui ne se recouvrent pas :
///
///  1. **elles ne gardent pas la même chose** — la garde de la page décide de
///     l'*affichage* du volet Discipline et de sa pastille ; celle du socle
///     décide du *pull*. Retirer la première ne supprimerait pas un appel
///     réseau, elle afficherait un volet vide à qui n'a pas le droit de le
///     voir, ce que le test de gating de la page interdit précisément ;
///  2. **le filtre du socle est fail-open** — `CurrentPermissions` rend `null`
///     tant que la session n'a pas alimenté le holder, et le coordinateur tire
///     alors quand même. La garde de la page, elle, lit l'`AuthBloc` : à
///     l'amorçage, c'est la seule des deux qui refuse ;
///  3. **elle évite un aller-retour inutile** — le `pullSubset` d'un profil sans
///     droit ne ferait que compter un `forbidden` de plus.
///
/// Le sens de panne est asymétrique et c'est ce qui tranche : une garde en trop
/// ne coûte qu'un appel non fait ; une garde en moins montre une donnée
/// disciplinaire à qui n'y a pas droit.
class SyncDisciplinaryPullUseCase {
  /// Les ressources dont la fiche élève a besoin — la seule chose que ce use
  /// case possède encore.
  static const Set<String> resources = {kDisciplinaryResource};

  final PullCoordinator _coordinator;

  const SyncDisciplinaryPullUseCase(this._coordinator);

  Future<PullRunReport> call() => _coordinator.pullSubset(resources);
}
