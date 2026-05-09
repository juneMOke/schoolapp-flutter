import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_page_helpers.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_page_content.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
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

      context.read<BootstrapCurrentYearBloc>().add(
        const BootstrapContextLocalRequested(key: AppConstants.bootstrapPayloadKey),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      child: MultiBlocListener(
        listeners: [
          BlocListener<AttendanceBloc, AttendanceState>(
            listenWhen: AttendancePageHelpers.listenWhenFetchFailure,
            listener: (context, state) {
              if (state.fetchStatus != AttendanceStatus.failure) {
                return;
              }

              AppSnackBar.showError(
                context,
                AttendancePageHelpers.mapAttendanceErrorToMessage(
                  l10n,
                  state.fetchErrorType,
                ),
              );
            },
          ),
          BlocListener<AttendanceBloc, AttendanceState>(
            listenWhen: AttendancePageHelpers.listenWhenSaveStatusChanges,
            listener: (context, state) {
              if (state.saveStatus == AttendanceStatus.success) {
                AppSnackBar.showSuccess(context, l10n.attendanceSaveSuccess);
                context.read<AttendanceBloc>().add(
                  const AttendanceSaveStatusResetRequested(),
                );
              }

              if (state.saveStatus == AttendanceStatus.failure) {
                AppSnackBar.showError(
                  context,
                  AttendancePageHelpers.mapAttendanceErrorToMessage(
                    l10n,
                    state.saveErrorType,
                  ),
                );
                context.read<AttendanceBloc>().add(
                  const AttendanceSaveStatusResetRequested(),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
          buildWhen: AttendancePageHelpers.buildWhenBootstrapChanges,
          builder: (context, bootstrapState) {
            if (bootstrapState.status == BootstrapContextLoadStatus.loading ||
                bootstrapState.status == BootstrapContextLoadStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (bootstrapState.status != BootstrapContextLoadStatus.success ||
                bootstrapState.bootstrap == null) {
              return BootstrapContextError(
                onLogout: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
              );
            }

            final options = AttendancePageHelpers.buildCycleOptions(
              bootstrapState.bootstrap?.schoolLevelGroups ?? const [],
            );

            return AttendancePageContent(
              options: options,
              lastRequest: _lastRequest,
              onSearch: _handleSearch,
              onExportPressed: _handleExportPressed,
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

    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
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

  void _handleExportPressed() {
    final l10n = AppLocalizations.of(context)!;
    AppSnackBar.showInfo(context, l10n.attendanceExportSoon);
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
