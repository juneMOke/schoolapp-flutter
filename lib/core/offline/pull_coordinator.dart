import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/plan/pull_sequencer.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_holder.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_cycle_guard.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/pull_run_report.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';

// Ré-exporté : le rapport a été sorti d'ici pour tenir la cible de taille, et
// une quinzaine d'appelants l'importent via ce fichier.
export 'package:school_app_flutter/core/offline/pull_run_report.dart';

/// Orchestrateur du **pull delta** (SOC-1) — pendant *lecture* du `SyncEngine`
/// (qui, lui, pousse l'outbox).
///
/// Tient un registre de [PullHandler] par ressource et les exécute :
///  - **pré-garde connectivité** (radio) : hors-ligne → aucun appel ;
///  - **gate crédentiels** : sans jetons utilisables, on ne tente rien — chaque
///    appel partirait en 401 pour rien ;
///  - **filtre de permission** ([_isReadable]), dont le socle est exempté ;
///  - **abandon sur dépendance bloquée** : une ressource dont l'amont
///    money-grade vient d'échouer n'est pas tentée ;
///  - **isolation par ressource** : un handler qui échoue (ou lève) n'empêche
///    pas les autres — l'échec est comptabilisé, pas propagé.
///
/// Deux points d'entrée, et la différence entre eux est le périmètre, jamais la
/// politique : [pullAll] pour un cycle complet, [pullSubset] pour ce dont un
/// écran a besoin à son montage. Les deux partagent le **même** corps de cycle,
/// délibérément — deux copies divergeraient, et celle qui divergerait serait
/// celle que les tests ne couvrent pas.
///
/// **Passif** : il est *déclenché* (à l'ouverture de session et au retour
/// *online* par `SyncStatusCubit`, ou par un écran à son montage), il ne
/// s'abonne pas lui-même à la connectivité — symétrique du `SyncEngine`, piloté
/// par le même point de colle.
class PullCoordinator {
  final ConnectivityService _connectivity;
  final PullCompletionBus? _completionBus;
  final CurrentPermissions? _permissions;
  final SessionCredentialsProbe? _credentialsProbe;
  final SyncPlanHolder? _planHolder;
  final Map<String, PullHandler> _handlers = {};
  final PullCycleGuard _guard = PullCycleGuard();

  bool _pulling = false;

  PullCoordinator({
    required ConnectivityService connectivity,
    PullCompletionBus? completionBus,
    CurrentPermissions? permissions,
    SessionCredentialsProbe? credentialsProbe,
    SyncPlanHolder? planHolder,
  }) : _connectivity = connectivity,
       _completionBus = completionBus,
       _permissions = permissions,
       _credentialsProbe = credentialsProbe,
       _planHolder = planHolder;

  /// Enregistre le handler d'une ressource (appelé par la DI des branches).
  void registerHandler(PullHandler handler) {
    _handlers[handler.resource] = handler;
  }

  bool get isPulling => _pulling;

  /// Tire toutes les ressources enregistrées. Ne lève pas : encapsule tout dans
  /// un [PullRunReport].
  ///
  /// Le verrou `_pulling` ne garde QUE ce chemin : un second cycle complet
  /// pendant qu'un premier tourne n'apporterait rien. Il ne s'applique pas à
  /// [pullSubset], qui a sa propre sérialisation, plus fine.
  Future<PullRunReport> pullAll() async {
    if (_pulling) return const PullRunReport.skipped();
    _pulling = true;
    try {
      return await _runCycle(_handlers.values.toList(growable: false));
    } finally {
      _pulling = false;
    }
  }

