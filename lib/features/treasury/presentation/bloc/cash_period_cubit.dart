import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';

enum CashPeriodStatus { loading, ready, failure }

class CashPeriodState extends Equatable {
  final CashPeriodStatus status;

  /// [ClosingScope.week] ou [ClosingScope.month].
  final ClosingScope scope;

  /// Le premier jour de la période affichée (lundi, ou 1er du mois).
  final DateTime from;
  final TreasuryPeriod? period;
  final Failure? failure;

  const CashPeriodState({
    required this.scope,
    required this.from,
    this.status = CashPeriodStatus.loading,
    this.period,
    this.failure,
  });

  DateTime get to => CashClosingRules.rangeOf(scope, from).to;

  @override
  List<Object?> get props => [status, scope, from, period, failure];
}

/// Trésorerie ▸ Clôture de caisse, vues hebdomadaire et mensuelle (B7) : les
/// totaux par caisse et les journées écoulées. Lecture seule, en ligne.
///
/// Comme la journée, chaque lecture porte un numéro : une réponse lente ne
/// ramène jamais l'écran sur une période qu'on vient de quitter.
class CashPeriodCubit extends Cubit<CashPeriodState> {
  final TreasuryDayRepository _repository;

  /// « Aujourd'hui » selon le serveur, et le début de l'historique : les
  /// bornes de ‹ › (R15).
  DateTime _today;
  final DateTime _historyStart;
  var _generation = 0;

  CashPeriodCubit(
    this._repository, {
    required ClosingScope scope,
    required DateTime today,
    required DateTime historyStart,
  }) : _today = today,
       _historyStart = historyStart,
       super(
         CashPeriodState(
           scope: scope,
           from: CashClosingRules.rangeOf(scope, today).from,
         ),
       );

  /// La période voisine, `null` à la borne.
  DateTime? nextFrom(int direction) => CashClosingRules.stepPeriod(
    state.scope,
    state.from,
    direction: direction,
    min: _historyStart,
    today: _today,
  );

  bool get isCurrent =>
      state.from == CashClosingRules.rangeOf(state.scope, _today).from;

  Future<void> load([DateTime? from]) async {
    final target = from ?? state.from;
    emit(CashPeriodState(scope: state.scope, from: target));
    final generation = ++_generation;
    final range = CashClosingRules.rangeOf(state.scope, target);
    final result = await _repository.period(range.from, range.to);
    if (isClosed || generation != _generation) return;
    await result.fold(
      (failure) async {
        // Le serveur refuse une période qui n'a pas commencé (horloge de
        // tablette en avance) et dit quel jour on est.
        final today = _businessDateOf(failure);
        if (today != null && today != _today) {
          _today = today;
          await load(CashClosingRules.rangeOf(state.scope, today).from);
          return;
        }
        emit(
          CashPeriodState(
            scope: state.scope,
            from: target,
            status: CashPeriodStatus.failure,
            failure: failure,
          ),
        );
      },
      (period) async {
        emit(
          CashPeriodState(
            scope: state.scope,
            from: target,
            status: CashPeriodStatus.ready,
            period: period,
          ),
        );
      },
    );
  }

  Future<void> step(int direction) async {
    final next = nextFrom(direction);
    if (next != null) await load(next);
  }

  Future<void> goCurrent() =>
      load(CashClosingRules.rangeOf(state.scope, _today).from);

  static DateTime? _businessDateOf(Failure failure) {
    if (failure is! TreasuryRefusalFailure ||
        failure.refusal != TreasuryRefusal.invalidRange) {
      return null;
    }
    return TreasuryWire.dayOrNull(failure.details['businessDate']);
  }
}
