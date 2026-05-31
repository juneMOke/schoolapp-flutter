import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_stats_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_state.dart';

class ClassroomStatsBloc
    extends Bloc<ClassroomStatsEvent, ClassroomStatsState> {
  final GetClassroomStatsUseCase _getClassroomStatsUseCase;

  ClassroomStatsBloc({
    required GetClassroomStatsUseCase getClassroomStatsUseCase,
  }) : _getClassroomStatsUseCase = getClassroomStatsUseCase,
       super(const ClassroomStatsState()) {
    on<ClassroomStatsRequested>(_onRequested);
    on<ClassroomStatsRefreshRequested>(_onRefreshRequested);
    on<ClassroomStatsResetRequested>(_onResetRequested);
  }

  Future<void> _onRequested(
    ClassroomStatsRequested event,
    Emitter<ClassroomStatsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClassroomStatsStatus.loading,
        errorType: ClassroomStatsErrorType.none,
        errorMessage: null,
      ),
    );

    final result = await _getClassroomStatsUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ClassroomStatsStatus.error,
          errorType: _mapFailureToErrorType(failure),
          errorMessage: _mapFailureToMessage(failure),
        ),
      ),
      (stats) => emit(
        state.copyWith(
          status: ClassroomStatsStatus.success,
          stats: stats,
          errorType: ClassroomStatsErrorType.none,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    ClassroomStatsRefreshRequested event,
    Emitter<ClassroomStatsState> emit,
  ) async {
    add(const ClassroomStatsRequested());
  }

  void _onResetRequested(
    ClassroomStatsResetRequested event,
    Emitter<ClassroomStatsState> emit,
  ) {
    emit(const ClassroomStatsState());
  }

  ClassroomStatsErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => ClassroomStatsErrorType.network,
        NotFoundFailure() => ClassroomStatsErrorType.notFound,
        ValidationFailure() => ClassroomStatsErrorType.validation,
        UnauthorizedFailure() => ClassroomStatsErrorType.unauthorized,
        InvalidCredentialsFailure() =>
          ClassroomStatsErrorType.invalidCredentials,
        ServerFailure() => ClassroomStatsErrorType.server,
        StorageFailure() => ClassroomStatsErrorType.storage,
        AuthFailure() => ClassroomStatsErrorType.auth,
        _ => ClassroomStatsErrorType.unknown,
      };

  String _mapFailureToMessage(Failure failure) => switch (failure) {
    NetworkFailure() => 'Verifiez votre connexion internet',
    NotFoundFailure() => 'Aucune statistique de classe disponible',
    ValidationFailure() => 'Parametres invalides',
    UnauthorizedFailure() => 'Acces non autorise',
    InvalidCredentialsFailure() => 'Session invalide, reconnectez-vous',
    ServerFailure() => 'Erreur serveur, reessayez plus tard',
    StorageFailure() => 'Erreur de stockage local',
    AuthFailure() => 'Erreur d\'authentification',
    _ => 'Une erreur est survenue',
  };
}
