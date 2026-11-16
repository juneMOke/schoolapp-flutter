import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_dashboard_repository.dart';

enum TreasuryEvolutionStatus { loading, ready, failure }

class TreasuryEvolutionState extends Equatable {
  final TreasuryEvolutionStatus status;

  /// Ce mois par défaut (A3).
  final EvolutionPeriod period;

  /// La plage libre de « Période » : 30 derniers jours par défaut.
  final DateTime customFrom;
  final DateTime customTo;

  /// Fin avant le début : aucun appel, un message à la place des courbes.
  final bool rangeError;
  final TreasuryEvolution? evolution;
  final Failure? failure;

  const TreasuryEvolutionState({
    required this.customFrom,
    required this.customTo,
    this.period = EvolutionPeriod.month,
    this.status = TreasuryEvolutionStatus.loading,
    this.rangeError = false,
    this.evolution,
    this.failure,
  });

  TreasuryEvolutionState copyWith({
    TreasuryEvolutionStatus? status,
    EvolutionPeriod? period,
    DateTime? customFrom,
    DateTime? customTo,
    bool? rangeError,
    TreasuryEvolution? evolution,
    Failure? failure,
    bool clearEvolution = false,
  }) => TreasuryEvolutionState(
    status: status ?? this.status,
    period: period ?? this.period,
    customFrom: customFrom ?? this.customFrom,
    customTo: customTo ?? this.customTo,
    rangeError: rangeError ?? this.rangeError,
    evolution: clearEvolution ? null : (evolution ?? this.evolution),
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    period,
    customFrom,
    customTo,
    rangeError,
    evolution,
    failure,
  ];
}

/// Trésorerie ▸ Tableau de bord, l'évolution des caisses (A3-A4). La
/// granularité vient de la réponse du serveur (R5), jamais d'un calcul local.
///
/// Un changement rapide de filtre n'affiche que la dernière réponse : chaque
/// lecture porte un numéro.
class TreasuryEvolutionCubit extends Cubit<TreasuryEvolutionState> {
  final TreasuryDashboardRepository _repository;
  var _generation = 0;

  TreasuryEvolutionCubit(this._repository, {required DateTime today})
    : super(
        TreasuryEvolutionState(
          customFrom: DateTime(today.year, today.month, today.day - 29),
          customTo: DateTime(today.year, today.month, today.day),
        ),
      );

  Future<void> periodChanged(EvolutionPeriod period) async {
    emit(state.copyWith(period: period, rangeError: false));
    await load();
  }

  Future<void> customRangeChanged(DateTime from, DateTime to) async {
    emit(state.copyWith(customFrom: from, customTo: to));
    await load();
  }

  /// La période lue dans l'adresse (F5, Précédent, lien) ; les bornes ne
  /// valent que pour la période libre.
  Future<void> applyLocation(
    EvolutionPeriod period, {
    DateTime? from,
    DateTime? to,
  }) async {
    emit(
      state.copyWith(
        period: period,
        customFrom: from ?? state.customFrom,
        customTo: to ?? state.customTo,
        rangeError: false,
      ),
    );
    await load();
  }

  Future<void> load() async {
    final custom = state.period == EvolutionPeriod.custom;
    if (custom && state.customTo.isBefore(state.customFrom)) {
      ++_generation;
      emit(
        state.copyWith(
          status: TreasuryEvolutionStatus.ready,
          rangeError: true,
          clearEvolution: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: TreasuryEvolutionStatus.loading,
        rangeError: false,
        clearEvolution: true,
      ),
    );
    final generation = ++_generation;
    final result = await _repository.evolution(
      state.period,
      from: custom ? state.customFrom : null,
      to: custom ? state.customTo : null,
    );
    if (isClosed || generation != _generation) return;
    // Une borne après aujourd'hui (le serveur dit lequel) : la plage libre se
    // recale sur les 30 jours qui finissent ce jour-là, une seule fois.
    final today = _businessDateOf(result.fold((f) => f, (_) => null));
    if (custom && today != null && today != state.customTo) {
      emit(
        state.copyWith(
          customFrom: DateTime(today.year, today.month, today.day - 29),
          customTo: today,
        ),
      );
      await load();
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: TreasuryEvolutionStatus.failure,
          failure: failure,
        ),
        (evolution) => state.copyWith(
          status: TreasuryEvolutionStatus.ready,
          evolution: evolution,
        ),
      ),
    );
  }

  static DateTime? _businessDateOf(Failure? failure) {
    if (failure is! TreasuryRefusalFailure ||
        failure.refusal != TreasuryRefusal.invalidRange) {
      return null;
    }
    return TreasuryWire.dayOrNull(failure.details['businessDate']);
  }
}
