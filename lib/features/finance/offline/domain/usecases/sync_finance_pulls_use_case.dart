import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';

/// Hydrate le grand-livre au montage du scope Facturation (ADR-015 F6) — le
/// caissier ouvre la Facturation **pendant** qu'il a du réseau, avant de partir
/// encaisser hors-ligne.
///
/// **Ne tire plus le repository en direct.** Ce déclencheur passe désormais par
/// le `PullCoordinator`, qui reste seul à connaître l'ordre, les droits et —
/// bientôt — le plan de synchronisation. Tant que des écrans tiraient à côté, la
/// largeur effective du pull était l'union du coordinateur et d'une douzaine de
/// portes dérobées, aucune filtrée par une permission.
///
/// Ce qui vivait ici et vit maintenant dans le socle, pour tout le monde : la
/// pré-garde de connectivité, la sonde de crédentiels, le filtre de permission,
/// l'isolation des échecs et la diffusion sur le `PullCompletionBus`. Ce use
/// case ne porte plus qu'une chose — **de quelles ressources cet écran a
/// besoin**.
///
/// Le second déclencheur reste le cycle complet du coordinateur (ouverture de
/// session, retour online) : une tablette posée sur le Wi-Fi de l'école ne
/// verrait aucun retour online de la journée.
///
/// ## ⚠️ La garde money-grade a été portée dans le socle, pas perdue
///
/// Ce use case portait une règle que rien d'autre n'avait : **créances KO ⇒ on
/// ne tente même pas les paiements**. Le sens de panne est asymétrique et c'est
/// tout l'argument — créances OK / paiements KO fait *refuser* un encaissement
/// (friction, argent sauf, se résorbe seul) ; paiements OK / créances KO insère
/// un versement SYNCED par-dessus un `amount_paid_in_cents` périmé, la créance
/// s'affiche impayée et le caissier **réencaisse**.
///
/// Elle vit maintenant à deux endroits du socle, et il faut les deux :
///  - `MoneyGradeEdge.blocking`, vrai pour la **seule** arête
///    `finance.student-charges` → `finance.payments` (les trois autres arêtes
///    n'ont pas ce sens de panne et laissent leur aval s'exécuter) ;
///  - `PullCoordinator._isBlockedBy`, qui écarte l'aval du cycle en cours et le
///    compte en `PullRunReport.blocked` — à part de `failed`, parce que rien n'a
///    échoué : on s'est abstenu.
///
/// La jonction entre les deux est la table d'alias `planKeyOf` : la garde ne
/// mord que si `finance_payments` s'y traduit bien en `finance.payments`. Une
/// clé mal orthographiée rouvrirait la porte **en silence**, d'où le test qui
/// prouve l'abandon pour ce chemin précis, et pas seulement l'ordre.
///
/// ## L'ordre vient du registre, jamais des accolades
///
/// `pullSubset` itère le registre filtré par l'ensemble reçu — un `Set` littéral
/// n'a pas d'ordre porteur. L'ordre créances → paiements est tenu par la DI et
/// verrouillé par `offline_pull_registration_order_test`.
class SyncFinancePullsUseCase {
  final PullCoordinator _coordinator;

  const SyncFinancePullsUseCase(this._coordinator);

  Future<PullRunReport> call() => _coordinator.pullSubset(const {
    FinancePullRepositoryImpl.chargesResource,
    FinancePullRepositoryImpl.paymentsResource,
  });
}
