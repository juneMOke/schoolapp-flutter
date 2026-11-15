import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_dashboard_repository.dart';

enum TreasuryOverviewStatus { loading, ready, failure }

class TreasuryOverviewState extends Equatable {
  final TreasuryOverviewStatus status;
  final TreasuryOverview? overview;
  final Failure? failure;

  const TreasuryOverviewState({
    this.status = TreasuryOverviewStatus.loading,
    this.overview,
    this.failure,
  });

  @override
  List<Object?> get props => [status, overview, failure];
}

/// Trésorerie ▸ Tableau de bord, les KPI par caisse (A2). Les chiffres sont
/// ceux du serveur ; la tablette ne recompose aucun solde.
class TreasuryOverviewCubit extends Cubit<TreasuryOverviewState> {
  final TreasuryDashboardRepository _repository;

  TreasuryOverviewCubit(this._repository)
    : super(const TreasuryOverviewState());

  Future<void> load() async {
    emit(const TreasuryOverviewState());
    final result = await _repository.overview();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => TreasuryOverviewState(
          status: TreasuryOverviewStatus.failure,
          failure: failure,
        ),
        (overview) => TreasuryOverviewState(
          status: TreasuryOverviewStatus.ready,
          overview: overview,
        ),
      ),
    );
  }
}
