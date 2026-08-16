import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';

/// Ce qu'une tentative d'analyse a produit : un plan, ou la raison de son échec.
///
/// [rejected] porte les clés dont le `mode` ou le `scope` était inconnu — le
/// contrat impose de les ignorer sans erreur, **mais jamais sans trace**, et ce
/// dépôt n'a pas de canal de log.
class SyncPlanParseResult {
  final SyncPlan? plan;
  final Set<String> rejectedKeys;

  const SyncPlanParseResult._(this.plan, this.rejectedKeys);

  const SyncPlanParseResult.malformed() : this._(null, const <String>{});

  const SyncPlanParseResult.parsed(SyncPlan plan, Set<String> rejectedKeys)
    : this._(plan, rejectedKeys);

  bool get isMalformed => plan == null;
}

/// Analyse **positive** d'un corps de réponse en plan de synchronisation.
///
/// ## Pourquoi à la main, et pas `@JsonSerializable`
///
/// Aucun des soixante modèles de la couche offline n'utilise la génération de
/// code, et ce n'est pas seulement une convention : un `fromJson` généré **lève**
/// sur un champ requis absent ou mal typé. Ici, lever revient à confondre « ce
/// corps n'est pas un plan » avec « ce plan est refusé » — or le premier doit
/// produire un repli silencieux, jamais une erreur remontée.
///
/// ## Le piège que cette fonction existe à fermer
///
/// **Sans validation positive, un portail captif qui répond 200 en HTML se lit
/// comme un plan.** Il ne suffit donc pas d'attraper les exceptions : il faut
/// exiger la présence et le type de `planVersion`, `subject`, `onAbsence` et
/// `streams`. Un corps qui n'a pas ces quatre-là n'est pas un plan, quel que
/// soit son code HTTP.
///
/// ## Ce qui est toléré, et ce qui ne l'est pas
///
/// Toléré (le contrat l'exige) : un champ inconnu, un `mode` ou un `scope`
/// inconnu — le flux est alors écarté et sa clé retournée dans
/// [SyncPlanParseResult.rejectedKeys]. Non toléré : l'absence de l'un des
/// quatre champs requis, un `streams` qui n'est pas une liste, un flux sans
/// `key`.
///
/// ⚠️ **`streams` ne passe jamais par `pullList`.** Le helper partagé replie
/// `null` sur la liste vide ; appliqué ici, un plan tronqué deviendrait « plan
/// valide avec zéro flux » — soit, sous F5, l'arrêt total de toute la
/// synchronisation, en silence.
SyncPlanParseResult parseSyncPlan(Object? body) {
  if (body is! Map) return const SyncPlanParseResult.malformed();

  final planVersion = body['planVersion'];
  final subject = body['subject'];
  final onAbsence = body['onAbsence'];
  final streams = body['streams'];

  // Les quatre exigences positives. `subject` vide compte comme absent : un
  // plan qu'on ne peut apparier à personne n'est pas appariable à la session.
  if (planVersion is! int) return const SyncPlanParseResult.malformed();
  if (subject is! String || subject.trim().isEmpty) {
    return const SyncPlanParseResult.malformed();
  }
  if (onAbsence is! String || onAbsence.trim().isEmpty) {
    return const SyncPlanParseResult.malformed();
  }
  if (streams is! List) return const SyncPlanParseResult.malformed();

  final flows = <SyncPlanFlow>[];
  final rejected = <String>{};

  for (final raw in streams) {
    if (raw is! Map) continue;
    final key = raw['key'];
    if (key is! String || key.trim().isEmpty) continue;

    final mode = _modeOf(raw['mode']);
    final scope = _scopeOf(raw['scope']);
    // Un flux qu'on ne sait ni reprendre ni cadrer est inexploitable. On
    // l'écarte plutôt que de le tirer au hasard — et on le nomme, sans quoi
    // l'introduction d'un mode côté serveur serait un silence complet.
    if (mode == SyncFlowMode.unknown || scope == SyncFlowScope.unknown) {
      rejected.add(key);
      continue;
    }

    flows.add(
      SyncPlanFlow(
        key: key,
        clientResource: _stringList(raw['clientResource']),
        mode: mode,
        scope: scope,
        reason: _stringList(raw['reason']),
        dependsOn: _stringList(raw['dependsOn']),
      ),
    );
  }

  return SyncPlanParseResult.parsed(
    SyncPlan(
      planVersion: planVersion,
      subject: subject,
      onAbsence: onAbsence,
      streams: List.unmodifiable(flows),
    ),
    rejected,
  );
}

/// Liste de chaînes tolérante : un élément non-chaîne est écarté, un champ
/// absent donne une liste vide.
///
/// L'absence est ici sans conséquence, contrairement à `streams` : `dependsOn`
/// vide veut dire « aucune dépendance », `reason` vide veut dire « le serveur ne
/// le dit pas encore ». Les deux sont des états légitimes du contrat.
List<String> _stringList(Object? raw) {
  if (raw is! List) return const <String>[];
  return List.unmodifiable(raw.whereType<String>());
}

SyncFlowMode _modeOf(Object? raw) => switch (raw) {
  'BUNDLE' => SyncFlowMode.bundle,
  'KEYSET' => SyncFlowMode.keyset,
  'COHORT' => SyncFlowMode.cohort,
  'FANOUT' => SyncFlowMode.fanout,
  _ => SyncFlowMode.unknown,
};

SyncFlowScope _scopeOf(Object? raw) => switch (raw) {
  'school' => SyncFlowScope.school,
  'principal' => SyncFlowScope.principal,
  _ => SyncFlowScope.unknown,
};
