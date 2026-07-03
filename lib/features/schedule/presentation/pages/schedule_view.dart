import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_bloc.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_event.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_state.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';
import 'package:school_app_flutter/features/schedule/presentation/pages/schedule_ready_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_timetable_skeleton.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_toolbar.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_view_mode.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/states/schedule_results_empty_state.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/states/schedule_results_error_state.dart';

/// Corps de l'écran emploi du temps une fois l'année courante résolue : barre
/// supérieure (toujours visible) + zone d'état pilotée par le [TimetableBloc]
/// (squelette / grille ou vue Jour / vide / erreur). La bascule Semaine/Jour et
/// le jour sélectionné sont un état local, indépendant de la machine à états.
class ScheduleView extends StatefulWidget {
  final String academicYearId;

  /// Ouvre le détail d'un cours (`null` → séances non interactives).
  final void Function(CoursDetailArgs args)? onOpenCourse;

  const ScheduleView({
    super.key,
    required this.academicYearId,
    this.onOpenCourse,
  });

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  /// `null` = aucun choix explicite → mode par défaut résolu selon la largeur
  /// (Jour sur téléphone / petit écran, Semaine sinon). Dès que l'utilisateur
  /// bascule, `_mode` est fixé et prime sur le défaut.
  ScheduleViewMode? _mode;
  Weekday? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Charge une seule fois : au retour du détail, le BLoC (vivant dans le
    // scope) est déjà chargé → pas de re-fetch ni de clignotement.
    if (context.read<TimetableBloc>().state.status == TimetableStatus.initial) {
      context.read<TimetableBloc>().add(
        TimetableRequested(academicYearId: widget.academicYearId),
      );
    }
  }

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
    if (!mounted) return; // garde mounted après await (règle non-négociable #8)
  }

  @override
  Widget build(BuildContext context) {
    // Choix explicite s'il existe, sinon défaut selon la largeur disponible.
    final mode =
        _mode ?? defaultScheduleViewMode(MediaQuery.sizeOf(context).width);
    return BlocBuilder<TimetableBloc, TimetableState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.timetable != curr.timetable ||
          prev.errorType != curr.errorType,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScheduleToolbar(
              mode: mode,
              onModeChanged: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.outCurve,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.outCurve,
                switchOutCurve: AppMotion.inCurve,
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    '${state.status.name}-${state.errorType.name}',
                  ),
                  child: _buildBody(context, state, mode),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    TimetableState state,
    ScheduleViewMode mode,
  ) {
    return switch (state.status) {
      TimetableStatus.loading => const ScheduleTimetableSkeleton(),
      TimetableStatus.success => _buildReady(state.timetable, mode),
      TimetableStatus.failure => ScheduleResultsErrorState(
        type: state.errorType,
        onRetry: () => context.read<TimetableBloc>().add(
          TimetableRequested(academicYearId: widget.academicYearId),
        ),
        onReconnect: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
        onContactAdmin: _contactAdmin,
      ),
      TimetableStatus.initial => const SizedBox.shrink(),
    };
  }

  Widget _buildReady(WeeklyTimetable? timetable, ScheduleViewMode mode) {
    if (timetable == null || ScheduleTimeFormat.sessionCount(timetable) == 0) {
      return const ScheduleResultsEmptyState();
    }

    final palette = ScheduleClassPalette.fromTimetable(timetable);
    final today = ScheduleTimeFormat.todayWeekday();
    final onOpenCell = widget.onOpenCourse == null
        ? null
        : (TimetableCell cell) => _openCell(cell, palette);

    return ScheduleReadyView(
      timetable: timetable,
      palette: palette,
      today: today,
      mode: mode,
      selectedDay: _effectiveDay(timetable.days, today),
      onDaySelected: (day) => setState(() => _selectedDay = day),
      onOpenCell: onOpenCell,
    );
  }

  /// Jour sélectionné effectif : le choix explicite s'il est valide, sinon le
  /// jour courant s'il est dans la grille, sinon le premier jour disponible.
  Weekday _effectiveDay(List<Weekday> days, Weekday? today) {
    final selected = _selectedDay;
    if (selected != null && days.contains(selected)) {
      return selected;
    }
    if (today != null && days.contains(today)) {
      return today;
    }
    return days.isNotEmpty ? days.first : Weekday.mon;
  }

  void _openCell(TimetableCell cell, ScheduleClassPalette palette) {
    widget.onOpenCourse?.call(
      CoursDetailArgs(
        coursId: cell.coursId,
        brancheNom: cell.subjectLabel,
        classroomName: cell.classroomLabel,
        visual: palette.visualForClassroom(cell.classroomId),
      ),
    );
  }
}
