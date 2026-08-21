import 'package:equatable/equatable.dart';

/// Comment un flux reprend là où il s'est arrêté (ADR-015 D).
///
/// [unknown] est **délibéré et obligatoire** : le contrat pose que le client
/// ignore ce qu'il ne connaît pas. Un mode ajouté côté serveur ne doit pas
/// rendre tout le plan illisible — il rend seulement ce flux-là inexploitable,
/// et cela se compte.
enum SyncFlowMode { bundle, keyset, cohort, fanout, unknown }

/// Ce qui cadre un flux : l'école, ou le lien du porteur de session.
///
/// `principal` marque les cinq flux cadrés par un lien plutôt que par une
/// permission — un directeur, rattaché à aucun cours, les reçoit vides. C'est
/// une vérité du catalogue, pas un défaut.
enum SyncFlowScope { school, principal, unknown }

/// Un flux du plan, tel que le serveur le décrit.
class SyncPlanFlow extends Equatable {
  /// Identifiant stable du flux côté serveur. **Jamais** la clé locale : celle-ci
  /// est à la fois la PK de `sync_meta`, le sujet du bus de complétion et la clé
  /// de déduplication du registre. Les aligner rebootstraperait le parc.
  final String key;

  /// Les ressources client, **en liste** — une clé peut en porter plusieurs, et
  /// l'ordre est porteur (cf. `kSyncPlanAliases`).
  final List<String> clientResource;

  final SyncFlowMode mode;
  final SyncFlowScope scope;

  /// Pourquoi ce flux descend — ce qui rend le plan auditable. En V1 exactement
  /// une valeur, `socle` ou `granted:<permission>`.
  ///
  /// ⚠️ **Ne jamais afficher ni journaliser** : `granted:<perm>` est l'ensemble
  /// des droits du compte. Le faire remonter dans un rapport lu par l'UI
  /// transformerait la pastille de synchro en révélateur de permissions.
  final List<String> reason;

  /// Les flux à tirer avant celui-ci, **élagués aux clés présentes dans ce
  /// plan** par le serveur : le graphe est donc toujours clos, et un comptable
  /// ne lit jamais une arête vers un flux qu'il ne reçoit pas.
  final List<String> dependsOn;

  const SyncPlanFlow({
    required this.key,
    required this.clientResource,
    required this.mode,
    required this.scope,
    required this.reason,
    required this.dependsOn,
  });

  @override
  List<Object?> get props => [
    key,
    clientResource,
    mode,
    scope,
    reason,
    dependsOn,
  ];
}

/// Le plan de synchronisation d'un compte (ADR-015 D-03).
///
/// Ne porte **aucun** chemin HTTP (le client route par ressource, pas par URL),
/// aucune cible locale, aucun déclencheur et **aucun curseur** : le serveur est
/// sans état, et l'unité de compte d'un curseur est la ressource, jamais la clé.
class SyncPlan extends Equatable {
  /// Incrémenté quand la **sémantique** d'un champ existant change — jamais pour
  /// un ajout. Sa seule absence suffit à rendre un plan inconnu : c'est le
  /// marqueur qui distingue une réponse de ce contrat d'un corps quelconque.
  final int planVersion;

  /// L'UUID **serveur** du compte pour qui ce plan a été calculé — jamais
  /// l'e-mail, qui rendrait tout plan en cache non appariable, donc rejeté en
  /// permanence.
  final String subject;

  /// Ce que le client fait d'un flux absent d'un plan valide. `ignore` en V1 ;
  /// la seule autre valeur future est `purge`. Une sémantique destructrice est
  /// portée par une valeur explicite, jamais par une absence.
  final String onAbsence;

  /// **Déjà triés topologiquement** par le serveur : un client naïf itère le
  /// tableau dans l'ordre et a raison. `dependsOn` est publié pour qui veut
  /// paralléliser — et, côté front, pour refuser un ordre qui casserait.
  final List<SyncPlanFlow> streams;

  const SyncPlan({
    required this.planVersion,
    required this.subject,
    required this.onAbsence,
    required this.streams,
  });

  /// Les clés de flux de ce plan, dans l'ordre reçu.
  List<String> get keys => streams.map((f) => f.key).toList(growable: false);

  @override
  List<Object?> get props => [planVersion, subject, onAbsence, streams];
}
