import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';

/// Pourquoi le plan est inconnu — la **trace** qu'exige le contrat.
///
/// « Le client ignore ce qu'il ne connaît pas, mais jamais sans trace. » Ce
/// dépôt n'a aucun canal de log (`avoid_print` est actif) : le diagnostic est
/// donc porté par l'objet valeur, comme `PullOutcome.error` et
/// `OutboxEntry.lastError`. Sans cette cause typée, un repli permanent — un
/// serveur non redéployé, un `subject` discordant — serait indistinguable d'un
/// cycle sain.
enum SyncPlanUnknownCause {
  /// La route n'existe pas encore sur ce serveur. **Cas nominal du dégradé**,
  /// pas une panne : l'APK se met à jour indépendamment du back.
  notDeployed,

  /// Réseau, timeout, portail captif qui coupe. Transitoire par nature.
  transport,

  /// Session illisible côté serveur. Le contrat promet « jamais 403 » : recevoir
  /// un refus ici est une anomalie de déploiement, pas un manque de droit.
  unauthorized,

  /// Corps non-JSON, non-objet, `planVersion` absent, `streams` **absent ou
  /// d'un autre type**. C'est ce qui attrape le portail captif qui répond 200
  /// en HTML.
  ///
  /// ⚠️ Un `streams` **vide**, lui, n'est pas malformé : c'est [SyncPlanEmpty].
  /// Les confondre ferait tout tirer là où le serveur dit qu'il n'y a rien.
  malformed,

  /// Le plan en cache a été calculé pour un **autre compte**. Jamais « vide » :
  /// sur une tablette partagée, le plan de A relu pour B déterminerait ce que B
  /// tire.
  foreignSubject,

  /// Rien en cache et rien sur le réseau — premier démarrage hors ligne.
  absent,
}

/// L'état du plan — **trois** états, jamais deux (ADR-015 O).
///
/// La distinction porte tout le lot. « Vide » est une information réelle : le
/// serveur a répondu, et il n'y a rien à tirer. « Inconnu » est une absence
/// d'information : on ne sait pas, donc on retombe sur le registre en dur,
/// filtré par `requiredPermissions`.
///
/// ⚠️ **Substitution, jamais union.** Le repli s'applique *parce que* le plan
/// est inconnu, pas en plus de lui. Une règle de la forme « tirer si planifié
/// **ou** lisible localement » donnerait l'union des deux autorités — ce que
/// D-03 interdit explicitement, et tout le bénéfice serait perdu.
///
/// Le dépôt a trois précédents de ce motif : `permissions == null` ≠ `[]`,
/// « section absente » ≠ « section vide » dans le bundle Inscription, et
/// `PermissionHolding`. Même patron.
sealed class SyncPlanState {
  const SyncPlanState();

  /// Le plan gouverne seul (à partir du lot F5).
  const factory SyncPlanState.known(SyncPlan plan, {Set<String> rejectedKeys}) =
      SyncPlanKnown;

  /// Information réelle : rien à tirer, et **jamais** de purge.
  const factory SyncPlanState.empty(SyncPlan plan, {Set<String> rejectedKeys}) =
      SyncPlanEmpty;

  /// Repli sur le registre en dur, **zéro purge**.
  const factory SyncPlanState.unknown(SyncPlanUnknownCause cause) =
      SyncPlanUnknown;
}

/// 200, JSON, `planVersion` présent, `streams` non vide, `subject` == porteur.
class SyncPlanKnown extends SyncPlanState {
  final SyncPlan plan;

  /// Les clés de flux écartées à l'analyse, parce que leur `mode` ou leur
  /// `scope` est inconnu de ce client (ADR-015 N-2).
  ///
  /// C'est la **trace** que le contrat exige : « le client ignore ce qu'il ne
  /// connaît pas, mais jamais sans trace ». Le plan reste valide — un flux
  /// introduit côté serveur avant que le client sache le traiter ne doit pas
  /// invalider les dix-sept autres — mais l'écart doit rester nommé. Le jeter
  /// ici rendrait l'introduction d'un mode serveur totalement silencieuse, ce
  /// qui est exactement la panne que le compteur `plannedNotPulledKeys` du
  /// coordinateur existe déjà à rendre visible.
  final Set<String> rejectedKeys;

  const SyncPlanKnown(this.plan, {this.rejectedKeys = const <String>{}});
}

/// Positivement identifié comme plan, mais sans aucun flux.
///
/// Le contrat dit que le plan n'est **jamais** vide — il contient au minimum le
/// socle. Cet état existe donc pour un serveur qui contredirait son propre
/// contrat, et il est traité comme une information plutôt que comme une erreur :
/// rien à tirer, rien à purger. Il ne doit surtout pas se confondre avec
/// [SyncPlanUnknown], qui ferait au contraire tout tirer.
class SyncPlanEmpty extends SyncPlanState {
  final SyncPlan plan;

  /// Cf. [SyncPlanKnown.rejectedKeys]. Un plan dont TOUS les flux ont été
  /// écartés arrive ici : « vide » et « entièrement inexploitable » se
  /// ressemblent à l'œil, et seule cette liste les distingue.
  final Set<String> rejectedKeys;

  const SyncPlanEmpty(this.plan, {this.rejectedKeys = const <String>{}});
}

/// Tout le reste, avec sa cause.
class SyncPlanUnknown extends SyncPlanState {
  final SyncPlanUnknownCause cause;
  const SyncPlanUnknown(this.cause);
}
