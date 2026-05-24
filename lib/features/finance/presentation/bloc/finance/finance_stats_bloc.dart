import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_stats_usecase.dart';

part 'finance_stats_event.dart';
part 'finance_stats_state.dart';

class FinanceStatsBloc extends Bloc<FinanceStatsEvent, FinanceStatsState> {
  final GetFinanceStatsUseCase _getFinanceStatsUseCase;

  FinanceStatsBloc({required GetFinanceStatsUseCase getFinanceStatsUseCase})
    : _getFinanceStatsUseCase = getFinanceStatsUseCase,
      super(const FinanceStatsState()) {
    on<FinanceStatsRequested>(_onRequested);
    on<FinanceStatsRefreshRequested>(_onRefreshRequested);
    on<FinanceStatsResetRequested>(_onResetRequested);
  }

  Future<void> _onRequested(
    FinanceStatsRequested event,
    Emitter<FinanceStatsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FinanceStatsStatus.loading,
        errorType: FinanceStatsErrorType.none,
        errorMessage: null,
        selectedPeriod: event.period,
        selectedMonth: event.month,
        selectedWeek: event.week,
      ),
    );

    final result = await _getFinanceStatsUseCase(
      period: event.period,
      month: event.month,
      week: event.week,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FinanceStatsStatus.error,
          errorType: _mapFailureToErrorType(failure),
          errorMessage: _mapFailureToMessage(failure),
        ),
      ),
      (stats) => emit(
        state.copyWith(
          status: FinanceStatsStatus.success,
          stats: stats,
          errorType: FinanceStatsErrorType.none,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    FinanceStatsRefreshRequested event,
    Emitter<FinanceStatsState> emit,
  ) async {
    add(
      FinanceStatsRequested(
        period: state.selectedPeriod,
        month: state.selectedMonth,
        week: state.selectedWeek,
      ),
    );
  }

  void _onResetRequested(
    FinanceStatsResetRequested event,
    Emitter<FinanceStatsState> emit,
  ) {
    emit(const FinanceStatsState());
  }

  FinanceStatsErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => FinanceStatsErrorType.network,
        NotFoundFailure() => FinanceStatsErrorType.notFound,
        ValidationFailure() => FinanceStatsErrorType.validation,
        UnauthorizedFailure() => FinanceStatsErrorType.unauthorized,
        InvalidCredentialsFailure() => FinanceStatsErrorType.invalidCredentials,
        ServerFailure() => FinanceStatsErrorType.server,
        StorageFailure() => FinanceStatsErrorType.storage,
        AuthFailure() => FinanceStatsErrorType.auth,
        _ => FinanceStatsErrorType.unknown,
      };

  String _mapFailureToMessage(Failure failure) => switch (failure) {
    NetworkFailure() => 'Verifiez votre connexion internet',
    NotFoundFailure() => 'Aucune statistique financiere disponible',
    ValidationFailure() => 'Parametres invalides',
    UnauthorizedFailure() => 'Acces non autorise',
    InvalidCredentialsFailure() => 'Session invalide, reconnectez-vous',
    ServerFailure() => 'Erreur serveur, reessayez plus tard',
    StorageFailure() => 'Erreur de stockage local',
    AuthFailure() => 'Erreur d\'authentification',
    _ => 'Une erreur est survenue',
  };
}
