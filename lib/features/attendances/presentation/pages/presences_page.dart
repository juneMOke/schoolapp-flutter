import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_page_helpers.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_page_content.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PresencesPage extends StatefulWidget {
  const PresencesPage({super.key});

  @override
  State<PresencesPage> createState() => _PresencesPageState();
}

class _PresencesPageState extends State<PresencesPage> {
  AttendanceSearchRequest? _lastRequest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      // L'erreur de chargement est desormais affichee en place via l'anatomie
      // d'erreur partagee (AttendanceResultsErrorState) : plus de snackbar
      // redondant sur echec de fetch.
      child: BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
        // Transition de STATUT (pas égalité de valeur) : un contexte qui se
        // résout à une valeur identique (rien n'a changé au référentiel
        // niveaux/cycles) doit quand même redéclencher la lecture des classes,
        // sourcées séparément dans `ClassroomOfflineBloc` (revue adversariale —
        // aligné sur `ClassesListPageHelpers`/`classes_list_page.dart`).
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status == AcademicYearContextLoadStatus.success,
        listener: (context, academicYearState) {
          context.read<ClassroomOfflineBloc>().add(
            OfflineClassroomsRequested(
              academicYearId: academicYearState.context!.academicYear.id,
            ),
          );
        },
        child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
          buildWhen: AttendancePageHelpers.buildWhenAcademicYearContextChanges,
          builder: (context, academicYearState) {
            if (academicYearState.status ==
                    AcademicYearContextLoadStatus.loading ||
                academicYearState.status ==
                    AcademicYearContextLoadStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (academicYearState.status !=
                    AcademicYearContextLoadStatus.success ||
                academicYearState.context == null) {
              return BootstrapContextError(
                onLogout: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
              );
            }

            final classrooms = context
                .watch<ClassroomOfflineBloc>()
                .state
                .classrooms;
            final options = AttendancePageHelpers.buildCycleOptions(
              academicYearState.context!.schoolLevelGroups,
              classrooms,
            );

            return AttendancePageContent(
              options: options,
              lastRequest: _lastRequest,
              onSearch: _handleSearch,
              onRetry: _retryLastSearch,
            );
          },
        ),
      ),
    );
  }

  void _handleSearch(AttendanceSearchRequest request) async {
    final attendanceState = context.read<AttendanceBloc>().state;
    if (attendanceState.saveStatus == AttendanceStatus.loading) {
      return;
    }

    if (attendanceState.hasUnsavedChanges) {
      final confirmed = await _confirmDiscardUnsavedChanges();
      if (!mounted || !confirmed) {
        return;
      }

      context.read<AttendanceBloc>().add(const AttendanceResetRequested());
    }

    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    setState(() => _lastRequest = request);

    context.read<AttendanceBloc>().add(
      AttendanceFetchRequested(
        classroomId: request.selectedClassroom.id,
        date: request.date,
        academicYearId: academicYearId,
      ),
    );
  }

  void _retryLastSearch() {
    final request = _lastRequest;
    if (request == null) {
      return;
    }

    _handleSearch(request);
  }

  Future<bool> _confirmDiscardUnsavedChanges() async {
    final l10n = AppLocalizations.of(context)!;

    return showAppConfirmationDialog(
      context: context,
      title: l10n.attendanceUnsavedChangesTitle,
      message: l10n.attendanceUnsavedChangesMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
  }
}
