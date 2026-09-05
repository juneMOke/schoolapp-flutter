import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_stats_use_case.dart';

part 'enrollment_stats_event.dart';
part 'enrollment_stats_state.dart';

/// Le tableau de bord des inscriptions — **une fenêtre, un fait**.
///
/// Ce bloc fait seul autorité sur ce que la page rend sous son en-tête. Les
/// quatre états qu'il émet (`loading`, `success`, `empty`, `error`) ne sont pas
/// des nuances d'affichage : ils décident quels blocs **existent**.
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
        failure: null,
        window: event.window,
      ),
    );

    final result = await _getEnrollmentStatsUseCase(window: event.window);

    result.fold(
      // L'erreur emporte les données AVEC elle.
      //
      // Sans ce `stats: null`, la dernière lecture réussie survivait à l'échec
      // suivant : le bandeau d'effectif aurait affiché un total d'il y a dix
      // minutes, sous un écran en erreur, sans rien qui le signale. « Sans
      // données, l'effectif affiché serait un mensonge » — et la façon de tenir
      // cette règle est de ne plus AVOIR la donnée, pas de compter sur chaque
      // widget pour s'abstenir de la lire.
      (failure) => emit(
        state.copyWith(
          status: EnrollmentStatsStatus.error,
          stats: null,
          failure: failure,
        ),
      ),
      (stats) => emit(
        state.copyWith(status: _statusFor(stats), stats: stats, failure: null),
      ),
    );
  }

  /// Vide ou plein — tranché ici, une fois pour tout l'écran.
  ///
  /// `pre > 0` n'est **pas** un vide : des demandes en ligne attendent d'être
  /// traitées, l'écran a donc quelque chose à dire et une action à proposer.
  static EnrollmentStatsStatus _statusFor(EnrollmentStats stats) {
    final total = stats.kpis.totalEnrollments.value;
    final pre = stats.kpis.preEnrollments.value;
    return total == 0 && pre == 0
        ? EnrollmentStatsStatus.empty
        : EnrollmentStatsStatus.success;
  }

  Future<void> _onRefreshRequested(
    EnrollmentStatsRefreshRequested event,
    Emitter<EnrollmentStatsState> emit,
  ) async {
    add(EnrollmentStatsRequested(window: state.window));
  }

  void _onResetRequested(
    EnrollmentStatsResetRequested event,
    Emitter<EnrollmentStatsState> emit,
  ) {
    emit(const EnrollmentStatsState());
  }
}
