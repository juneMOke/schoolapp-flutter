import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';

/// Le seam paiements du grand-livre, **routé par le coordinateur** — treizième
/// porte dérobée du lot F6 (ADR-015), refermée après coup.
///
/// ## Ce qui échappait, et pourquoi ce n'était pas l'exemption prévue
///
/// Le plan §F6 exemptait bien un flux Finance du passage par le coordinateur :
/// `finance_ledger:<studentId>`, dont la clé est **dynamique par élève** et que
/// le serveur ne sait pas énumérer. `FinanceLedgerRefresher` a deux jambes, et
/// seule la première est celle-là. La seconde — l'avancement du cycle des
/// paiements — est le flux **GLOBAL** : clé de plan `finance.payments`, handler
/// `finance_payments` enregistré comme les autres. Rien ne le distingue des
/// douze portes que F6 a fermées, sinon qu'il était câblé dans l'ombre d'un
/// voisin légitimement exempté.
///
/// Il échappait donc à trois choses : l'autorité du plan (F5), le filtre de
/// droits, et la diffusion sur le `PullCompletionBus`.
///
/// ## Ce qui n'était PAS en jeu
///
/// Aucune perte de donnée, et il faut le dire pour ne pas surestimer le
/// correctif. Le curseur keyset est protégé en amont : `FinancePullRepository`
/// sérialise **par ressource**, et les deux chemins — le handler du coordinateur
/// et cet appel-ci — traversent la même instance. Deux cycles concurrents ne
/// pouvaient donc pas rembobiner le curseur l'un sur l'autre.
///
/// Ce qui échappait rendait le pull plus **large** que le plan, jamais plus
/// étroit. Même classe que le portail captif : le serveur reste la frontière,
/// c'est la propriété centrale de F5 qui était trouée.
///
/// ## Pourquoi une classe et non une fermeture dans la DI
///
/// Parce qu'une fermeture anonyme n'est pas testable, et que ce chantier a payé
/// cher pour l'apprendre : une garde peut être écrite, testée, et n'être jamais
/// branchée. Ce routage-ci a son test.
class CoordinatorPaymentsSync {
  final PullCoordinator _coordinator;

  const CoordinatorPaymentsSync(this._coordinator);

  /// L'ensemble demandé, **toujours réduit à cette seule ressource**.
  ///
  /// Y ajouter `finance_student_charges` serait tentant — l'arête money-grade
  /// va des créances aux paiements. Ce serait pourtant un doublon nuisible : le
  /// refresher vient de rafraîchir les créances **de cet élève** par un point
  /// read scopé, et n'appelle ce seam que si ce point read a abouti. Tirer en
  /// plus le delta global des créances rejouerait un cycle de masse dans un
  /// chemin de LECTURE borné à quelques secondes.
  static const Set<String> resources = {
    FinancePullRepositoryImpl.paymentsResource,
  };

  /// `true` si l'historique local des paiements est à jour.
  ///
  /// **304 compris** : « rien n'a changé » veut dire que le miroir est bon, pas
  /// qu'il a échoué — même règle que le point read des créances, et
  /// [PullRunReport.succeeded] la porte déjà.
  ///
  /// Tout le reste rend `false`, et chaque cas mérite de l'être :
  ///  - **hors plan** : le profil n'a pas les paiements à son périmètre. Rien
  ///    n'a été tiré, donc rien n'autorise à afficher une fraîcheur. C'est aussi
  ///    ce qui se produisait avant, en plus coûteux : l'appel partait, le
  ///    serveur répondait 403, et le verdict était le même ;
  ///  - **hors ligne / sans jetons** : le cycle n'a rien observé ;
  ///  - **échec** : l'historique reste au dernier état connu.
  ///
  /// ⚠️ Ne jamais rendre `true` par défaut. Cette valeur commande l'estampille
  /// « à jour à HHhMM » sous les totaux, et l'écran replie l'historique en
  /// « total payé » : annoncer frais un historique qu'on n'a pas tiré ferait
  /// **réencaisser** un versement déjà reçu à l'autre poste.
  Future<bool> call() async {
    final report = await _coordinator.pullSubset(resources);
    return report.succeeded(FinancePullRepositoryImpl.paymentsResource);
  }
}
