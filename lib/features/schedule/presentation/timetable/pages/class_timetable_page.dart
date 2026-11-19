import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/class_week_builder.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_picker.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_summary.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_day_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_view_mode.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/states/school_calendar_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Agenda & Horaires ▸ Emploi du temps : l'emploi du temps publié d'une classe,
/// en semaine ou à la journée. L'adresse retient la classe, la vue et le jour
/// (EDT fiche, A1).
class ClassTimetablePage extends StatelessWidget {
  const ClassTimetablePage({super.key});

  static const classParam = 'classe';
  static const modeParam = 'vue';
  static const dayParam = 'jour';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.instance<ClassTimetableCubit>()..load(pull: true),
    child: BlocBuilder<ClassTimetableCubit, ClassTimetableState>(
      builder: (context, state) {
        final cubit = context.read<ClassTimetableCubit>();
        return LocationParamsSync(
          current: {
            classParam: state.classroomId,
            modeParam: state.mode?.name,
            dayParam: state.day?.wire,
          },
          onLocation: (values) {
            unawaited(cubit.selectClass(values[classParam]));
            cubit
              ..setMode(
                ClassTimetableMode.values
                    .where((m) => m.name == values[modeParam])
                    .firstOrNull,
              )
              ..setDay(
                values[dayParam] == null
                    ? null
                    : WeekdayX.fromWire(values[dayParam]),
              );
          },
          child: AppPageBackground(
            width: PageContentWidth.wide,
            child: _Body(state: state, cubit: cubit),
          ),
        );
      },
    ),
  );
}

class _Body extends StatelessWidget {
  final ClassTimetableState state;
  final ClassTimetableCubit cubit;

  const _Body({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final header = EteeloPageHeader(
      eyebrow: l10n.classTimetableEyebrow,
      title: l10n.classTimetableTitle,
    );
    final content = switch (state.status) {
      ClassTimetableStatus.loading => EteeloListSkeleton(
        rowCount: 3,
        pillCount: 2,
        showAvatar: false,
        semanticsLabel: l10n.classTimetableLoading,
      ),
      ClassTimetableStatus.failure => SchoolCalendarErrorState(
        failure: state.failure ?? const StorageFailure(),
        onRetry: () => unawaited(cubit.load(pull: true)),
      ),
      ClassTimetableStatus.ready when state.options.isEmpty =>
        EteeloEmptyResult(
          label: l10n.classTimetableNoClassTitle,
          description: l10n.classTimetableNoClassBody,
          medallionIcon: Icons.class_outlined,
          fullWidthCard: true,
        ),
      ClassTimetableStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClassPicker(
            options: state.options,
            selectedId: state.classroomId,
            onSelected: (id) => unawaited(cubit.selectClass(id)),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ClassContent(state: state, cubit: cubit),
        ],
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.lg),
        content,
      ],
    );
  }
}

class _ClassContent extends StatelessWidget {
  final ClassTimetableState state;
  final ClassTimetableCubit cubit;

  const _ClassContent({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = state.view;
    if (state.classroomId == null) {
      return EteeloEmptyResult(
        label: l10n.classTimetablePickHint,
        medallionIcon: Icons.event_note_outlined,
        fullWidthCard: true,
      );
    }
    if (view == null) {
      return const EteeloListSkeleton(
        rowCount: 3,
        pillCount: 2,
        showAvatar: false,
      );
    }
    if (view.programme.isEmpty && view.published.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.classTimetableNoProgrammeTitle,
        description: l10n.classTimetableNoProgrammeBody(view.classroom.name),
        medallionIcon: Icons.menu_book_outlined,
        fullWidthCard: true,
      );
    }
    if (view.published.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.classTimetableEmptyTitle(view.classroom.name),
        description: l10n.classTimetableEmptyBody,
        medallionIcon: Icons.calendar_view_week_outlined,
        fullWidthCard: true,
      );
    }
    final week = ClassWeekBuilder.build(view, view.published);
    final palette = ScheduleClassPalette.byCourse(
      ClassWeekBuilder.courseVisuals(view),
    );
    final today = CurrentSession.weekdayOf(
      SchoolTime.wallClock(DateTime.now()),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final mode =
            state.mode ??
            (defaultScheduleViewMode(constraints.maxWidth) ==
                    ScheduleViewMode.day
                ? ClassTimetableMode.day
                : ClassTimetableMode.week);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassTimetableSummary(view: view, cells: view.published),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedTabFilter<ClassTimetableMode>(
                selected: mode,
                onSelected: cubit.setMode,
                options: [
                  SegmentedTabOption(
                    label: l10n.classTimetableWeek,
                    value: ClassTimetableMode.week,
                  ),
                  SegmentedTabOption(
                    label: l10n.classTimetableDay,
                    value: ClassTimetableMode.day,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (mode == ClassTimetableMode.week)
              ScheduleWeekGrid(
                timetable: week,
                palette: palette,
                today: today,
                keepSaturday: true,
              )
            else
              ScheduleDayView(
                timetable: week,
                palette: palette,
                today: today,
                selectedDay: state.day ?? today ?? Weekday.mon,
                onDaySelected: cubit.setDay,
              ),
            const SizedBox(height: AppSpacing.lg),
            ClassTimetableDistribution(view: view, cells: view.published),
          ],
        );
      },
    );
  }
}
