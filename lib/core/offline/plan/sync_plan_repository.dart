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
}
