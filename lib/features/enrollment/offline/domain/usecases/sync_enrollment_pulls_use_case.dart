import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';

/// Hydrate les caches Inscription au montage des scopes qui en dépendent
/// (ADR-015 F6) : Inscription, Facturation et Documents — les trois écrans dont
/// la recherche d'élève lit les dossiers locaux.
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
/// l'isolation des échecs et la diffusion sur le `PullCompletionBus`. Ce use
/// case ne porte plus qu'une chose — **de quelles ressources ces écrans ont
/// besoin** — et c'est la seule qui lui appartienne vraiment.
///
/// Le second déclencheur reste le cycle complet du coordinateur (ouverture de
/// session, retour online). Les deux sont nécessaires : une tablette posée sur
/// le Wi-Fi de l'école ne verrait aucun retour online de la journée.
///
/// ## L'ordre porteur n'est plus ici — et c'est voulu
///
/// L'hydratant (`enrollment_snapshots`, qui INSERT) doit précéder le delta
/// (`enrollments`, qui ne fait qu'UPDATE) : inversés, le delta consomme son
/// backlog sans lignes à mettre à jour et le curseur avance sur des dossiers que
/// plus rien ne redemandera — muets, sans la moindre erreur.
///
/// Cet ordre est désormais tenu par **l'ordre d'enregistrement en DI**, que
/// `pullSubset` respecte : il itère le registre filtré par l'ensemble reçu,
/// jamais l'ensemble lui-même. Les accolades ci-dessous n'ordonnent donc rien —
/// un `Set` littéral n'a pas d'ordre porteur, et il serait malsain qu'une arête
/// money-grade dépende de la façon dont un développeur a tapé sa liste.
/// L'invariant est verrouillé là où il vit : `offline_pull_registration_order_test`
/// exige que la DI enregistre les snapshots avant le delta.
///
/// ## Conséquence à ne pas redécouvrir dans six mois : `enrollment.read`
///
/// Avant ce repli, la Facturation et les Documents tiraient les cinq flux
/// Inscription **sans aucun filtre de permission**. Le coordinateur, lui,
/// applique `requiredPermissions` : quatre de ces cinq flux exigent
/// `enrollment.read` (le cinquième, le référentiel, est le seul flux socle du
/// dépôt et reste exempté — sans lui la porte de navigation ne s'ouvre pas).
///
/// Les gabarits de rôle par défaut qui atteignent ces trois écrans détiennent
/// tous `enrollment.read` (secrétariat, comptabilité, direction des études,
/// discipline, direction — cf. `test/core/auth/role_journeys_test.dart` ;
/// l'enseignant ne l'a pas, mais n'a ni `finance.*.read` ni `editique.read`, donc
/// n'ouvre aucun de ces trois scopes). **Rien ne casse pour eux.**
///
/// En revanche un rôle **personnalisé** doté de `finance.charge.read` sans
/// `enrollment.read` verra sa recherche d'élève rester vide en Facturation et en
/// Documents : ses dossiers locaux ne seront plus hydratés. C'est le périmètre
/// correct — le serveur aurait répondu 403 de toute façon — mais c'est un
/// changement de comportement observable, et il se diagnostique par
/// `PullRunReport.forbidden`.
class SyncEnrollmentPullsUseCase {
  final PullCoordinator _coordinator;

  const SyncEnrollmentPullsUseCase(this._coordinator);

  Future<PullRunReport> call() => _coordinator.pullSubset(const {
    EnrollmentPullRepositoryImpl.referentialResource,
    EnrollmentPullRepositoryImpl.cohortResource,
    EnrollmentPullRepositoryImpl.preEnrollmentsResource,
    EnrollmentPullRepositoryImpl.snapshotsResource,
    EnrollmentPullRepositoryImpl.deltaResource,
  });
}
