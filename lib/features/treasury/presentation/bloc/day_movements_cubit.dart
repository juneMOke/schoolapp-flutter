import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';

enum DayMovementsStatus { loading, ready, failure }

class DayMovementsState extends Equatable {
  final DayMovementsStatus status;
  final List<CashMovement> items;

  final Failure? failure;

  const DayMovementsState({
    this.status = DayMovementsStatus.loading,
    this.items = const [],
    this.failure,
  });

  /// Une ligne arrivée après une clôture, encore sans réponse : elle retient
  /// la clôture (R19), **même défaite** — le serveur lui garde sa question
  /// (PR back #230). Seule une correction sans argent rendu la passe à son
  /// remplaçant, ce que la ligne ne dit pas encore : la réponse est alors
  /// refusée (`NOT_AFTER_CLOSURE`) et la journée relue.
  bool awaitsAnswer(CashMovement m) => m.awaitsAnswer;

  @override
  List<Object?> get props => [status, items, failure];
}

/// Les entrées ou les sorties d'une caisse sur une journée, chargées quand on
/// déplie la case (B4). Un échec reste dans la liste : la carte reste
/// utilisable.
///
/// On lit la journée **entière** de la caisse et on garde le sens demandé :
/// c'est la seule façon de savoir qu'une entrée a été défaite par une sortie.
class DayMovementsCubit extends Cubit<DayMovementsState> {
  final TreasuryDayRepository _repository;
  final DateTime date;
  final String registerId;
  final MovementDirection direction;

  DayMovementsCubit(
    this._repository, {
    required this.date,
    required this.registerId,
    required this.direction,
  }) : super(const DayMovementsState());

  Future<void> load() async {
    emit(const DayMovementsState());
    final result = await _repository.movements(date, registerId: registerId);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => DayMovementsState(
          status: DayMovementsStatus.failure,
          failure: failure,
        ),
        (all) => DayMovementsState(
          status: DayMovementsStatus.ready,
          items: [
            for (final m in all)
              if (m.direction == direction) m,
          ],
        ),
      ),
    );
  }
}
