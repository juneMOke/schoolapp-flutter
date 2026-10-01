import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_failure_mapper.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_picker_options.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_picker_button.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_picker_dialog.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_presence_no_class.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_presence_notices.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_register_tab.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';

/// Disciplines ▸ Présences — l'appel d'une classe : le registre du jour.
///
/// Lecture 100 % locale ; les touches vont au brouillon de la tablette, et
/// l'appel entier part à la validation (même transport que l'appel d'avant
/// la v2 : une session par classe et par jour).
class ClassPresencePage extends StatelessWidget {
  const ClassPresencePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ClassPresenceCubit>(
    create: (_) => getIt<ClassPresenceCubit>(),
    child: const ClassPresenceScreen(),
  );
}

class ClassPresenceScreen extends StatefulWidget {
  const ClassPresenceScreen({super.key});

  @override
  State<ClassPresenceScreen> createState() => _ClassPresenceScreenState();
}

class _ClassPresenceScreenState extends State<ClassPresenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final years = context.read<AcademicYearContextBloc>();
      years.add(const AcademicYearContextRequested());
      // Un contexte déjà résolu ne repasse pas par le listener.
      _onAcademicYear(years.state);
    });
  }

  void _onAcademicYear(AcademicYearContextState state) {
    final yearContext = state.context;
    if (state.status != AcademicYearContextLoadStatus.success ||
        yearContext == null) {
      return;
    }
    final year = yearContext.academicYear;
    context.read<ClassroomOfflineBloc>().add(
      OfflineClassroomsRequested(academicYearId: year.id),
    );
    context.read<ClassPresenceCubit>().setAcademicYear(
      year.id,
      SchoolYearBounds(
        start: year.startDate == null
            ? null
            : SchoolDayCalendar.dayOf(year.startDate!),
        end: year.endDate == null
            ? null
            : SchoolDayCalendar.dayOf(year.endDate!),
      ),
    );
  }

  Future<void> _pickClass(List<ClassPickerCycle> cycles) async {
    final cubit = context.read<ClassPresenceCubit>();
    final picked = await EteeloFormDialog.show<ClassPresenceClassroom>(
      context,
      ClassPickerDialog(cycles: cycles, selectedId: cubit.state.classroom?.id),
    );
    if (picked == null || !mounted) return;
    await cubit.selectClassroom(picked);
  }

  @override
  Widget build(BuildContext context) => AppPageBackground(
    child: BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
      // Transition de statut : un contexte qui se résout à l'identique doit
      // quand même relire les classes.
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _onAcademicYear(state),
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.context != current.context,
        builder: (context, years) {
          if (years.status == AcademicYearContextLoadStatus.initial ||
              years.status == AcademicYearContextLoadStatus.loading) {
            return const EteeloListSkeleton(rowCount: 8);
          }
          final yearContext = years.context;
          if (years.status != AcademicYearContextLoadStatus.success ||
              yearContext == null) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }
          final cycles = buildClassPickerCycles(
            yearContext.schoolLevelGroups,
            context.watch<ClassroomOfflineBloc>().state.classrooms,
          );
          return _Body(cycles: cycles, onPick: () => _pickClass(cycles));
        },
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  final List<ClassPickerCycle> cycles;
  final VoidCallback onPick;

  const _Body({required this.cycles, required this.onPick});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ClassPresenceCubit, ClassPresenceState>(
        listenWhen: (previous, current) =>
            current.notice != null && previous.notice != current.notice,
        listener: (context, state) =>
            showClassPresenceNotice(context, state.notice!),
        buildWhen: (previous, current) =>
            previous.copyWith(notice: current.notice) != current,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ClassPickerButton(
                classroom: state.classroom,
                onTap: cycles.isEmpty ? null : onPick,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _content(context, state),
          ],
        ),
      );

  Widget _content(BuildContext context, ClassPresenceState state) {
    final cubit = context.read<ClassPresenceCubit>();
    switch (state.load) {
      case ClassPresenceLoad.noClass:
        return ClassPresenceNoClass(
          hasClasses: cycles.isNotEmpty,
          onPick: onPick,
        );
      case ClassPresenceLoad.loading:
        return const EteeloListSkeleton(rowCount: 8);
      case ClassPresenceLoad.failure:
        final classroom = state.classroom;
        return AttendanceResultsErrorState(
          type: mapFailureToAttendanceErrorType(state.failure!),
          onRetry: classroom == null
              ? null
              : () => unawaited(cubit.selectClassroom(classroom)),
          onReconnect: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
        );
      case ClassPresenceLoad.ready:
        return ClassRegisterTab(
          state: state,
          register: state.register!,
          classroomName: state.classroom!.name,
        );
    }
  }
}
