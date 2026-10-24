import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_list_report.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/usecases/hr_staff_dashboard_use_cases.dart';

part 'hr_staff_list_report_state.dart';

/// La liste du personnel en PDF (pièce LP) — **une à la fois**, comme le
/// rapport des ventes de la boutique : préparation qui dure, attente imposée
/// par un 429, document remis puis oublié (la pièce n'est pas archivée, la
/// redemander en produit une autre).
class HrStaffListReportCubit extends Cubit<HrStaffListReportState> {
  final GetHrStaffListReportUseCase _getReport;

  Timer? _cooldownTimer;

  HrStaffListReportCubit({required GetHrStaffListReportUseCase getReport})
    : _getReport = getReport,
      super(const HrStaffListReportState());

  /// Demande la liste de [query] — la question qui a produit la liste
  /// affichée, toutes pages.
  Future<void> download(HrRosterQuery query) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        status: HrStaffListReportStatus.preparing,
        report: null,
        failure: null,
        retryAfter: null,
      ),
    );

    final result = await _getReport(query);
    // Le rendu prend plusieurs secondes : l'écran a pu être quitté.
    if (isClosed) return;

    result.fold(
      (failure) {
        // ⚠️ Le 429 n'est pas un échec, c'est un tour de file : le bouton
        // reste désarmé le temps annoncé.
        if (failure is TooManyRequestsFailure) {
          final wait =
              failure.retryAfter ?? AppConstants.hrStaffListReportRetryFallback;
          emit(
            state.copyWith(
              status: HrStaffListReportStatus.cooldown,
              failure: failure,
              retryAfter: wait,
              report: null,
            ),
          );
          _startCooldown(wait);
          return;
        }
        emit(
          state.copyWith(
            status: HrStaffListReportStatus.idle,
            failure: failure,
            report: null,
            retryAfter: null,
          ),
        );
      },
      (report) => emit(
        state.copyWith(
          status: HrStaffListReportStatus.idle,
          report: report,
          failure: null,
          retryAfter: null,
        ),
      ),
    );
  }

  /// La vue a remis le document (ou dit l'échec) : l'état se vide.
  void acknowledge() {
    if (!state.hasDelivery) return;
    emit(state.clearDelivery());
  }

  void _startCooldown(Duration wait) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(wait, () {
      if (isClosed) return;
      emit(state.copyWith(status: HrStaffListReportStatus.idle));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
