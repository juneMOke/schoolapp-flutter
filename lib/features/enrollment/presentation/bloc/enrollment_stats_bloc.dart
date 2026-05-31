import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_stats_use_case.dart';

part 'enrollment_stats_event.dart';
part 'enrollment_stats_state.dart';

class EnrollmentStatsBloc
    extends Bloc<EnrollmentStatsEvent, EnrollmentStatsState> {
  final GetEnrollmentStatsUseCase _getEnrollmentStatsUseCase;

  EnrollmentStatsBloc({
    required GetEnrollmentStatsUseCase getEnrollmentStatsUseCase,
  }) : _getEnrollmentStatsUseCase = getEnrollmentStatsUseCase,
       super(const EnrollmentStatsState()) {
    on<EnrollmentStatsRequested>(_onRequested);
    on<EnrollmentStatsRefreshRequested>(_onRefreshRequested);
    on<EnrollmentStatsResetRequested>(_onResetRequested);
  }

  Future<void> _onRequested(
    EnrollmentStatsRequested event,
    Emitter<EnrollmentStatsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EnrollmentStatsStatus.loading,
        errorType: EnrollmentStatsErrorType.none,
        errorMessage: null,
        selectedPeriod: event.period,
        selectedMonth: event.month,
        selectedWeek: event.week,
      ),
    );

    final result = await _getEnrollmentStatsUseCase(
      period: event.period,
      month: event.month,
      week: event.week,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EnrollmentStatsStatus.error,
          errorType: _mapFailureToErrorType(failure),
          errorMessage: _mapFailureToMessage(failure),
        ),
      ),
      (stats) => emit(
        state.copyWith(
          status: EnrollmentStatsStatus.success,
          stats: stats,
          errorType: EnrollmentStatsErrorType.none,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    EnrollmentStatsRefreshRequested event,
    Emitter<EnrollmentStatsState> emit,
  ) async {
    add(
      EnrollmentStatsRequested(
        period: state.selectedPeriod,
        month: state.selectedMonth,
        week: state.selectedWeek,
      ),
    );
  }

  void _onResetRequested(
    EnrollmentStatsResetRequested event,
    Emitter<EnrollmentStatsState> emit,
  ) {
    emit(const EnrollmentStatsState());
  }

  EnrollmentStatsErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => EnrollmentStatsErrorType.network,
        NotFoundFailure() => EnrollmentStatsErrorType.notFound,
        ValidationFailure() => EnrollmentStatsErrorType.validation,
        UnauthorizedFailure() => EnrollmentStatsErrorType.unauthorized,
        InvalidCredentialsFailure() =>
          EnrollmentStatsErrorType.invalidCredentials,
        ServerFailure() => EnrollmentStatsErrorType.server,
        StorageFailure() => EnrollmentStatsErrorType.storage,
        AuthFailure() => EnrollmentStatsErrorType.auth,
        _ => EnrollmentStatsErrorType.unknown,
      };

  String _mapFailureToMessage(Failure failure) => switch (failure) {
    NetworkFailure() => 'Verifiez votre connexion internet',
    NotFoundFailure() => 'Aucune statistique disponible',
    ValidationFailure() => 'Parametres invalides',
    UnauthorizedFailure() => 'Acces non autorise',
    InvalidCredentialsFailure() => 'Session invalide, reconnectez-vous',
    ServerFailure() => 'Erreur serveur, reessayez plus tard',
    StorageFailure() => 'Erreur de stockage local',
    AuthFailure() => 'Erreur d\'authentification',
    _ => 'Une erreur est survenue',
  };
}
