import 'package:connectivity_plus/connectivity_plus.dart';

/// Détection de connectivité pour le vidage opportuniste de l'outbox
/// (ADR-005 : « dès qu'un signal réseau passe »).
///
/// ⚠️ **Portée : état RADIO uniquement, pas la joignabilité réelle.** La doc
/// officielle de `connectivity_plus` est explicite : le résultat de
/// `checkConnectivity()` « only gives you the radio status » et ne doit pas
/// servir à décider si une requête réseau aboutira. Ici on ne s'en sert que
/// comme **pré-garde bon marché** (éviter un flush inutile quand la radio est
/// clairement coupée) ; la joignabilité réelle est tranchée par l'appel HTTP
/// du handler d'outbox lui-même (qui bascule en retry/backoff si le serveur est
/// injoignable).
class ConnectivityService {
  final Connectivity _connectivity;

  const ConnectivityService(this._connectivity);

  /// Vrai s'il existe au moins une interface réseau active (radio « up »).
  ///
  /// Ponctuel : à utiliser comme pré-garde avant un flush, jamais comme preuve
  /// qu'une requête aboutira (cf. remarque de classe). Pour réagir aux
  /// changements, préférer [onStatusChange] (recommandation de la doc).
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasActiveInterface(results);
  }

  /// Flux réactif des transitions radio online/offline — **source privilégiée**
  /// par la doc `connectivity_plus` pour déclencher une action (ici : un flush
  /// de l'outbox à chaque retour de connectivité).
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasActiveInterface);

  /// Interprète le résultat de `connectivity_plus` selon ses **invariants
  /// documentés** :
  ///  - la liste n'est **jamais vide** ;
  ///  - [ConnectivityResult.none] est le **seul** marqueur d'absence de réseau
  ///    et n'est **jamais** mélangé à d'autres résultats.
  ///
  /// Donc « en ligne » ⟺ la liste ne contient pas `none`.
  bool _hasActiveInterface(List<ConnectivityResult> results) =>
      !results.contains(ConnectivityResult.none);
}
