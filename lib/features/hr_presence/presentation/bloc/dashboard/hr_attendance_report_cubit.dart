import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_report.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';

part 'hr_attendance_report_state.dart';

/// L'assiduité des agents en PDF (pièce AP) — **une à la fois**, comme la
/// liste du personnel : préparation qui dure, attente imposée par un 429,
/// document remis puis oublié.
class HrAttendanceReportCubit extends Cubit<HrAttendanceReportState> {
  final GetHrAttendanceReportUseCase _getReport;

  Timer? _cooldownTimer;

  HrAttendanceReportCubit({required GetHrAttendanceReportUseCase getReport})
    : _getReport = getReport,
      super(const HrAttendanceReportState());

  /// Le PDF de [window] filtré par [search] — la question qui a produit la
  /// liste affichée.
  Future<void> download(DashboardWindow window, {String search = ''}) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        status: HrAttendanceReportStatus.preparing,
        report: null,
        failure: null,
        retryAfter: null,
      ),
    );

    final result = await _getReport(window, search: search.trim());
    if (isClosed) return;

    result.fold(
      (failure) {
        // ⚠️ Le 429 n'est pas un échec, c'est un tour de file.
        if (failure is TooManyRequestsFailure) {
          final wait =
              failure.retryAfter ??
              AppConstants.hrAttendanceReportRetryFallback;
          emit(
            state.copyWith(
              status: HrAttendanceReportStatus.cooldown,
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
            status: HrAttendanceReportStatus.idle,
            failure: failure,
            report: null,
            retryAfter: null,
          ),
        );
      },
      (report) => emit(
        state.copyWith(
          status: HrAttendanceReportStatus.idle,
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
      emit(state.copyWith(status: HrAttendanceReportStatus.idle));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
