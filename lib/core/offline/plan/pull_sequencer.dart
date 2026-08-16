import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';

/// Une arête d'ordre que **le plan ne peut pas inverser**.
///
/// Ce ne sont pas des dépendances au sens de `dependsOn` — le serveur n'en
/// déclare aucune entre les deux flux de la paire Finance, et il a raison : leur
/// ordre ne vient pas d'un besoin de donnée mais d'un **sens de panne**. Un tri
/// topologique n'ordonne que les paires liées ; celles-ci lui sont invisibles.
class MoneyGradeEdge {
  final String before;
  final String after;

  /// Ce qui arrive si l'ordre s'inverse. Écrit ici plutôt qu'en commentaire :
  /// c'est ce que le test affiche quand il rougit.
  final String consequence;

  const MoneyGradeEdge({
    required this.before,
    required this.after,
    required this.consequence,
  });
}

/// Les quatre arêtes que le front refuse de laisser inverser.
///
/// Trois échouent en silence, la quatrième fait réencaisser. Aucune n'est
/// détectable à l'exécution : c'est pourquoi elles sont déclarées.
///
/// ⚠️ Elles n'ont **pas** la même gravité, et les traiter à égalité serait un
/// mauvais arbitrage — voir [PullSequencer.sequence], qui écarte l'ordre du plan
/// en bloc plutôt que de punir un flux.
const List<MoneyGradeEdge> kMoneyGradeEdges = [
  MoneyGradeEdge(
    before: SyncPlanKeys.financeStudentCharges,
    after: SyncPlanKeys.financePayments,
    // Le sens de panne, et lui seul, décide de l'ordre. Créances OK / paiements
    // KO : le solde autoritaire compte déjà un paiement local non-SYNCED, la
    // créance s'affiche SUR-payée, le caissier REFUSE un encaissement — friction,
    // aucun argent perdu, et ça se résorbe seul. Paiements OK / créances KO :
    // un paiement encaissé sur un AUTRE poste est inséré SYNCED au-dessus d'un
    // `amount_paid_in_cents` encore périmé, la créance s'affiche IMPAYÉE, et le
    // caissier RÉENCAISSE.
    consequence: 'le caissier réencaisse — argent perdu',
  ),
  MoneyGradeEdge(
    before: SyncPlanKeys.schoolReferential,
    after: SyncPlanKeys.classroomClassrooms,
    consequence:
        'les classes échouent faute de référentiel — PullOutcome.error',
  ),
  MoneyGradeEdge(
    before: SyncPlanKeys.academicsGradesReferential,
    after: SyncPlanKeys.academicsCours,
    consequence: 'le détail des cours se compose sans barème — cycle perdu',
  ),
  MoneyGradeEdge(
    before: SyncPlanKeys.academicsCours,
    after: SyncPlanKeys.academicsEvaluations,
    // Les évaluations itèrent les cours LOCAUX : sans cours en base, la boucle
    // ne fait aucun appel réseau et rend « rien de neuf ». Le curseur avance sur
    // un vide, et personne ne voit qu'il ne s'est rien passé.
    consequence: 'zéro appel réseau, en silence',
  ),
];

/// Pourquoi la séquence n'est pas celle du plan.
enum SequenceFallback {
  /// Le plan gouverne l'ordre.
  none,

  /// Aucun plan exploitable : ordre d'enregistrement.
  noPlan,

  /// Le graphe `dependsOn` contient un cycle.
  cycle,

  /// L'ordre du plan inverserait une arête money-grade.
  moneyGradeViolation,
}

/// Une séquence de clés, et la raison de sa forme.
class PullSequence {
  /// Les ressources de handler à exécuter, dans l'ordre.
  final List<String> resources;

  final SequenceFallback fallback;

  /// L'arête violée, quand [fallback] vaut [SequenceFallback.moneyGradeViolation].
  final MoneyGradeEdge? violated;

  const PullSequence({
    required this.resources,
    required this.fallback,
    this.violated,
  });
}

/// Calcule l'ordre d'exécution d'un cycle de pull (ADR-015 F4).
///
/// ## Registre ≠ séquence
///
/// Le registre du coordinateur reste une `Map` de *lookup* ; l'ordre devient une
/// liste produite ici. Ré-enregistrer les handlers dans l'ordre du plan ne
/// réordonnerait rien : une `LinkedHashMap` conserve la position d'insertion
/// d'origine quand on réécrit une clé existante.
///
/// ## Ce que ce séquenceur est vraiment
///
/// Le serveur envoie `streams` **déjà trié topologiquement** : un client naïf
/// itère le tableau et a raison. Kahn n'est donc pas ce qui rend l'ordre
/// correct — il n'existe ici que pour les clients qui voudraient paralléliser,
/// et surtout pour **détecter un cycle**. La valeur du lot est ailleurs : dans
/// les gardes, qui refusent un ordre money-grade inversé au lieu de l'appliquer
/// poliment.
///
/// ## Repli en cascade
///
/// Plan absent → ordre d'enregistrement. Cycle → ordre du plan tel que reçu.
/// Arête money-grade violée → ordre d'enregistrement, **en bloc**. Ce dernier
/// point est un arbitrage : écarter le seul flux fautif punirait un cycle entier
/// pour une inversion parfois bénigne, et laisserait la tablette dans un état
/// que personne n'a décrit. L'ordre local, lui, est connu et sûr.
abstract final class PullSequencer {
  /// [registered] est l'ordre d'enregistrement des ressources — le repli sûr.
  static PullSequence sequence({
    required List<String> registered,
    SyncPlan? plan,
  }) {
    if (plan == null || plan.streams.isEmpty) {
      return PullSequence(
        resources: List.unmodifiable(registered),
        fallback: SequenceFallback.noPlan,
      );
    }

    final ordered = _topological(plan);
    final fallback = ordered == null
        ? SequenceFallback.cycle
        : SequenceFallback.none;
    final keys = ordered ?? plan.keys;

    final violated = _firstViolation(keys);
    if (violated != null) {
      return PullSequence(
        resources: List.unmodifiable(registered),
        fallback: SequenceFallback.moneyGradeViolation,
        violated: violated,
      );
    }

    return PullSequence(
      resources: _resources(keys, registered),
      fallback: fallback,
    );
  }

