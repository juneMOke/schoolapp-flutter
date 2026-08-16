import 'package:school_app_flutter/core/offline/pull_handler.dart';

/// Bilan d'un cycle de pull (diagnostic / UI).
class PullRunReport {
  final bool skipped;
  final bool offline;
  final int updated;
  final int notModified;
  final int failed;

  /// Ressources sautées faute de permission de lecture (ADR-014). Comptées à
  /// part des échecs : ce n'est ni une panne ni un incident, c'est le
  /// fonctionnement normal d'un compte au périmètre plus étroit. Les confondre
  /// afficherait une synchronisation « en erreur » à un enseignant dont tout
  /// va bien.
  ///
  /// **Mode dégradé seulement** (ADR-015 F1/O). Quand un plan de synchro
  /// valide gouverne le pull, c'est [outOfPlan] qui porte le périmètre du
  /// profil et ce compteur retombe à zéro : `requiredPermissions` cesse d'être
  /// l'autorité pour redevenir le filtre du seul repli local.
  final int forbidden;

  /// Ressources écartées parce qu'elles ne figurent pas au plan du profil
  /// (ADR-015 F5). **Ce n'est pas une dégradation** : c'est le périmètre
  /// correct, décidé par le serveur qui, lui, connaît le profil. À ne jamais
  /// agréger avec [forbidden] — l'un dit « ce compte n'y a pas droit », l'autre
  /// « ce compte n'en a pas l'usage », et seul le premier mérite d'être signalé.
  ///
  /// Reste à zéro tant que le plan n'existe pas (lots F2/F5).
  final int outOfPlan;

  /// Flux inscrits au plan pour lesquels **aucun handler n'est enregistré**
  /// (ADR-015 F1/F3). Défaut de contrat, pas de droits : le serveur annonce un
  /// flux que ce client ne sait pas tirer — une clé mal orthographiée de part
  /// et d'autre suffit, et sous F5 ce n'est plus une dégradation mais l'arrêt
  /// total de ce flux.
  ///
  /// Reste à zéro tant que le plan n'existe pas (lots F2/F5).
  final int plannedNotPulled;

  /// Les clés fautives de [plannedNotPulled], **nommément**.
  ///
  /// Le compteur seul ne serait pas diagnosticable : « un flux manque » n'a
  /// jamais permis de trouver lequel. Portées dans le rapport plutôt que
  /// journalisées — le dépôt n'a pas de canal de log (`avoid_print` est actif)
  /// et sa convention est de faire porter le diagnostic par l'objet valeur,
  /// comme `PullOutcome.error` ou `OutboxEntry.lastError`. Ce sont des clés de
  /// ressource, jamais une donnée métier : rien d'un élève ni d'un montant.
  final Set<String> plannedNotPulledKeys;

  /// Ressources **délibérément non tentées** parce qu'une dépendance bloquante a
  /// échoué dans ce cycle (ADR-015 F6).
  ///
  /// Une seule arête est de cette nature aujourd'hui : les paiements après les
  /// créances. Le sens de panne n'est pas symétrique — créances OK / paiements
  /// KO fait refuser un encaissement (friction, argent sauf, se résorbe seul),
  /// tandis que paiements OK / créances KO fait **réencaisser**. On préfère donc
  /// ne pas tirer les paiements du tout.
  ///
  /// Compté à part de [failed] : rien n'a échoué ici, on s'est abstenu. Mais
  /// compté dans [isDegraded], parce que le cycle n'a effectivement pas couvert
  /// ce qu'il devait.
  final int blocked;

  /// L'issue de chaque ressource réellement tentée.
  ///
  /// Les agrégats ne suffisent pas à tous les appelants : un écran qui a demandé
  /// un sous-ensemble veut savoir si **sa** ressource est passée, pas si le
  /// cycle global s'est bien terminé. Une ressource sautée (droit, plan,
  /// dépendance bloquée) n'y figure pas — elle n'a pas d'issue.
  final Map<String, PullResult> outcomes;

  /// Horloge **serveur** (epoch ms) la plus récente observée ce cycle, tous
  /// handlers confondus (max des [PullOutcome.serverTimeMs] non-null) — sert
  /// de date de "dernière synchro" (badge). `null` si aucun handler n'a
  /// ramené de donnée avec `serverTime` (rien de neuf partout, ou ressources
  /// dont le contrat n'expose pas encore ce champ).
  final int? latestServerTimeMs;

  const PullRunReport({
    this.skipped = false,
    this.offline = false,
    this.updated = 0,
    this.notModified = 0,
    this.failed = 0,
    this.forbidden = 0,
    this.outOfPlan = 0,
    this.plannedNotPulled = 0,
    this.plannedNotPulledKeys = const <String>{},
    this.blocked = 0,
    this.outcomes = const <String, PullResult>{},
    this.latestServerTimeMs,
  });

  const PullRunReport.skipped() : this(skipped: true);
  const PullRunReport.offline() : this(offline: true);

  /// Ressources réellement tirées. Les compteurs de ressources **sautées** en
  /// sont exclus : une ressource sautée n'a produit ni donnée ni échec.
  int get processed => updated + notModified + failed;

  /// Vrai si cette ressource a été tirée sans échec dans ce cycle.
  ///
  /// `false` couvre trois cas que l'appelant n'a pas à distinguer : elle a
  /// échoué, elle a été sautée, ou elle n'a jamais été demandée. Aucun de ces
  /// trois n'autorise à annoncer un cache à jour.
  bool succeeded(String resource) =>
      outcomes[resource] == PullResult.updated ||
      outcomes[resource] == PullResult.notModified;

  /// Vrai quand ce cycle **n'a pas couvert tout ce qu'il aurait dû** — la seule
  /// question à laquelle la pastille de synchro doit répondre (ADR-015 F1).
  ///
  /// [outOfPlan] en est délibérément absent : un flux hors du plan d'un profil
  /// est le périmètre correct de ce profil, pas un manque. L'y compter
  /// afficherait une dégradation permanente à tout compte au périmètre étroit —
  /// exactement le contresens que la docstring de [forbidden] écarte.
  ///
  /// Un rapport [skipped] ou [offline] n'a rien observé : il ne dit ni dégradé
  /// ni sain, et l'appelant ne doit rien en conclure.
  bool get isDegraded =>
      !skipped &&
      !offline &&
      (failed > 0 || forbidden > 0 || plannedNotPulled > 0 || blocked > 0);
}
