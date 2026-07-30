import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart'
    show AttendanceErrorType;
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_absence_list.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_perfect_card.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_period_filter.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_card.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_skeleton.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_view_data.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Onglet « Presence » de la fiche eleve : synthese d'assiduite sur une
/// periode, calculee **100% en local** (AF-3 §5, dénominateur = jours
/// réellement appelés via `attendance_sessions`). Consomme le
/// [AttendanceOfflineBloc] déjà fourni par `AttendanceFeatureScope` — aucun
/// bloc dédié, aucun appel réseau.
class StudentAttendanceSummaryTab extends StatefulWidget {
  final String studentId;
  final String academicYearId;

  const StudentAttendanceSummaryTab({
    super.key,
    required this.studentId,
    required this.academicYearId,
  });

  @override
  State<StudentAttendanceSummaryTab> createState() =>
      _StudentAttendanceSummaryTabState();
}

class _StudentAttendanceSummaryTabState
    extends State<StudentAttendanceSummaryTab> {
  StatsPeriod _period = StatsPeriod.year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _request(_period);
    });
  }

  void _request(StatsPeriod period) {
    context.read<AttendanceOfflineBloc>().add(
      LoadStudentStatsRequested(
        studentId: widget.studentId,
        academicYearId: widget.academicYearId,
        period: period,
        reference: DateTime.now(),
      ),
    );
  }

  void _onPeriodSelected(StatsPeriod period) {
    if (period == _period) return;
    setState(() => _period = period);
    _request(period);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PresencePeriodFilter(
            selected: _period,
            onSelected: _onPeriodSelected,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          BlocBuilder<AttendanceOfflineBloc, AttendanceOfflineState>(
            // Ce bloc porte aussi l'appel du jour / le taux dérivé (autres
            // onglets du module Présence) : on ne reconstruit que sur les
            // états pertinents à cette synthèse.
            buildWhen: (prev, curr) =>
                curr is AttendanceOfflineInitial ||
                curr is AttendanceOfflineLoading ||
                curr is AttendanceOfflineStatsLoaded ||
                curr is AttendanceOfflineError,
            builder: (context, state) {
              final stats = state is AttendanceOfflineStatsLoaded
                  ? state.stats
                  : null;

              final child = switch (state) {
                AttendanceOfflineError() => AttendanceResultsErrorState(
                  type: AttendanceErrorType.storage,
                  onRetry: () => _request(_period),
                ),
                AttendanceOfflineStatsLoaded() when stats != null =>
                  _buildLoaded(context, stats),
                _ => const PresenceSummarySkeleton(),
              };

              return AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.outCurve,
                switchOutCurve: AppMotion.inCurve,
                child: KeyedSubtree(
                  key: ValueKey('${state.runtimeType}-${_period.name}'),
                  child: child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, StudentAttendanceStats stats) {
    final l10n = AppLocalizations.of(context)!;

    // Invariant #7 : chiffres pas encore fiables tant que le bootstrap local
    // (appels + transferts) n'est pas complet — on ne les affiche jamais.
    if (!stats.available) {
      return EteeloEmptyResult(
        medallionIcon: Icons.cloud_sync_outlined,
        label: l10n.presenceOfflineSyncPendingTitle,
        description: l10n.presenceOfflineSyncPendingMessage,
        fullWidthCard: true,
        minHeight: 260,
        primaryAction: EteeloButton.primary(
          label: l10n.attendanceErrorRetry,
          icon: Icons.refresh_rounded,
          onPressed: () => _request(_period),
          fullWidth: false,
        ),
      );
    }

    final vm = PresenceSummaryViewData(stats);

    if (!vm.hasSchoolDays) {
      return EteeloEmptyResult(
        medallionIcon: Icons.calendar_month_rounded,
        label: l10n.presenceEmptyTitle,
        description: l10n.presenceEmptyMessage,
        fullWidthCard: true,
        minHeight: 260,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PresenceSummaryCard(data: vm, rangeLabel: _rangeLabel(l10n, stats)),
        const SizedBox(height: AppDimensions.spacingM),
        if (vm.isPerfect)
          const PresencePerfectCard()
        else
          PresenceAbsenceList(data: vm),
      ],
    );
  }

  String _rangeLabel(AppLocalizations l10n, StudentAttendanceStats stats) =>
      switch (stats.period) {
        StatsPeriod.year => l10n.presenceRangeYear(_academicYearName()),
        StatsPeriod.month => l10n.presenceRangeMonth(stats.from!),
        StatsPeriod.week => l10n.presenceRangeWeek(stats.from!),
      };

  String _academicYearName() =>
      context
          .read<AcademicYearContextBloc>()
          .state
          .context
          ?.academicYear
          .name ??
      '';
}
