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
/// ## Le résultat est partagé, pas recalculé — et c'est pour cela qu'il y a
/// deux voies
///
/// Un appelant qui se coalesce reçoit **le futur de l'autre**, donc son
/// résultat. C'est cohérent avec ce qu'il demandait : un cycle qui démarre après
/// son appel.
///
/// ⚠️ Mais tous les appelants n'attendent pas la même chose. Les handlers du
/// coordinateur veulent **leur issue** (`PullOutcome`) ; les écrans qui tirent
/// hors coordinateur veulent seulement que la ressource soit à jour. Une seule
/// voie générique les mélangeait : un `guarded('enrollments', …)` programmé avec
/// `T = void`, puis le cycle du coordinateur sur la même ressource, et ce
/// dernier recevait le futur du premier — `null as PullOutcome` lève, le `catch`
/// du coordinateur compte un échec, et `handler.pull()` **ne tourne jamais**.
/// La ressource ainsi perdue est l'Inscription, source de `students`, donc de
/// la Facturation, du Contrôle des frais, des Documents et du ticket imprimé.
///
/// D'où [run] et [runIgnoringResult] :
///  - seuls les cycles de [run] sont enregistrés comme **coalesçables**, si bien
///    que le transtypage qui les partage ne voit jamais qu'un cycle du même
///    type — une ressource n'ayant qu'un handler ;
///  - [runIgnoringResult] se coalesce volontiers sur eux (il **ignore** la
///    valeur, donc ne transtype rien) mais ne s'offre jamais en retour : un
///    appelant qui a besoin d'une issue chaînera derrière lui plutôt que de
///    recevoir un `void`. Le surcoût est un cycle de plus, c'est-à-dire un 304 ;
///    le prix de l'erreur inverse était une ressource jamais tirée.
class PullCycleGuard {
  final Map<String, Future<Object?>> _tail = {};
  final Map<String, Future<Object?>> _queued = {};

  /// Exécute [cycle] pour [resource] et **rend son issue**, sérialisé avec les
  /// cycles déjà en vol ou déjà programmés sur la même ressource.
  Future<T> run<T>(String resource, Future<T> Function() cycle) {
    // Un cycle est programmé mais pas encore parti → il lira le curseur après
    // nous : il fait l'affaire, et son résultat est le nôtre. Il vient
    // forcément de cette voie-ci (cf. docstring de classe), donc du même type.
    final queued = _queued[resource];
    if (queued != null) return queued.then((value) => value as T);
    return _schedule<T>(resource, cycle, coalescable: true);
  }

  /// Exécute [cycle] pour [resource] sans que personne n'en attende l'issue —
  /// les pulls lancés hors coordinateur (ADR-015 F6).
  ///
  /// Se coalesce sur un cycle programmé s'il y en a un, **sans lire sa
  /// valeur** : ce qui est demandé ici est un état à jour, pas un résultat.
  Future<void> runIgnoringResult(
    String resource,
    Future<void> Function() cycle,
  ) {
    final queued = _queued[resource];
    if (queued != null) return queued.then((_) {});
    return _schedule<void>(resource, cycle, coalescable: false);
  }

  Future<T> _schedule<T>(
    String resource,
    Future<T> Function() cycle, {
    required bool coalescable,
  }) {
    final tail = _tail[resource];
    late final Future<T> scheduled;
    final run = tail == null
        ? cycle()
        : _chainAfter<T>(tail, resource, () => scheduled, cycle);
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
    if (tail != null && coalescable) _queued[resource] = scheduled;
    return scheduled;
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
  Future<T> _chainAfter<T>(
    Future<Object?> tail,
    String resource,
    Future<T> Function() scheduled,
    Future<T> Function() cycle,
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