  /// Tire un **sous-ensemble** de ressources — le chemin des écrans (ADR-015 F6).
  ///
  /// Existe pour que les écrans cessent de tirer en direct sur les repositories.
  /// Ces appels-là n'étaient filtrés par aucun droit, ignoraient l'ordre et ne
  /// diffusaient rien : la largeur effective du pull était l'union du
  /// coordinateur et d'une douzaine de portes dérobées. Tant qu'elles restent
  /// ouvertes, faire du plan l'autorité du seul coordinateur ne resserre rien.
  ///
  /// **L'ordre est celui du registre, jamais celui de l'ensemble reçu.** Un
  /// `Set` littéral au site d'appel n'a pas d'ordre porteur, et l'arête
  /// créances → paiements ne doit pas dépendre de la façon dont un développeur
  /// a tapé ses accolades.
  ///
  /// **Ne prend PAS le verrou de cycle complet.** Le prendre ferait qu'un écran
  /// monté pendant un `pullAll()` en vol recevrait « sauté » et resterait sur un
  /// cache froid — précisément la panne que ces pulls existent à éviter, et
  /// d'autant plus vicieuse que le cycle complet part maintenant à l'ouverture
  /// de session : la fenêtre tombe pile quand l'utilisateur ouvre son premier
  /// écran. La sérialisation se fait donc **par ressource**, via
  /// [PullCycleGuard].
  ///
  /// Une ressource demandée mais non enregistrée est ignorée en silence : c'est
  /// un écran qui demande plus que ce que son APK sait tirer, pas une panne.
  Future<PullRunReport> pullSubset(Set<String> resources) async {
    final selected = _handlers.values
        .where((h) => resources.contains(h.resource))
        .toList(growable: false);
    if (selected.isEmpty) return const PullRunReport();
    return _runCycle(selected);
  }

