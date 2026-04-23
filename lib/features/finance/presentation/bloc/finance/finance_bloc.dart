import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart'; // nécessaire pour finance_state.dart (part)
import 'package:school_app_flutter/features/finance/domain/usecases/get_fee_tariffs_usecase.dart';

part 'finance_event.dart';
part 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final GetFeeTariffsUseCase _getFeeTariffsUseCase;

  FinanceBloc({required GetFeeTariffsUseCase getFeeTariffsUseCase})
      : _getFeeTariffsUseCase = getFeeTariffsUseCase,
        super(const FinanceState()) {
    on<FinanceFeeTariffsRequested>(_onFeeTariffsRequested);
  }

  Future<void> _onFeeTariffsRequested(
    FinanceFeeTariffsRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading, errorMessage: null));

    final result = await _getFeeTariffsUseCase(levelId: event.levelId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FinanceStatus.failure,
          errorMessage: _mapFailureToMessage(failure),
        ),
      ),
      (tariffs) => emit(
        state.copyWith(
          status: FinanceStatus.success,
          tariffs: tariffs,
          errorMessage: null,
        ),
      ),
    );
  }

  String _mapFailureToMessage(Failure failure) => switch (failure) {
    NetworkFailure() => 'Vérifiez votre connexion internet',
    UnauthorizedFailure() => 'Accès non autorisé',
    InvalidCredentialsFailure() => 'Identifiants incorrects',
    ServerFailure() => 'Erreur serveur, réessayez plus tard',
    StorageFailure() => 'Erreur de stockage local',
    _ => 'Une erreur est survenue',
  };
}