  /// Kahn sur `dependsOn`. `null` si le graphe contient un cycle.
  ///
  /// Le graphe est **toujours clos** : le serveur élague `dependsOn` aux clés
  /// présentes dans ce plan, donc une arête ne pointe jamais hors du plan. Une
  /// arête sortante est néanmoins ignorée plutôt que traitée en erreur — un
  /// serveur qui cesserait d'élaguer ne doit pas geler le pull.
  ///
  /// L'ordre du plan sert de départage à degré égal : le serveur a déjà trié, et
  /// s'écarter de son ordre sans raison le contredirait.
  static List<String>? _topological(SyncPlan plan) {
    // Dédoublonné en préservant l'ordre. Sans cela, une clé reçue deux fois
    // n'occupe qu'une entrée dans `inDegree`/`dependents` mais deux dans la
    // liste : le compte final ne retomberait jamais juste et un graphe
    // parfaitement acyclique serait déclaré cyclique. Le serveur n'envoie pas
    // de doublon, mais l'analyse est tolérante par contrat — et un faux cycle
    // ferait mentir le diagnostic sans qu'aucun symptôme ne le trahisse.
    final keys = <String>[
      ...{...plan.keys},
    ];
    final present = keys.toSet();
    final inDegree = <String, int>{for (final k in keys) k: 0};
    final dependents = <String, List<String>>{for (final k in keys) k: []};

    for (final flow in plan.streams) {
      for (final parent in flow.dependsOn) {
        if (!present.contains(parent)) continue;
        dependents[parent]!.add(flow.key);
        inDegree[flow.key] = inDegree[flow.key]! + 1;
      }
    }

    // File amorcée dans l'ordre du plan, et réalimentée en le respectant.
    final ready = keys.where((k) => inDegree[k] == 0).toList();
    final sorted = <String>[];
    while (ready.isNotEmpty) {
      final key = ready.removeAt(0);
      sorted.add(key);
      for (final child in dependents[key]!) {
        final left = inDegree[child]! - 1;
        inDegree[child] = left;
        if (left == 0) ready.add(child);
      }
    }

    return sorted.length == keys.length ? sorted : null;
  }

  /// La première arête money-grade que cet ordre inverserait, ou `null`.
  ///
  /// Une arête dont l'un des deux flux est absent du plan n'est pas violée :
  /// elle est sans objet. Un comptable qui ne reçoit pas `academics.cours` ne
  /// doit pas voir tout son cycle retomber en repli pour une arête qui ne le
  /// concerne pas.
  static MoneyGradeEdge? _firstViolation(List<String> keys) {
    final rank = <String, int>{
      for (var i = 0; i < keys.length; i++) keys[i]: i,
    };
    for (final edge in kMoneyGradeEdges) {
      final before = rank[edge.before];
      final after = rank[edge.after];
      if (before == null || after == null) continue;
      if (before > after) return edge;
    }
    return null;
  }

  /// Projette les clés de plan sur les ressources réellement enregistrées.
  ///
  /// Trois règles, toutes destinées à ne rien perdre :
  ///  - une clé inconnue de l'alias, ou dont aucune ressource n'est enregistrée,
  ///    est sautée — c'est un flux que ce client ne sait pas tirer, et le
  ///    coordinateur le comptera nommément ;
  ///  - l'ordre **interne** d'une clé à plusieurs ressources est celui de
  ///    l'alias, jamais celui du plan : c'est là que vit la paire hydratant /
  ///    delta, dont l'inversion viderait les dossiers en silence ;
  ///  - une ressource enregistrée qu'aucune clé ne couvre est ajoutée **à la
  ///    fin**, dans son ordre d'enregistrement. Elle n'est pas au plan, mais ce
  ///    lot ne décide pas encore qui tire : tant que le plan n'est pas
  ///    l'autorité (lot F5), l'écarter ici serait franchir la ligne sans le dire.
  static List<String> _resources(List<String> keys, List<String> registered) {
    final known = registered.toSet();
    final out = <String>[];
    final placed = <String>{};

    for (final key in keys) {
      for (final resource in resourcesOf(key)) {
        if (!known.contains(resource)) continue;
        if (placed.add(resource)) out.add(resource);
      }
    }
    for (final resource in registered) {
      if (placed.add(resource)) out.add(resource);
    }
    return List.unmodifiable(out);
  }
}