  /// Le corps de cycle, unique — cf. la docstring de classe.
  Future<PullRunReport> _runCycle(List<PullHandler> handlers) async {
    if (!await _connectivity.isOnline()) {
      return const PullRunReport.offline();
    }
    // Sans jetons utilisables, chaque ressource partirait en 401. Les use cases
    // d'hydratation portaient cette sonde eux-mêmes, en justifiant qu'ils
    // contournaient le coordinateur ; elle remonte ici avec eux.
    if (!await _canAuthenticate()) {
      return const PullRunReport.skipped();
    }

    // Le plan est résolu APRÈS les deux gardes : le lire avant imposerait un
    // aller-retour réseau — ou son timeout — à chaque montage d'écran hors
    // connexion, et un 401 sur `/sync/plan` se lirait comme une anomalie de
    // déploiement là où il n'y a qu'une session sans jetons.
    final planState =
        await _planHolder?.current() ??
        const SyncPlanState.unknown(SyncPlanUnknownCause.absent);

    var updated = 0, notModified = 0, failed = 0;
    var forbidden = 0, blocked = 0, outOfPlan = 0;
    int? latestServerTimeMs;
    final outcomes = <String, PullResult>{};

    // Les clés que l'ANALYSE a écartées, faute d'en connaître le `mode` ou le
    // `scope` (ADR-015 N-2). Le parser les retire de `plan.streams` et les nomme
    // à part : rien, dans le plan lui-même, ne dit plus qu'elles existaient.
    //
    // ⚠️ Le régime VIDE n'en porte plus. Un plan dont TOUS les flux ont été
    // écartés ne vaut plus « rien à tirer » mais « inconnu »
    // (`unsupportedStreams`) — sans quoi le corps partait en cache et l'arrêt
    // total survivait au redémarrage. Les deux branches sans clés restent
    // néanmoins nommées, comme au switch d'autorité : pas de `_`, pour qu'un
    // quatrième état casse la compilation au lieu d'atterrir sur un défaut.
    final planRejectedKeys = switch (planState) {
      SyncPlanKnown(:final rejectedKeys) => rejectedKeys,
      SyncPlanEmpty() => const <String>{},
      SyncPlanUnknown() => const <String>{},
    };

    /// Ressources dont l'aval bloquant ne peut PAS se fier au cache local.
    ///
    /// Un échec y entre, évidemment. Mais une ressource **sautée faute de
    /// droit** aussi, et c'est moins évident : pour l'aval, « l'amont a échoué »
    /// et « l'amont n'a pas été tenté » se valent — dans les deux cas son miroir
    /// local est périmé. Un rôle qui détiendrait `finance.payment.read` sans
    /// `finance.charge.read` verrait sinon les paiements descendre par-dessus un
    /// `amount_paid_in_cents` que plus rien ne rafraîchit : la créance
    /// s'afficherait impayée et le caissier réencaisserait.
    ///
    /// Avant que les écrans ne passent par ici, ce cas se réglait par accident :
    /// leur pull n'était filtré par rien, les créances partaient, prenaient un
    /// 403 du serveur et tombaient en échec — ce qui bloquait les paiements.
    /// Filtrer localement supprime le 403, donc supprimerait le blocage.
    ///
    /// ⚠️ **Un flux écarté à l'analyse y entre d'entrée**, avant même la boucle,
    /// et c'est le troisième chemin — le seul qu'aucun compteur n'attrapait. Le
    /// jour où le serveur pose un `mode` neuf sur `finance.student-charges`, les
    /// créances cessent de descendre : la clé quitte `plan.streams`, `_covers`
    /// la rate, le handler tombe en `outOfPlan`, et les paiements — eux toujours
    /// au plan — descendent par-dessus un `amount_paid_in_cents` que plus rien
    /// ne rafraîchit. Même issue que le rôle mal taillé ci-dessus, par une porte
    /// que le serveur ouvre tout seul. La seule différence est la durée : un
    /// droit manquant se corrige côté serveur, un `mode` inconnu attend un APK.
    ///
    /// Amorcé depuis le PLAN, jamais depuis la sélection du cycle : un
    /// `pullSubset` qui ne demande que les paiements doit renoncer lui aussi,
    /// puisque l'amont ne sera rafraîchi par aucun cycle, pas même celui d'après.
    final unusableResources = <String>{
      for (final key in planRejectedKeys) ...resourcesOf(key),
    };

    // Deux façons pour un flux d'être **au plan et jamais tiré**, et elles
    // méritent le même compteur.
    //
    // La première est connue : aucun handler enregistré ne porte cette clé.
    //
    // La seconde est plus vicieuse — l'analyse a écarté le flux parce que son
    // `mode` ou son `scope` est inconnu de cet APK. Le contrat prévoit ce cas et
    // n'exige qu'une chose : l'ignorer « sans erreur, mais jamais sans trace ».
    // Or la clé disparaît de `plan.streams`, donc `_covers` la rate, donc elle
    // tombe en `outOfPlan` — qui est délibérément exclu de `isDegraded`. Sans
    // cette union, le jour où le serveur introduit un mode, le flux concerné
    // s'arrête **totalement** sur tout le parc, avec une pastille verte et
    // aucune trace. C'est exactement ce que `rejectedKeys` avait été calculé
    // pour éviter, et il n'était lu par personne.
    final plannedNotPulledKeys = switch (planState) {
      SyncPlanKnown(:final plan) => {
        ..._plannedWithoutHandler(plan),
        ...planRejectedKeys,
      },
      // Un plan vide n'a ni handler manquant ni clé écartée à déclarer : il est
      // vide parce que le SERVEUR l'a dit, et `planEmpty` porte déjà ce fait.
      SyncPlanEmpty() => const <String>{},
      SyncPlanUnknown() => const <String>{},
    };

    for (final handler in handlers) {
      // ── L'AUTORITÉ DE PÉRIMÈTRE (ADR-015 O) ────────────────────────────────
      //
      // **Substitution, jamais union.** Le repli local s'applique PARCE QUE le
      // plan est inconnu, pas en plus de lui. « Tirer si planifié OU lisible
      // localement » donnerait l'union des deux autorités, et tout le bénéfice
      // du chantier serait perdu — c'est l'erreur qu'une V1 de ce plan
      // contenait. Deux `if` consécutifs seraient pires encore : l'INTERSECTION,
      // où un flux planifié reste écarté par la règle locale.
      //
      // Le `switch` sur la sealed rend ces deux formes inexprimables, et son
      // exhaustivité est le seul garde-fou compilé pour un quatrième état
      // futur : ne JAMAIS y ajouter de `default:`.
      //
      // Le socle échappe aux trois branches. Sans le référentiel, la porte de
      // navigation ne s'ouvre pas et la seule sortie est la déconnexion : un
      // serveur qui l'omettrait — ou qui renverrait un plan vide — briquerait
      // le parc. Laisser passer n'est pas « écarter », F-I9 est sauf.
      if (!handler.isBaseline) {
        var skip = false;
        switch (planState) {
          // Le plan gouverne SEUL. `requiredPermissions` ne disparaît pas, il
          // cesse d'être l'autorité : un flux planifié est tiré même si le
          // compte ne détient pas la permission déclarée en dur, et c'est le
          // serveur — seule frontière réelle — qui refusera s'il le faut.
          case SyncPlanKnown(:final plan):
            if (!_covers(plan, handler)) {
              outOfPlan++;
              // ⚠️ N'entre PAS ici dans `unusableResources`. Un flux hors du
              // plan est le périmètre décidé par le serveur, pas un amont en
              // panne : le compter comme inexploitable ferait écarter un flux
              // PLANIFIÉ par une règle locale, ce que F-I9 interdit
              // frontalement.
              //
              // Les clés ÉCARTÉES À L'ANALYSE passent aussi par cette branche —
              // `_covers` ne peut pas les distinguer, elles ont quitté
              // `plan.streams` — mais elles y sont déjà entrées, avant la
              // boucle, sur la seule foi du plan. La différence n'est pas de
              // degré : « le serveur ne te l'envoie pas » et « le serveur te
              // l'envoie dans une langue que tu ne parles pas » n'ont pas le
              // même aval.
              skip = true;
            }
          // Information réelle : rien à tirer. Le contrat promet pourtant qu'un
          // plan n'est jamais vide — il contient au minimum le socle — donc ce
          // cas est un serveur qui se contredit, et il est compté (voir
          // `planEmpty` dans le rapport) plutôt que subi en silence.
          case SyncPlanEmpty():
            skip = true;
          // Mode dégradé : l'ancien filtre reprend la main, à l'identique.
          case SyncPlanUnknown():
            if (!_isReadable(handler)) {
              forbidden++;
              unusableResources.add(handler.resource);
              skip = true;
            }
        }
        if (skip) continue;
      }
      if (_isBlockedBy(handler, unusableResources)) {
        blocked++;
        continue;
      }
      try {
        // Sérialisé PAR RESSOURCE : un cycle complet et le pull d'un écran qui
        // se monte peuvent se croiser, et deux cycles keyset qui écrivent le
        // même curseur en concurrence le font régresser. Trois repositories sur
        // douze ne se protègent pas eux-mêmes, dont l'Inscription.
        final outcome = await _guard.run(
          handler.resource,
          () => handler.pull(),
        );
        outcomes[handler.resource] = outcome.result;
        switch (outcome.result) {
          case PullResult.updated:
            updated++;
            // Réveil IMMÉDIAT des écrans qui lisent cette ressource : un cycle
            // complet enchaîne des ressources lentes, attendre la fin laisserait
            // un écran affiché vide alors que SES données sont déjà en base.
            // TOUTES les ressources de la clé de ce flux, pas la seule que le
            // handler déclare (cf. `pullCompletionSubjectsOf`).
            _completionBus?.notifyUpdated(
              pullCompletionSubjectsOf(handler.resource),
            );
          case PullResult.notModified:
            notModified++;
          case PullResult.error:
            failed++;
            unusableResources.add(handler.resource);
        }
        final observed = outcome.serverTimeMs;
        if (observed != null &&
            (latestServerTimeMs == null || observed > latestServerTimeMs)) {
          latestServerTimeMs = observed;
        }
      } catch (_) {
        // Un handler qui lève (malgré son contrat) est isolé en échec.
        failed++;
        unusableResources.add(handler.resource);
        outcomes[handler.resource] = PullResult.error;
      }
    }

    return PullRunReport(
      updated: updated,
      notModified: notModified,
      failed: failed,
      forbidden: forbidden,
      blocked: blocked,
      outOfPlan: outOfPlan,
      plannedNotPulled: plannedNotPulledKeys.length,
      plannedNotPulledKeys: plannedNotPulledKeys,
      planEmpty: planState is SyncPlanEmpty,
      outcomes: Map.unmodifiable(outcomes),
      latestServerTimeMs: latestServerTimeMs,
    );
  }

