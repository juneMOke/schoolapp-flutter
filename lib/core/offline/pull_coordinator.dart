import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
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
    this.latestServerTimeMs,
  });

  const PullRunReport.skipped() : this(skipped: true);
  const PullRunReport.offline() : this(offline: true);

  /// Ressources réellement tirées. Les trois compteurs de ressources **sautées**
  /// en sont exclus : une ressource sautée n'a produit ni donnée ni échec.
  int get processed => updated + notModified + failed;

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
      (failed > 0 || forbidden > 0 || plannedNotPulled > 0);
}

/// Orchestrateur du **pull delta** (SOC-1) — pendant *lecture* du `SyncEngine`
/// (qui, lui, pousse l'outbox).
///
/// Tient un registre de [PullHandler] par ressource et les exécute :
///  - **pré-garde connectivité** (radio) : hors-ligne → aucun appel ;
///  - **verrou anti-concurrence** (`_pulling`) : un seul cycle *de coordinateur*
///    à la fois. Il ne sérialise **pas** les pulls déclenchés directement sur un
///    repository hors coordinateur (ex. re-pull de réassignation) — sans danger
///    car les upserts sont idempotents (au pire un re-pull redondant) ;
///  - **isolation par ressource** : un handler qui échoue (ou lève) n'empêche
///    pas les autres — l'échec est comptabilisé, pas propagé.
///
/// **Passif** : il est *déclenché* (au retour *online* par `SyncStatusCubit`, ou
/// à la demande), il ne s'abonne pas lui-même à la connectivité — symétrique du
/// `SyncEngine`, piloté par le même point de colle.
class PullCoordinator {
  final ConnectivityService _connectivity;
  final PullCompletionBus? _completionBus;
  final CurrentPermissions? _permissions;
  final Map<String, PullHandler> _handlers = {};

  bool _pulling = false;

  PullCoordinator({
    required ConnectivityService connectivity,
    PullCompletionBus? completionBus,
    CurrentPermissions? permissions,
  }) : _connectivity = connectivity,
       _completionBus = completionBus,
       _permissions = permissions;

  /// Enregistre le handler d'une ressource (appelé par la DI des branches).
  void registerHandler(PullHandler handler) {
    _handlers[handler.resource] = handler;
  }

  bool get isPulling => _pulling;

  /// Tire toutes les ressources enregistrées. Ne lève pas : encapsule tout dans
  /// un [PullRunReport].
  Future<PullRunReport> pullAll() async {
    if (_pulling) return const PullRunReport.skipped();
    _pulling = true;
    try {
      if (!await _connectivity.isOnline()) {
        return const PullRunReport.offline();
      }

      var updated = 0, notModified = 0, failed = 0, forbidden = 0;
      int? latestServerTimeMs;
      for (final handler in _handlers.values) {
        if (!_isReadable(handler)) {
          forbidden++;
          continue;
        }
        try {
          final outcome = await handler.pull();
          switch (outcome.result) {
            case PullResult.updated:
              updated++;
              // Réveil IMMÉDIAT des écrans qui lisent cette ressource : un
              // cycle complet enchaîne des ressources lentes, attendre la fin
              // laisserait un écran affiché vide alors que SES données sont
              // déjà en base (cf. `PullCompletionBus`).
              // TOUTES les ressources de la clé de ce flux, pas la seule que le
              // handler déclare : deux flux du contrat partagent une clé et
              // écrivent les mêmes tables (cf. `pullCompletionSubjectsOf`).
              _completionBus?.notifyUpdated(
                pullCompletionSubjectsOf(handler.resource),
              );
            case PullResult.notModified:
              notModified++;
            case PullResult.error:
              failed++;
          }
          final observed = outcome.serverTimeMs;
          if (observed != null &&
              (latestServerTimeMs == null || observed > latestServerTimeMs)) {
            latestServerTimeMs = observed;
          }
        } catch (_) {
          // Un handler qui lève (malgré son contrat) est isolé en échec.
          failed++;
        }
      }

      return PullRunReport(
        updated: updated,
        notModified: notModified,
        failed: failed,
        forbidden: forbidden,
        latestServerTimeMs: latestServerTimeMs,
      );
    } finally {
      _pulling = false;
    }
  }

  /// Vrai si la session courante peut lire cette ressource (ADR-014).
  ///
  /// **Ensemble inconnu → on tire quand même.** Le holder rend `null` tant que
  /// la couche auth n'a pas alimenté la session (amorçage, ou tests montant le
  /// coordinateur seul) : filtrer là-dessus couperait toute la synchronisation
  /// sur un simple trou d'alimentation, alors que ne pas filtrer ne coûte, au
  /// pire, qu'un appel refusé par le serveur — qui reste la seule vraie
  /// frontière. L'ensemble **vide**, lui, est une information : aucun droit,
  /// donc aucune ressource tirée.
  bool _isReadable(PullHandler handler) {
    // Le socle échappe au filtre (ADR-015 M) : sans le référentiel, la porte de
    // navigation ne s'ouvre pas et la seule sortie est la déconnexion. Le
    // sauter faute de droit gèlerait l'année en silence — la panne exacte que
    // ce drapeau existe à écarter.
    if (handler.isBaseline) return true;
    final held = _permissions?.permissions;
    if (held == null) return true;
    return canAccess(
      requires: handler.requiredPermissions,
      permissions: held,
      // Conjonction : un point d'entrée qui franchit deux frontières
      // d'autorité les exige toutes les deux.
      requiresAll: true,
    );
  }
}
