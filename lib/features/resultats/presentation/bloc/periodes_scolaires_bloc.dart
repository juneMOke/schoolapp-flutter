import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_periodes_scolaires_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

/// BLoC de **lecture** des grandes périodes de l'année (source des
/// `periodeScolaireId` pour la vue classe / focus).
///
/// Ne déclenche rien au montage : attend un [PeriodesScolairesRequested] émis
/// quand un cycle est sélectionné. Une liste vide donne l'état
/// [PeriodesScolairesStatus.empty], distinct d'un échec.
class PeriodesScolairesBloc
    extends Bloc<PeriodesScolairesEvent, PeriodesScolairesState> {
  final GetPeriodesScolairesUseCase _getPeriodesScolaires;

  PeriodesScolairesBloc({
    required GetPeriodesScolairesUseCase getPeriodesScolaires,
  }) : _getPeriodesScolaires = getPeriodesScolaires,
       super(const PeriodesScolairesState()) {
    on<PeriodesScolairesRequested>(_onPeriodesScolairesRequested);
  }

  Future<void> _onPeriodesScolairesRequested(
    PeriodesScolairesRequested event,
    Emitter<PeriodesScolairesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PeriodesScolairesStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
    );

    final result = await _getPeriodesScolaires(event.classroomId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PeriodesScolairesStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (periodes) => emit(
        state.copyWith(
          status: periodes.isEmpty
              ? PeriodesScolairesStatus.empty
              : PeriodesScolairesStatus.success,
          periodes: periodes,
          errorType: ResultatsErrorType.none,
        ),
      ),
    );
  }

  ResultatsErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => ResultatsErrorType.network,
        NotFoundFailure() => ResultatsErrorType.notFound,
        ValidationFailure() => ResultatsErrorType.validation,
        UnauthorizedFailure() => ResultatsErrorType.forbidden,
        InvalidCredentialsFailure() => ResultatsErrorType.invalidCredentials,
        ServerFailure() => ResultatsErrorType.server,
        StorageFailure() => ResultatsErrorType.storage,
        AuthFailure() => ResultatsErrorType.auth,
        _ => ResultatsErrorType.unknown,
      };
}
