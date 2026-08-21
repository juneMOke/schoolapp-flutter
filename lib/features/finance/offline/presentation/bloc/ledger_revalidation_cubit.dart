import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/watch_ledger_revalidation_use_case.dart';

/// Compteur d'aboutissements du rafraîchissement ciblé POUR UN ÉLÈVE : chaque
/// cycle abouti incrémente l'état, ce qui donne aux widgets un signal
/// `BlocListener` là où le refresher n'expose qu'un `Stream`.
///
/// Un compteur plutôt qu'un booléen ou un horodatage : deux cycles successifs
/// doivent produire deux notifications, et un état égal au précédent n'émet pas
/// (`Cubit`), donc ne réveillerait personne la seconde fois.
class LedgerRevalidationCubit extends Cubit<int> {
  final WatchLedgerRevalidationUseCase _watch;
  StreamSubscription<String>? _subscription;

  LedgerRevalidationCubit(this._watch) : super(0);

  /// Branche le cubit sur l'élève affiché. Rappelable : une fiche qui change
  /// d'élève sans être démontée (le détail se réutilise) ne doit pas continuer
  /// à écouter le précédent.
  void watch(String studentId) {
    _subscription?.cancel();
    _subscription = _watch().where((id) => id == studentId).listen(
      (_) {
        if (!isClosed) emit(state + 1);
      },
      // Le canal est un `broadcast` d'application : une erreur y serait
      // anormale, mais elle ne doit pas remonter à la zone et tuer l'écran.
      onError: (_) {},
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
