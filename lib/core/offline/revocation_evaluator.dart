/// Contrat minimal consommé par la boucle de synchro (`SyncStatusCubit`) pour
/// décider d'une révocation de session **après** le flush de l'outbox
/// (ADR-010 D-11 : ordre `flush → evaluate → pull`).
///
/// Implémenté par `AuthSessionManager`. Découple le socle offline (core) de la
/// feature auth : le cubit ne connaît que ce contrat.
abstract class RevocationEvaluator {
  /// Évalue la divergence `userVersion` observée vs locale. Retourne `true` si
  /// la session a été révoquée (et donc wipée — jamais l'outbox). Ne lève pas.
  Future<bool> evaluateRevocation();
}
