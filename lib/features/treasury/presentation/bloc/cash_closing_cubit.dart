import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_pending_probe.dart';

enum CashClosingStatus { loading, ready, failure }

class CashClosingState extends Equatable {
  final CashClosingStatus status;

  /// La journée affichée.
  final DateTime date;
  final TreasuryDay? day;

  /// « Aujourd'hui » selon le serveur, connu après le premier chargement et
  /// **gardé** pendant les suivants : la navigation reste possible même
  /// quand une journée échoue à se charger.
  final DateTime? businessDate;

  /// Le début de l'historique : la première mise en service d'une caisse,
  /// gardé comme [businessDate].
  final DateTime? historyStart;

  /// Opérations du jour pas encore envoyées, par devise (aujourd'hui seulement).
  final Map<TreasuryCurrency, int> pendingSync;
  final Failure? failure;

  const CashClosingState({
    required this.date,
    this.status = CashClosingStatus.loading,
    this.day,
    this.businessDate,
    this.historyStart,
    this.pendingSync = const {},
    this.failure,
  });

  @override
  List<Object?> get props => [
    status,
    date,
    day,
    businessDate,
    historyStart,
    pendingSync,
    failure,
  ];
}

/// Trésorerie ▸ Clôture de caisse, vue journalière.
///
/// Après chaque geste (clôture, réponse, réouverture), la journée est
/// **relue** au serveur : le reste, l'écart et le statut sont des chiffres
/// serveur, et l'écran ne les recompose jamais.
///
/// Chaque lecture porte un numéro : seule la plus récente a le droit d'écrire
/// l'état. Une relecture lancée après un geste ne ramène donc jamais l'écran
/// sur une journée qu'on vient de quitter avec ‹ ›.
class CashClosingCubit extends Cubit<CashClosingState> {
  final TreasuryDayRepository _repository;
  final CashPendingProbe _pending;
  var _generation = 0;

  CashClosingCubit(
    this._repository,
    this._pending, {
    required DateTime initialDate,
  }) : super(CashClosingState(date: CashClosingRules.cashDayOf(initialDate)));

  Future<void> load([DateTime? date]) async {
    emit(
      CashClosingState(
        date: date ?? state.date,
        businessDate: state.businessDate,
        historyStart: state.historyStart,
      ),
    );
    await _fetch(state.date);
  }

  /// ‹ › : la journée voisine, dimanche sauté, bornée (R4, R15).
  Future<void> step(int direction) async {
    final next = nextDay(direction);
    if (next != null) await load(next);
  }

  /// La journée où mène ‹ (−1) ou › (+1), `null` à la borne ou tant que le
  /// serveur n'a pas dit quel jour on est.
  DateTime? nextDay(int direction) {
    final today = state.businessDate;
    final min = state.historyStart;
    if (today == null || min == null) return null;
    return CashClosingRules.step(state.date, direction, min: min, today: today);
  }

  Future<void> goToday() async {
    final today = state.businessDate;
    if (today != null && today != state.date) await load(today);
  }

  /// Relit la journée affichée sans repasser par le squelette.
  Future<void> refresh() => _fetch(state.date, quiet: true);

  Future<Either<Failure, CashClosure>> closeRegister({
    required String id,
    required String registerId,
    required bool matches,
    required int shownExpectedInCents,
    int? declaredAmountInCents,
    String? justification,
  }) async {
    final result = await _repository.close(
      state.date,
      id: id,
      registerId: registerId,
      matches: matches,
      shownExpectedInCents: shownExpectedInCents,
      declaredAmountInCents: declaredAmountInCents,
      justification: justification,
    );
    // Succès comme refus (le reste a bougé, quelqu'un a déjà clôturé) : la
    // journée a changé, on la relit.
    await refresh();
    return result;
  }

  Future<Failure?> confirmAfterClosure({
    required String movementId,
    required String id,
    required bool alreadyCounted,
  }) async {
    final result = await _repository.confirmAfterClosure(
      movementId,
      id: id,
      alreadyCounted: alreadyCounted,
    );
    await refresh();
    return result.fold((failure) => failure, (_) => null);
  }

  Future<Failure?> reopen({
    required String closureId,
    required String id,
    required String reason,
  }) async {
    final result = await _repository.reopen(closureId, id: id, reason: reason);
    await refresh();
    return result.fold((failure) => failure, (_) => null);
  }

  Future<void> _fetch(DateTime date, {bool quiet = false}) async {
    final generation = ++_generation;
    bool stale() => isClosed || generation != _generation;
    final result = await _repository.day(date);
    if (stale()) return;
    await result.fold(
      (failure) async {
        // Le serveur refuse un jour qu'il ne sert pas (dimanche, futur : une
        // horloge de tablette en avance) et dit lequel est aujourd'hui.
        final today = _businessDateOf(failure);
        if (today != null && today != date) {
          await load(today);
          return;
        }
        if (quiet && state.day != null) return;
        emit(
          CashClosingState(
            date: date,
            status: CashClosingStatus.failure,
            businessDate: state.businessDate,
            historyStart: state.historyStart,
            failure: failure,
          ),
        );
      },
      (day) async {
        final pending = day.isToday
            ? await _pendingOf(day)
            : const <TreasuryCurrency, int>{};
        if (stale()) return;
        emit(
          CashClosingState(
            date: date,
            status: CashClosingStatus.ready,
            day: day,
            businessDate: day.businessDate,
            historyStart: _historyStartOf(day) ?? state.historyStart,
            pendingSync: pending,
          ),
        );
      },
    );
  }

  static DateTime? _businessDateOf(Failure failure) {
    if (failure is! TreasuryRefusalFailure ||
        failure.refusal != TreasuryRefusal.invalidDate) {
      return null;
    }
    return TreasuryWire.dayOrNull(failure.details['businessDate']);
  }

  static DateTime? _historyStartOf(TreasuryDay day) {
    if (day.registers.isEmpty) return null;
    return day.registers
        .map((r) => r.register.inServiceOn)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  Future<Map<TreasuryCurrency, int>> _pendingOf(TreasuryDay day) async => {
    for (final summary in day.registers)
      summary.register.currency: await _pending.pendingFor(
        summary.register.currency,
      ),
  };
}
