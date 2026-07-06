import 'package:connectivity_plus/connectivity_plus.dart';

/// Détection de connectivité pour le vidage opportuniste de l'outbox
/// (ADR-005 : « dès qu'un signal réseau passe »). Ne teste que la présence
/// d'une interface réseau — la joignabilité réelle est validée par l'appel HTTP
/// du handler lui-même (qui bascule en retry si le serveur est injoignable).
class ConnectivityService {
  final Connectivity _connectivity;

  const ConnectivityService(this._connectivity);

  /// Vrai s'il existe au moins une interface réseau active.
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  /// Flux de transitions online/offline (déclenche un flush à chaque passage
  /// à online).
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}