  /// Ce plan couvre-t-il ce handler ?
  ///
  /// Le routage passe par la **clé de plan**, jamais par `clientResource` : ce
  /// champ est analysé en mode tolérant (absent ou mal typé ⇒ liste vide), donc
  /// une omission côté serveur mettrait les dix-neuf handlers hors plan — arrêt
  /// total, plan « valide », zéro erreur.
  ///
  /// Un handler que la table d'alias ne connaît pas (`planKeyOf` rend `null`)
  /// est hors plan : aucune clé ne pourra jamais le désigner. C'est un défaut de
  /// contrat, pas un périmètre — il est compté à part, sous son nom.
  bool _covers(SyncPlan plan, PullHandler handler) {
    final key = planKeyOf(handler.resource);
    if (key == null) return false;
    return plan.keys.contains(key);
  }

  /// Les clés du plan qu'AUCUN handler enregistré ne sait tirer.
  ///
  /// Calculé contre le **registre entier**, jamais contre la sélection du
  /// cycle : un `pullSubset` demande une à cinq ressources sur dix-neuf, et le
  /// mesurer là déclarerait une quinzaine de flux manquants à chaque montage
  /// d'écran — donc une pastille dégradée en permanence sur un écran sain.
  ///
  /// Un flux au plan qu'aucun handler ne couvre est un **défaut de contrat** :
  /// une clé mal orthographiée de part et d'autre suffit, et sous ce lot ce
  /// n'est plus une dégradation, c'est l'arrêt total de ce flux. D'où les clés
  /// nommément — « un flux manque » n'a jamais permis de trouver lequel.
  Set<String> _plannedWithoutHandler(SyncPlan plan) {
    final covered = <String>{
      for (final resource in _handlers.keys)
        if (planKeyOf(resource) != null) planKeyOf(resource)!,
    };
    return plan.keys.where((k) => !covered.contains(k)).toSet();
  }

