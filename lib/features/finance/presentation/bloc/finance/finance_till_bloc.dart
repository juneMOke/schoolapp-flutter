import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_period.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_till_usecase.dart';

part 'finance_till_event.dart';
part 'finance_till_state.dart';

/// L'onglet **Caisse** du tableau de bord Finances.
///
/// Contrairement au recouvrement, la caisse a une fenêtre — et c'est tout ce
/// qui la distingue côté état. Le grain choisi est retenu pour que le
/// rafraîchissement rejoue la **même** fenêtre : recharger après une coupure ne
/// doit pas ramener l'écran au jour courant sans le dire.
class FinanceTillBloc extends Bloc<FinanceTillEvent, FinanceTillState> {
  final GetFinanceTillUseCase _getFinanceTillUseCase;

  FinanceTillBloc({required GetFinanceTillUseCase getFinanceTillUseCase})
    : _getFinanceTillUseCase = getFinanceTillUseCase,
      super(const FinanceTillState()) {
    on<FinanceTillRequested>(_onRequested);
    on<FinanceTillRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onRequested(
    FinanceTillRequested event,
    Emitter<FinanceTillState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FinanceTillStatus.loading,
        selectedPeriod: event.period,
        failure: null,
      ),
    );

    final result = await _getFinanceTillUseCase(period: event.period);

    result.fold(
      (failure) => emit(
        state.copyWith(status: FinanceTillStatus.error, failure: failure),
      ),
      (till) => emit(
        state.copyWith(
          status: FinanceTillStatus.success,
          till: till,
          failure: null,
        ),
      ),
    );
  }

  /// Rejoue la fenêtre **retenue**, jamais le défaut.
  Future<void> _onRefreshRequested(
    FinanceTillRefreshRequested event,
    Emitter<FinanceTillState> emit,
  ) async {
    add(FinanceTillRequested(period: state.selectedPeriod));
  }
}
