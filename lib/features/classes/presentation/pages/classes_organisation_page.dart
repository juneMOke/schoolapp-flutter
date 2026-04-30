import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_distribution_confirm_dialog.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_page_content.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_reassign_dialog.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationPage extends StatefulWidget {
  const ClassesOrganisationPage({super.key});

  @override
  State<ClassesOrganisationPage> createState() => _ClassesOrganisationPageState();
}

class _ClassesOrganisationPageState extends State<ClassesOrganisationPage> {
  ClassesOrganisationSearchRequest? _lastRequest;
  ClassesOrganisationLevelOption? _lastDistributionLevel;

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
          BlocListener<ClassroomBloc, ClassroomState>(
            listenWhen: ClassesOrganisationPageHelpers.listenDistributionStatus,
            listener: (context, state) {
              if (state.distributionStatus == ClassroomStatus.success) {
                AppSnackBar.showSuccess(
                  context,
                  l10n.classesOrganisationDistributionSuccess,
                );
                final distributedLevel = _lastDistributionLevel;
                if (distributedLevel != null) {
                  context.read<BootstrapCurrentYearBloc>().add(
                    BootstrapContextSchoolLevelSplitPatched(
                      schoolLevelId: distributedLevel.schoolLevelId,
                      key: AppConstants.bootstrapPayloadKey,
                    ),
                  );
                  _handleSearch(
                    ClassesOrganisationSearchRequest(
                      firstName: '',
                      lastName: '',
                      surname: '',
                      selectedLevel: distributedLevel.copyWith(
                        splitIntoClassrooms: true,
                      ),
                    ),
                  );
                } else {
                  final request = _lastRequest;
                  if (request != null) {
                    _handleSearch(request);
                  }
                }
              }
              if (state.distributionStatus == ClassroomStatus.failure) {
                AppSnackBar.showError(
                  context,
                  ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(
                    l10n,
                    state.distributionErrorType,
                  ),
                );
              }
            },
          ),
          BlocListener<ClassroomBloc, ClassroomState>(
            listenWhen: ClassesOrganisationPageHelpers.listenReassignStatus,
            listener: (context, state) {
              if (state.reassignStatus == ClassroomStatus.success) {
                AppSnackBar.showSuccess(
                  context,
                  l10n.classesOrganisationTransferSuccess,
                );
                final request = _lastRequest;
                if (request != null) {
                  _handleSearch(request);
                }
              }
              if (state.reassignStatus == ClassroomStatus.failure) {
                AppSnackBar.showError(
                  context,
                  ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(
                    l10n,
                    state.reassignErrorType,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
          buildWhen: ClassesOrganisationPageHelpers.buildWhenBootstrapChanges,
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

            final options = ClassesOrganisationPageHelpers.buildAcademicOptions(
              bootstrapState.bootstrap?.schoolLevelGroups ?? const [],
            );

            return ClassesOrganisationPageContent(
              options: options,
              lastRequest: _lastRequest,
              onSearch: _handleSearch,
              onDistributionRequested: _handleDistributionRequested,
              onViewRequested: _onViewStudentRequested,
              onTransferTap: _handleReassignTap,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleReassignTap(ClassroomMemberReassignIntent intent) async {
    final l10n = AppLocalizations.of(context)!;
    final classroomState = context.read<ClassroomBloc>().state;
    if (classroomState.reassignStatus == ClassroomStatus.loading) {
      AppSnackBar.showInfo(context, l10n.classesOrganisationTransferInProgress);
      return;
    }

    final selectedLevel = _lastRequest?.selectedLevel;
    if (selectedLevel == null) {
      return;
    }

    final availableTargets = selectedLevel.classrooms
        .where((classroom) => classroom.id != intent.classroomId)
        .toList(growable: false);

    if (availableTargets.isEmpty) {
      AppSnackBar.showWarning(
        context,
        l10n.classesOrganisationTransferNoTarget,
      );
      return;
    }

    await showClassesOrganisationReassignDialog(
      context: context,
      intent: intent,
      options: availableTargets,
    );
  }

  void _handleSearch(ClassesOrganisationSearchRequest request) {
    final level = request.selectedLevel;
    if (level == null) {
      return;
    }

    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    setState(() {
      _lastRequest = request;
    });

    if (level.splitIntoClassrooms) {
      context.read<ClassroomBloc>().add(
            ClassroomRequested(
              schoolLevelGroupId: level.schoolLevelGroupId,
              schoolLevelId: level.schoolLevelId,
              academicYearId: academicYearId,
            ),
          );

      final classroomIds = level.classrooms
          .map((classroom) => classroom.id)
          .toList(growable: false);

      context.read<ClassroomBloc>().add(
            ClassroomMembersBatchRequested(
              classroomIds: classroomIds,
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
            schoolLevelGroupId: level.schoolLevelGroupId,
            schoolLevelId: level.schoolLevelId,
          ),
        );
  }

  Future<void> _handleDistributionRequested(
    ClassroomDistributionCriterion criterion,
    ClassesOrganisationLevelOption level,
  ) async {
    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    final confirmed = await showClassesOrganisationDistributionConfirmDialog(
      context,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _lastDistributionLevel = level;
    });

    context.read<ClassroomBloc>().add(
          ClassroomDistributionRequested(
            academicYearId: academicYearId,
            schoolLevelGroupId: level.schoolLevelGroupId,
            schoolLevelId: level.schoolLevelId,
            distributionCriterion: criterion,
          ),
        );
  }

  void _onViewStudentRequested(Object summary, String levelId) {
    final l10n = AppLocalizations.of(context)!;
    AppSnackBar.showInfo(context, l10n.classesOrganisationStudentDetailSoon);
  }
}