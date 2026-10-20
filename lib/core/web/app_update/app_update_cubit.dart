import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/web/app_update/deployed_build_source.dart';

/// Une nouvelle version a-t-elle été déployée depuis l'ouverture de l'onglet ?
///
/// La première lecture fixe la version chargée ; les suivantes, à chaque top
/// de [ticks], la comparent. Un onglet de caisse ouvert des jours restait
/// sinon sur l'ancienne application — `no-cache` ne joue qu'au rechargement.
///
/// L'état est `true` dès qu'une version différente est vue ; il ne revient
/// pas en arrière (seul un rechargement charge la nouvelle).
class AppUpdateCubit extends Cubit<bool> {
  final DeployedBuildSource _source;
  final Stream<void> _ticks;
  String? _loaded;
  StreamSubscription<void>? _subscription;

  AppUpdateCubit({
    required DeployedBuildSource source,
    required Stream<void> ticks,
  }) : _source = source,
       _ticks = ticks,
       super(false);

  /// Fixe la version chargée et commence à surveiller.
  Future<void> start() async {
    _loaded = await _source.read();
    if (isClosed) return;
    _subscription = _ticks.listen((_) => unawaited(check()));
  }

  /// Relit la version déployée.
  Future<void> check() async {
    if (state || isClosed) return;
    final deployed = await _source.read();
    if (isClosed || deployed == null) return;
    // Première lecture manquée (hors ligne à l'ouverture) : celle-ci devient
    // la version chargée — on ne sait pas mieux.
    final loaded = _loaded ??= deployed;
    if (deployed == loaded) return;
    unawaited(_subscription?.cancel());
    emit(true);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
