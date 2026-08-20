import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';

/// Lit le plan de synchronisation du porteur de session (ADR-015 F2).
///
/// **Interface dans le socle, implémentation dans `features/sync`** — même
/// patron que `SessionReauthenticator` et `SessionCredentialsProbe` : le socle
/// `core/offline` reste découplé du réseau et de l'auth. Aucun client Retrofit
/// ne vit sous `lib/core`, et ce lot n'inaugure pas l'exception.
///
/// **Ne lève jamais**, comme `PullHandler.pull()` : tout échec — réseau, corps
/// illisible, route absente — est encodé dans un [SyncPlanState] et vaut
/// « inconnu », c'est-à-dire le repli sur le registre en dur. Une lecture qui
/// remonterait une exception couperait la synchronisation sans recours.
abstract interface class SyncPlanRepository {
  /// Le plan courant, réseau d'abord, cache ensuite.
  ///
  /// L'ordre compte : le plan n'a **délibérément pas d'ETag** (un bump de
  /// `userVersion` efface la session au lieu de déclencher une relecture), donc
  /// rien côté serveur ni côté schéma ne périmera jamais un plan en cache. La
  /// fraîcheur est entièrement portée par le client, et le réseau est la seule
  /// source qui la donne.
  Future<SyncPlanState> load();

  /// Le plan en cache seul, sans toucher au réseau.
  ///
  /// Séparé de [load] parce que les deux ont des appelants différents : le
  /// cycle de synchro veut la fraîcheur, un démarrage hors ligne veut ce qu'il
  /// a. Confondre les deux imposerait un timeout réseau à chaque lecture.
  Future<SyncPlanState> loadCached();

  /// Un plan **réellement obtenu du réseau**, ou `null` si la jambe réseau n'a
  /// pas abouti.
  ///
  /// Existe parce que [load] ne permet pas de distinguer une lecture fraîche
  /// d'un repli sur le cache : sur timeout il sert le plan en cache et rend un
  /// `SyncPlanKnown`, verdict identique à une lecture réussie. Un appelant qui
  /// doit savoir si sa relecture a abouti — pour retenter au cycle suivant
  /// plutôt que de croire son plan à jour — n'a rien à quoi s'accrocher.
  ///
  /// C'est le manque qui rendait le « marqué à relire » du lot F9 inexprimable :
  /// implémenté sur `state is SyncPlanUnknown`, le drapeau se serait éteint sur
  /// un échec, soit exactement l'inverse du comportement voulu.
  ///
  /// `null` = **la relecture n'a pas abouti, retente au cycle suivant.** Deux
  /// causes seulement le produisent : l'incident de transport et le corps
  /// illisible (le portail captif qui répond 200 en HTML) — tous deux
  /// transitoires, tous deux démentis par le cycle d'après.
  ///
  /// Tout le reste remonte en ÉTAT : route absente (404, le cas nominal du
  /// dégradé — l'APK se met à jour indépendamment du back), refus, plan d'un
  /// autre sujet, uid pas encore posé, et **plan dont aucun flux n'est
  /// exploitable par cet APK**.
  ///
  /// La ligne de partage n'est donc PAS « a-t-on reçu un corps », mais « la
  /// jambe réseau a-t-elle abouti ». Un corps illisible est bien reçu, et
  /// pourtant il n'apprend rien : c'est le portail captif, qui change dès qu'il
  /// est franchi.
  ///
  /// ⚠️ **Un état rendu ici n'est pas pour autant un verdict.** Recevoir une
  /// réponse et pouvoir cesser de relire sont deux questions distinctes : un
  /// refus ou un uid manquant sont des réponses, et se démentent au cycle
  /// suivant. Les confondre figeait le mémo du porteur pour toute la session sur
  /// un seul 403. La seconde question a sa propre réponse, une seule pour tout
  /// le dépôt : [SyncPlanUnknownCause.isVerdict].
  Future<SyncPlanState?> refreshFromNetwork();
}