  /// Vrai si une dépendance **bloquante** de ce handler est inexploitable dans
  /// ce cycle — qu'elle ait échoué ou qu'elle n'ait pas été tentée.
  ///
  /// Une seule arête est de cette nature — les paiements après les créances —
  /// et son asymétrie est tout l'argument : poursuivre après un échec des
  /// créances fait réencaisser, alors que renoncer ne coûte qu'un grand-livre en
  /// retard. Les trois autres arêtes n'ont pas ce sens de panne et laissent
  /// donc leur aval s'exécuter (cf. [MoneyGradeEdge.blocking]).
  bool _isBlockedBy(PullHandler handler, Set<String> unusable) {
    if (unusable.isEmpty) return false;
    final key = planKeyOf(handler.resource);
    if (key == null) return false;
    for (final edge in kMoneyGradeEdges) {
      if (!edge.blocking || edge.after != key) continue;
      final upstream = resourcesOf(edge.before);
      if (upstream.any(unusable.contains)) return true;
    }
    return false;
  }

  /// Sans sonde branchée (tests, plateformes partielles) : pas de gate.
  ///
  /// Fail-open comme partout ailleurs dans cette couche : une sonde défaillante
  /// ne doit jamais devenir elle-même la cause d'une synchronisation qui ne part
  /// plus.
  Future<bool> _canAuthenticate() async {
    final probe = _credentialsProbe;
    if (probe == null) return true;
    try {
      return await probe.canAuthenticate();
    } catch (_) {
      return true;
    }
  }

  /// Sérialise un cycle sur cette ressource — réservé aux appelants qui tirent
  /// hors coordinateur en attendant leur repli (ADR-015 F6).
  Future<void> guarded(String resource, Future<void> Function() cycle) =>
      _guard.run(resource, cycle);

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
