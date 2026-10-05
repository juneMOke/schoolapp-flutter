import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';

/// En ligne ou non, pour la séance : une photo prise hors connexion se dit
/// « en file », et le bandeau rassure sur son envoi au retour du réseau.
class PhotoNetworkCubit extends Cubit<bool> {
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _changes;

  PhotoNetworkCubit(this._connectivity) : super(true);

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
