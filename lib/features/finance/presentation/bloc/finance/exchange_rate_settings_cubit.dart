import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_exchange_rates_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/save_exchange_rate_use_case.dart';

enum ExchangeRateSettingsStatus { idle, saving, saved, failed }

/// Le paramétrage des taux de guichet, côté direction.
class ExchangeRateSettingsState extends Equatable {
  final bool loaded;

  /// La série telle qu'elle est en base, tous paliers confondus.
  final List<ExchangeRate> rates;

  final ExchangeRateSettingsStatus status;
  final String? errorMessage;

  const ExchangeRateSettingsState({
    this.loaded = false,
    this.rates = const [],
    this.status = ExchangeRateSettingsStatus.idle,
    this.errorMessage,
  });

  /// Le taux en vigueur pour cette paire, `null` s'il n'y en a aucun.
  ExchangeRate? currentFor({required String base, required String quote}) =>
      ExchangeRates.at(rates, base: base, quote: quote, moment: DateTime.now());

  ExchangeRateSettingsState copyWith({
    bool? loaded,
    List<ExchangeRate>? rates,
    ExchangeRateSettingsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) => ExchangeRateSettingsState(
    loaded: loaded ?? this.loaded,
    rates: rates ?? this.rates,
    status: status ?? this.status,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [loaded, rates, status, errorMessage];
}

/// Poser le taux du jour, et relire la série.
///
/// **Un palier par enregistrement, jamais une valeur remplacée en place.**
/// L'école qui change de taux à midi en pose un second : le versement du matin
/// garde le sien. C'est ce qui permet de relire un encaissement six mois plus
/// tard avec le taux qui valait alors, et c'est pour ça que `effective_from`
/// est dans la clé.
class ExchangeRateSettingsCubit extends Cubit<ExchangeRateSettingsState> {
  final GetExchangeRatesUseCase _getRates;
  final SaveExchangeRateUseCase _saveRate;
  final DateTime Function() _now;

  ExchangeRateSettingsCubit({
    required GetExchangeRatesUseCase getRates,
    required SaveExchangeRateUseCase saveRate,
    DateTime Function()? now,
  }) : _getRates = getRates,
       _saveRate = saveRate,
       _now = now ?? DateTime.now,
       super(const ExchangeRateSettingsState());

  Future<void> load() async {
    final result = await _getRates();
    if (isClosed) return;
    emit(
      state.copyWith(
        loaded: true,
        rates: result.fold((_) => const <ExchangeRate>[], (rates) => rates),
      ),
    );
  }

  /// Pose un taux prenant effet **maintenant**.
  ///
  /// L'instant d'effet n'est pas saisissable en V1, et c'est délibéré : un taux
  /// antidaté réécrirait la lecture de versements déjà encaissés et déjà
  /// imprimés. Poser un palier vers le passé est une opération de correction
  /// comptable, pas un geste de paramétrage.
  Future<void> save({
    required String base,
    required String quote,
    required int rateMicros,
    int? divergenceBandBp,
  }) async {
    emit(
      state.copyWith(
        status: ExchangeRateSettingsStatus.saving,
        clearError: true,
      ),
    );
    final result = await _saveRate(
      base: base,
      quote: quote,
      rateMicros: rateMicros,
      effectiveFrom: _now(),
      divergenceBandBp: divergenceBandBp,
    );
    if (isClosed) return;
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: ExchangeRateSettingsStatus.failed,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        await load();
        if (isClosed) return;
        emit(state.copyWith(status: ExchangeRateSettingsStatus.saved));
      },
    );
  }
}
