import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_export_helper.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_page_content.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListPage extends StatefulWidget {
  const ClassesListPage({super.key});

  @override
  State<ClassesListPage> createState() => _ClassesListPageState();
}

class _ClassesListPageState extends State<ClassesListPage> {
  ClassesListSearchRequest? _lastRequest;

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
          BlocListener<EnrollmentBloc, EnrollmentState>(
            listenWhen: ClassesListPageHelpers.listenWhenEnrollmentStatusChanges,
            listener: (context, state) {
              if (state.summariesStatus == EnrollmentLoadStatus.failure) {
                AppSnackBar.showError(
                  context,
                  state.errorMessage ?? l10n.classesOrganisationErrorUnknown,
                );
              }
            },
          ),
          BlocListener<ClassroomBloc, ClassroomState>(
            listenWhen: ClassesListPageHelpers.listenWhenClassroomMembersStatusChanges,
            listener: (context, state) {
              if (state.membersStatus == ClassroomStatus.failure) {
                AppSnackBar.showError(
                  context,
                  ClassesListPageHelpers.mapClassroomErrorToMessage(
                    l10n,
                    state.membersErrorType,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
          buildWhen: ClassesListPageHelpers.buildWhenBootstrapChanges,
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

            final options = ClassesListPageHelpers.buildCycleOptions(
              bootstrapState.bootstrap?.schoolLevelGroups ?? const [],
            );

            return ClassesListPageContent(
              options: options,
              lastRequest: _lastRequest,
              onSearch: _handleSearch,
              onExportPressed: _handleExport,
              onEnrollmentViewRequested: _onEnrollmentViewRequested,
              onClassroomMemberViewRequested: _onClassroomMemberViewRequested,
            );
          },
        ),
      ),
    );
  }

  void _handleSearch(ClassesListSearchRequest request) {
    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    setState(() => _lastRequest = request);

    if (request.targetsClassroom) {
      context.read<EnrollmentBloc>().add(const EnrollmentResetRequested());
      context.read<ClassroomBloc>().add(
            ClassroomMembersRequested(
              classroomId: request.selectedClassroom!.id,
              academicYearId: academicYearId,
            ),
          );
      return;
    }

    context.read<ClassroomBloc>().add(const ClassroomResetRequested());
    context.read<EnrollmentBloc>().add(
          EnrollmentSummariesByAcademicInfoRequested(
            firstName: request.firstName,
            lastName: request.lastName,
            surname: request.surname,
            schoolLevelGroupId: request.selectedLevel.schoolLevelGroupId,
            schoolLevelId: request.selectedLevel.schoolLevelId,
          ),
        );
  }

  Future<void> _handleExport() async {
    final l10n = AppLocalizations.of(context)!;
    final request = _lastRequest;
    if (request == null) {
      AppSnackBar.showWarning(context, l10n.classesListExportNothingToExport);
      return;
    }

    try {
      final csv = request.targetsClassroom
          ? _buildClassroomExport(l10n, request)
          : _buildEnrollmentExport(l10n);

      if (csv == null || csv.trim().isEmpty) {
        AppSnackBar.showWarning(context, l10n.classesListExportNothingToExport);
        return;
      }

      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, l10n.classesListExportSuccess);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, l10n.classesListExportFailed);
    }
  }

  String? _buildEnrollmentExport(AppLocalizations l10n) {
    final enrollmentState = context.read<EnrollmentBloc>().state;
    if (enrollmentState.summariesStatus != EnrollmentLoadStatus.success ||
        enrollmentState.summaries.isEmpty) {
      return null;
    }

    return ClassesListExportHelper.buildEnrollmentCsv(
      l10n: l10n,
      summaries: enrollmentState.summaries,
    );
  }

  String? _buildClassroomExport(
    AppLocalizations l10n,
    ClassesListSearchRequest request,
  ) {
    final classroomState = context.read<ClassroomBloc>().state;
    if (classroomState.membersStatus != ClassroomStatus.success) {
      return null;
    }

    final members = ClassesListPageHelpers.filterMembers(
      classroomState.members,
      request,
    );
    if (members.isEmpty) {
      return null;
    }

    return ClassesListExportHelper.buildClassroomMembersCsv(
      l10n: l10n,
      members: members,
    );
  }

  void _onEnrollmentViewRequested(EnrollmentSummary _) {
    final l10n = AppLocalizations.of(context)!;
    AppSnackBar.showInfo(context, l10n.classesListStudentDetailSoon);
  }

  void _onClassroomMemberViewRequested(ClassroomMember _) {
    final l10n = AppLocalizations.of(context)!;
    AppSnackBar.showInfo(context, l10n.classesListStudentDetailSoon);
  }
}
