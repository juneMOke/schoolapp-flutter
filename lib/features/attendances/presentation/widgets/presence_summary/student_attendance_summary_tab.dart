import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/student_attendance_summary_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/student_attendance_summary_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/student_attendance_summary_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_absence_list.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_perfect_card.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_period_filter.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_card.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_skeleton.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_view_data.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Onglet « Presence » de la fiche eleve : synthese d'assiduite sur une periode.
///
/// Fournit son propre [StudentAttendanceSummaryBloc] (factory) et lance un
/// premier chargement sur la periode par defaut (annee).
class StudentAttendanceSummaryTab extends StatelessWidget {
  final String studentId;

  const StudentAttendanceSummaryTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentAttendanceSummaryBloc>(
      create: (_) => GetIt.instance<StudentAttendanceSummaryBloc>()
        ..add(
          StudentAttendanceSummaryRequested(
            studentId: studentId,
            period: StatsPeriod.year,
          ),
        ),
      child: _StudentAttendanceSummaryView(studentId: studentId),
    );
  }
}

class _StudentAttendanceSummaryView extends StatefulWidget {
  final String studentId;

  const _StudentAttendanceSummaryView({required this.studentId});

  @override
  State<_StudentAttendanceSummaryView> createState() =>
      _StudentAttendanceSummaryViewState();
}

class _StudentAttendanceSummaryViewState
    extends State<_StudentAttendanceSummaryView> {
  StatsPeriod _period = StatsPeriod.year;

  void _request(StatsPeriod period) {
    context.read<StudentAttendanceSummaryBloc>().add(
      StudentAttendanceSummaryRequested(
        studentId: widget.studentId,
        period: period,
        month: period == StatsPeriod.month ? _monthAnchor() : null,
        week: period == StatsPeriod.week ? _weekAnchor() : null,
      ),
    );
  }

  void _onPeriodSelected(StatsPeriod period) {
    if (period == _period) return;
    setState(() => _period = period);
    _request(period);
  }

  /// Ancre `YYYY-MM` sur le mois courant.
  String _monthAnchor() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
  }

  /// Ancre `YYYY-MM-DD` sur le jour courant (le backend resout la semaine).
  String _weekAnchor() => DateOnlyJsonHelper.toJson(DateTime.now());

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
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
          BlocBuilder<
            StudentAttendanceSummaryBloc,
            StudentAttendanceSummaryState
          >(
            builder: (context, state) {
              final child = switch (state.status) {
                StudentAttendanceSummaryStatus.failure =>
                  AttendanceResultsErrorState(
                    type: state.errorType,
                    onRetry: () => _request(_period),
                    onReconnect: () => context.read<AuthBloc>().add(
                      const AuthLogoutRequested(),
                    ),
                    onContactAdmin: _contactAdmin,
                  ),
                StudentAttendanceSummaryStatus.success
                    when state.summary != null =>
                  _buildSuccess(context, state.summary!),
                _ => const PresenceSummarySkeleton(),
              };

              return AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.outCurve,
                switchOutCurve: AppMotion.inCurve,
                child: KeyedSubtree(
                  key: ValueKey('${state.status.name}-${_period.name}'),
                  child: child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, StudentAttendanceSummary summary) {
    final l10n = AppLocalizations.of(context)!;
    final vm = PresenceSummaryViewData(summary);

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
        PresenceSummaryCard(data: vm, rangeLabel: _rangeLabel(l10n, summary)),
        const SizedBox(height: AppDimensions.spacingM),
        if (vm.isPerfect)
          const PresencePerfectCard()
        else
          PresenceAbsenceList(data: vm),
      ],
    );
  }

  String _rangeLabel(AppLocalizations l10n, StudentAttendanceSummary s) =>
      switch (s.period) {
        StatsPeriod.year => l10n.presenceRangeYear(s.academicYearName),
        StatsPeriod.month => l10n.presenceRangeMonth(s.windowStart),
        StatsPeriod.week => l10n.presenceRangeWeek(s.windowStart),
      };
}
