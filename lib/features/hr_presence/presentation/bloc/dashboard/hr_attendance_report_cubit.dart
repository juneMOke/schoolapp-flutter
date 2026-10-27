import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_report.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

part 'hr_attendance_report_state.dart';

/// Les PDF de présence — l'assiduité (pièce AP), la liste de la fiche
/// individuelle (PR), la fiche d'un agent (FP ou provisoire) — **un à la
/// fois** : préparation qui dure, attente imposée par un 429, document remis
/// puis oublié.
class HrAttendanceReportCubit extends Cubit<HrAttendanceReportState> {
  final GetHrAttendanceReportUseCase _getReport;
  final GetHrAttendanceProfilesReportUseCase? _getProfilesReport;
  final GetHrAttendanceAgentSheetUseCase? _getAgentSheet;

  Timer? _cooldownTimer;

  /// [getProfilesReport] et [getAgentSheet] : les écrans qui les tirent
  /// (la fiche individuelle) ; le tableau de bord n'en a pas besoin.
  HrAttendanceReportCubit({
    required GetHrAttendanceReportUseCase getReport,
    GetHrAttendanceProfilesReportUseCase? getProfilesReport,
    GetHrAttendanceAgentSheetUseCase? getAgentSheet,
  }) : _getReport = getReport,
       _getProfilesReport = getProfilesReport,
       _getAgentSheet = getAgentSheet,
       super(const HrAttendanceReportState());

  /// Le PDF de [window] filtré par [search] — la question qui a produit la
  /// liste affichée.
  Future<void> download(DashboardWindow window, {String search = ''}) =>
      _fetch(() => _getReport(window, search: search.trim()));

  /// La liste de la fiche individuelle sur [scope], filtrée comme l'écran.
  Future<void> downloadProfiles(
    HrProfileScope scope, {
    String search = '',
    StaffCategory? category,
    PresenceProfile? profile,
  }) {
    final get = _getProfilesReport;
    if (get == null) return Future.value();
    return _fetch(
      () => get(
        scope,
        search: search.trim(),
        category: category,
        profile: profile,
      ),
    );
  }

  /// La fiche de présence d'un agent : son mois `AAAA-MM`, ou son année
  /// ([month] `null`).
  Future<void> downloadSheet(String staffMemberId, {String? month}) {
    final get = _getAgentSheet;
    if (get == null) return Future.value();
    return _fetch(() => get(staffMemberId, month: month));
  }

  Future<void> _fetch(
    Future<Either<Failure, HrAttendanceReport>> Function() request,
  ) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        status: HrAttendanceReportStatus.preparing,
        report: null,
        failure: null,
        retryAfter: null,
      ),
    );

    final result = await request();
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
