import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_exchange_rates_use_case.dart';

/// La série de taux de guichet, chargée au montage de la page d'encaissement.
///
/// **Aucun état d'erreur, et c'est délibéré.** Un taux absent et un taux
/// illisible produisent la même chose à l'écran : pas de bascule de devise,
/// donc l'encaissement d'avant, qui n'a jamais cessé de fonctionner. Afficher
/// « impossible de charger les taux » au-dessus d'un formulaire d'argent
/// inquiéterait un caissier sur un chemin qui, lui, va parfaitement bien.
///
/// [loaded] existe quand même : il distingue « on ne sait pas encore » de « il
/// n'y a rien », ce qui évite de faire clignoter la bascule au premier rendu.
class ExchangeRatesState extends Equatable {
  final bool loaded;
  final List<ExchangeRate> rates;

  const ExchangeRatesState({this.loaded = false, this.rates = const []});

  @override
  List<Object?> get props => [loaded, rates];
}

class ExchangeRatesCubit extends Cubit<ExchangeRatesState> {
  final GetExchangeRatesUseCase _getExchangeRates;

  StreamSubscription<Set<String>>? _pullSub;

  /// ⚠️ **La lecture locale est one-shot ; le pull, lui, arrive après.**
  ///
  /// La page d'encaissement se monte, lit un cache encore froid, et le pull des
  /// taux part au même instant depuis le `FeatureScope`. Sans ce réveil, la
  /// série reste vide **pour toute la durée de l'écran** : le caissier voit
  /// « aucun taux paramétré » alors que le bundle vient d'arriver et que la
  /// table est pleine. Il faut sortir de la feature et y revenir pour que la
  /// bascule apparaisse — exactement l'impression tenace que « le pull ne
  /// marche pas » que ce bus existe pour dissiper.
  ///
  /// Abonnement défensif : le bus est optionnel dans la DI (tests, socle
  /// offline non enregistré), et son absence laisse l'écran fonctionnel en
  /// lecture locale.
  ExchangeRatesCubit(this._getExchangeRates, {PullCompletionBus? pullBus})
    : super(const ExchangeRatesState()) {
    final bus = pullBus;
    if (bus == null) return;
    _pullSub = bus.stream.listen(
      (resources) {
        if (isClosed ||
            !resources.contains(
              FinancePullRepositoryImpl.exchangeRatesResource,
            )) {
          return;
        }
        unawaited(load());
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  Future<void> close() async {
    await _pullSub?.cancel();
    return super.close();
  }

  /// Charge la série. **Ne lève jamais** : un écran d'argent ne tombe pas parce
  /// qu'un référentiel de confort est illisible.
  Future<void> load() async {
    final result = await _getExchangeRates();
    if (isClosed) return;
    emit(
      ExchangeRatesState(
        loaded: true,
        rates: result.fold((_) => const <ExchangeRate>[], (rates) => rates),
      ),
    );
  }
}
