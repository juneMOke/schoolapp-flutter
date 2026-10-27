import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';

/// En ligne ou non, pour un écran qui doit le dire en direct : un geste qui
/// n'existe qu'en ligne se désactive avec son message, au lieu d'échouer au
/// toucher. Une radio « up » n'est pas une preuve qu'une requête aboutira :
/// l'appel garde son traitement d'échec.
class NetworkStatusCubit extends Cubit<bool> {
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _changes;

  NetworkStatusCubit(this._connectivity) : super(true);

  Future<void> start() async {
    _changes ??= _connectivity.onStatusChange.listen((online) {
      if (!isClosed) emit(online);
    });
    final online = await _connectivity.isOnline();
    if (!isClosed) emit(online);
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
