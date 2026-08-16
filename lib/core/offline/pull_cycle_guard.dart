import 'dart:async';

/// Sérialise les cycles de pull d'une **ressource** — en chaînant, jamais en
/// rejoignant un cycle déjà parti.
///
/// ## Pourquoi pas un verrou global
///
/// Le coordinateur a déjà un verrou de cycle (`_pulling`), et il est le bon
/// pour ce qu'il garde : un second cycle *complet* pendant qu'un premier tourne
/// n'apporterait rien. Mais l'appliquer aux pulls **ciblés** — ceux qu'un écran
/// lance à son montage — produirait la panne exacte que ces pulls existent à
/// éviter : un écran ouvert pendant un cycle global recevrait « sauté » et
/// resterait sur un cache froid. Depuis que le cycle complet part aussi à
/// l'ouverture de session, cette fenêtre tombe précisément au démarrage, quand
/// l'utilisateur ouvre son premier écran.
///
/// ## Pourquoi pas « aucun verrou »
///
/// Sans sérialisation, deux cycles keyset écrivent le même curseur en
/// concurrence. Les upserts sont idempotents — au pire un re-pull redondant —
/// mais **les curseurs ne le sont pas** : le second cycle a lu le curseur avant
/// que le premier ne l'avance, et le réécrit ensuite en arrière ou en avant
/// selon l'ordre d'arrivée des pages.
///
/// Neuf des douze repositories de pull se protègent déjà eux-mêmes, chacun avec
/// sa copie de ce mécanisme. Les trois qui ne le font pas incluent l'Inscription
/// — tirée depuis quatre endroits, et source de `students`, donc de Facturation,
/// du Contrôle des frais, de Documents et du ticket imprimé. Poser le garde au
/// niveau du coordinateur couvre ces trois-là sans toucher aux neuf autres, chez
/// qui il ne fait qu'une couche redondante et inoffensive.
///
/// ## Chaîner plutôt que rejoindre
///
/// Rejoindre un cycle en vol serait tentant — un seul appel réseau — mais
/// **mentirait sur la fraîcheur** : ce cycle a lu son curseur AVANT l'appel du
/// nouvel arrivant, il ne peut donc pas contenir ce qui a été écrit entre-temps
/// sur un autre poste. On garantit à chaque appelant un cycle qui **démarre
/// après son appel**.
///
/// La chaîne est bornée à **deux** : un qui tourne, un qui attend. Tant que le
/// cycle en attente n'est pas parti, il satisfait tous les arrivants, qui s'y
/// coalescent. Les cycles surnuméraires ne coûtent qu'un 304.
///
/// Repris de `FinancePullRepositoryImpl._guarded`, où ce raisonnement a été
/// écrit et éprouvé sur la ressource la plus chère du dépôt. Extrait ici parce
/// que le socle en a désormais besoin pour toutes les ressources, pas seulement
/// pour l'argent.
/// ## Le résultat est partagé, pas recalculé
///
/// Un appelant qui se coalesce reçoit **le futur de l'autre**, donc son
/// résultat. C'est cohérent avec ce qu'il demandait : un cycle qui démarre après
/// son appel. Tous les appelants d'une même ressource doivent donc attendre le
/// même type de résultat — c'est le cas par construction, une ressource n'ayant
/// qu'un handler.
class PullCycleGuard {
  final Map<String, Future<Object?>> _tail = {};
  final Map<String, Future<Object?>> _queued = {};

  /// Exécute [cycle] pour [resource], sérialisé avec les cycles déjà en vol ou
  /// déjà programmés sur la même ressource.
  Future<T> run<T>(String resource, Future<T> Function() cycle) {
    // Un cycle est programmé mais pas encore parti → il lira le curseur après
    // nous : il fait l'affaire, et son résultat est le nôtre.
    final queued = _queued[resource];
    if (queued != null) return queued.then((value) => value as T);

    final tail = _tail[resource];
    late final Future<Object?> scheduled;
    final run = tail == null
        ? cycle()
        : _chainAfter(tail, resource, () => scheduled, cycle);
    // Corps en BLOC, pas en expression : `Map.remove` renvoie la valeur retirée
    // — ici le futur qu'on est en train de terminer — et `whenComplete` attend
    // tout futur que son rappel renvoie. En flèche, le cycle s'attendrait
    // lui-même : interblocage.
    scheduled = run.whenComplete(() {
      if (identical(_tail[resource], scheduled)) _tail.remove(resource);
      if (identical(_queued[resource], scheduled)) _queued.remove(resource);
    });
    // Aucun `await` entre la programmation et l'enregistrement : la pose du
    // garde est atomique vis-à-vis de la boucle d'événements.
    _tail[resource] = scheduled;
    if (tail != null) _queued[resource] = scheduled;
    return scheduled.then((value) => value as T);
  }

  /// Attend le cycle précédent **quel que soit son sort**, puis exécute le
  /// nôtre.
  ///
  /// ⚠️ L'échec du précédent ne doit surtout pas emporter le suivant. Écrit
  /// naïvement (`tail.then(...)` sans capter l'erreur), un cycle en échec —
  /// typiquement une coupure réseau — faisait que le cycle chaîné derrière lui
  /// **ne s'exécutait jamais**, et que son appelant recevait l'erreur d'un cycle
  /// qui n'était pas le sien. L'écran qui attendait repartait sur un cache
  /// froid en croyant avoir tiré : la panne exacte que ce garde doit rendre
  /// impossible, au moment précis où elle fait le plus de mal.
  Future<Object?> _chainAfter(
    Future<Object?> tail,
    String resource,
    Future<Object?> Function() scheduled,
    Future<Object?> Function() cycle,
  ) async {
    try {
      await tail;
    } catch (_) {
      // Le sort du précédent appartient à SON appelant, qui l'a déjà reçu.
    }
    // Le nôtre part maintenant : plus personne ne doit s'y coalescer.
    if (identical(_queued[resource], scheduled())) _queued.remove(resource);
    return cycle();
  }

  /// Vrai si un cycle tourne ou attend sur cette ressource (diagnostic/tests).
  bool isBusy(String resource) => _tail.containsKey(resource);
}
