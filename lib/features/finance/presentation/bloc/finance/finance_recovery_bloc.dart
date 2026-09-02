import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_recovery_usecase.dart';

part 'finance_recovery_event.dart';
part 'finance_recovery_state.dart';

/// L'onglet **Recouvrement** du tableau de bord Finances.
///
/// ## Un seul évènement, et c'est le split qui l'offre
///
/// Le BLoC d'avant en portait trois — demander, rafraîchir, réinitialiser —
/// parce qu'il fallait mémoriser la fenêtre choisie pour la rejouer. Le
/// recouvrement n'a plus de fenêtre : l'année scolaire courante, toujours. Le
/// premier chargement et le bouton « Réessayer » sont donc **le même geste**,
/// et un second évènement n'aurait fait que décrire deux fois le même appel.
class FinanceRecoveryBloc
    extends Bloc<FinanceRecoveryEvent, FinanceRecoveryState> {
  final GetFinanceRecoveryUseCase _getFinanceRecoveryUseCase;

  FinanceRecoveryBloc({
    required GetFinanceRecoveryUseCase getFinanceRecoveryUseCase,
  }) : _getFinanceRecoveryUseCase = getFinanceRecoveryUseCase,
       super(const FinanceRecoveryState()) {
    on<FinanceRecoveryRequested>(_onRequested);
  }

  Future<void> _onRequested(
    FinanceRecoveryRequested event,
    Emitter<FinanceRecoveryState> emit,
  ) async {
    emit(state.copyWith(status: FinanceRecoveryStatus.loading, failure: null));

    final result = await _getFinanceRecoveryUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(status: FinanceRecoveryStatus.error, failure: failure),
      ),
      (recovery) => emit(
        state.copyWith(
          status: FinanceRecoveryStatus.success,
          recovery: recovery,
          failure: null,
        ),
      ),
    );
  }
}
