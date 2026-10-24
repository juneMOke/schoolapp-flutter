import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/usecases/hr_staff_dashboard_use_cases.dart';

enum HrStaffStatsStatus { loading, ready, failure }

class HrStaffStatsState extends Equatable {
  final HrStaffStatsStatus status;
  final HrStaffStats? stats;
  final Failure? failure;

  const HrStaffStatsState({
    this.status = HrStaffStatsStatus.loading,
    this.stats,
    this.failure,
  });

  @override
  List<Object?> get props => [status, stats, failure];
}

/// Les chiffres du haut du tableau de bord, lus au serveur.
///
/// Une relecture (F5, fin d'un envoi) garde les chiffres affichés jusqu'à la
/// réponse : pas de squelette qui clignote, et un échec silencieux ne les
/// efface pas — ils restent ceux d'il y a un instant.
class HrStaffStatsCubit extends Cubit<HrStaffStatsState> {
  final GetHrStaffStatsUseCase _getStats;

  /// Le numéro de la dernière lecture : une réponse dépassée est jetée.
  int _ticket = 0;

  HrStaffStatsCubit({required GetHrStaffStatsUseCase getStats})
    : _getStats = getStats,
      super(const HrStaffStatsState());

  Future<void> load() async {
    final ticket = ++_ticket;
    final shown = state.stats;
    if (shown == null) emit(const HrStaffStatsState());
    final result = await _getStats();
    if (isClosed || ticket != _ticket) return;
    result.fold(
      (failure) {
        if (shown != null) return;
        emit(
          HrStaffStatsState(
            status: HrStaffStatsStatus.failure,
            failure: failure,
          ),
        );
      },
      (stats) => emit(
        HrStaffStatsState(status: HrStaffStatsStatus.ready, stats: stats),
      ),
    );
  }
}
