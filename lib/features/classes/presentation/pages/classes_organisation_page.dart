import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_page_header.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_search_form.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_results.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_invitation_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_student_table.dart';
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

    return FinancePageBackground(
      child: MultiBlocListener(
        listeners: [
          BlocListener<ClassroomBloc, ClassroomState>(
            listenWhen: _listenDistributionStatus,
              listener: (context, state) {
                if (state.distributionStatus == ClassroomStatus.success) {
                  AppSnackBar.showSuccess(
                    context,
                    l10n.classesOrganisationDistributionSuccess,
                  );
                  final distributedLevel = _lastDistributionLevel;
                  if (distributedLevel != null) {
                    // Patch le bootstrap local : splitIntoClassrooms → true
                    context.read<BootstrapCurrentYearBloc>().add(
                      BootstrapContextSchoolLevelSplitPatched(
                        schoolLevelId: distributedLevel.schoolLevelId,
                        key: AppConstants.bootstrapPayloadKey,
                      ),
                    );
                    // Recherche immédiate avec le niveau patché
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
                  _mapClassroomErrorToMessage(l10n, state.distributionErrorType),
                );
              }
            },
          ),
          BlocListener<ClassroomBloc, ClassroomState>(
            listenWhen: _listenReassignStatus,
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
                  _mapClassroomErrorToMessage(l10n, state.reassignErrorType),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
          buildWhen: _buildWhenBootstrapChanges,
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

            final options = _buildAcademicOptions(
              bootstrapState.bootstrap?.schoolLevelGroups ?? const [],
            );

            final isSplit = _lastRequest?.selectedLevel?.splitIntoClassrooms ?? false;

            return AnimatedSwitcher(
              duration: AppMotion.standard,
              switchInCurve: AppMotion.outCurve,
              switchOutCurve: AppMotion.inCurve,
              child: Column(
                key: ValueKey<String>('classes-organisation-$isSplit'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ClassesOrganisationPageHeader(),
                  const SizedBox(height: AppDimensions.spacingM),
                  BlocBuilder<ClassroomBloc, ClassroomState>(
                    buildWhen: _buildWhenSearchFormChanges,
                    builder: (context, classroomState) {
                      return BlocBuilder<EnrollmentBloc, EnrollmentState>(
                        buildWhen: (previous, current) =>
                            previous.summariesStatus != current.summariesStatus,
                        builder: (context, enrollmentState) {
                          return ClassesOrganisationSearchForm(
                            options: options,
                            isSearching:
                                _isSearching(classroomState, enrollmentState),
                            isDistributing: classroomState.distributionStatus ==
                                ClassroomStatus.loading,
                            onSearch: _handleSearch,
                            onDistributionRequested: _handleDistributionRequested,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.classesInfoBannerSurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.sectionCardRadius),
                      border: Border.all(color: AppColors.classesInfoBannerBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSplit
                              ? Icons.grid_view_rounded
                              : Icons.list_alt_rounded,
                          size: AppDimensions.detailMiniIconSize,
                          color: AppColors.indigo,
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Expanded(
                          child: Text(
                            isSplit
                                ? l10n.classesOrganisationSplitInfo
                                : l10n.classesOrganisationNonSplitInfo,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  BlocBuilder<ClassroomBloc, ClassroomState>(
                    buildWhen: (previous, current) =>
                        previous.membersStatus != current.membersStatus ||
                        previous.membersLoadingCount != current.membersLoadingCount,
                    builder: (context, classroomState) {
                      final shouldShow = isSplit &&
                          classroomState.membersStatus == ClassroomStatus.loading &&
                          classroomState.membersLoadingCount > 0;

                      return AnimatedSwitcher(
                        duration: AppMotion.fast,
                        switchInCurve: AppMotion.outCurve,
                        switchOutCurve: AppMotion.inCurve,
                        child: shouldShow
                            ? Padding(
                                key: const ValueKey('classes-loading-classrooms'),
                                padding: const EdgeInsets.only(
                                  bottom: AppDimensions.spacingS,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: AppDimensions.detailMiniIconSize,
                                      height: AppDimensions.detailMiniIconSize,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: AppDimensions.spacingS),
                                    Expanded(
                                      child: Text(
                                        l10n.classesOrganisationLoadingClassroomsCount(
                                          classroomState.membersLoadingCount,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                  AnimatedSwitcher(
                    duration: AppMotion.standard,
                    switchInCurve: AppMotion.outCurve,
                    switchOutCurve: AppMotion.inCurve,
                    child: KeyedSubtree(
                      key: ValueKey('classes-results-$isSplit'),
                      child: _buildResultsSection(isSplit: isSplit),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsSection({required bool isSplit}) {
    final request = _lastRequest;
    if (request == null) {
      return const FacturationSearchInvitationCard();
    }

    if (!isSplit) {
      return FacturationStudentTable(onViewRequested: _onViewStudentRequested);
    }

    return BlocBuilder<ClassroomBloc, ClassroomState>(
      buildWhen: _buildWhenClassroomResultsChange,
      builder: (context, classroomState) {
        final l10n = AppLocalizations.of(context)!;
        return ClassesOrganisationSplitResults(
          classrooms: classroomState.classrooms,
          membersByClassroom: classroomState.membersByClassroom,
          isLoading: classroomState.status == ClassroomStatus.loading ||
              classroomState.membersStatus == ClassroomStatus.loading,
          isReassigning: classroomState.reassignStatus == ClassroomStatus.loading,
          reassigningMemberId: classroomState.reassigningMemberId,
          isFailure: classroomState.status == ClassroomStatus.failure ||
              classroomState.membersStatus == ClassroomStatus.failure,
          errorMessage: _mapClassroomErrorToMessage(
            l10n,
            classroomState.membersErrorType,
          ),
          onTransferTap: _handleReassignTap,
        );
      },
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

    await _showReassignDialog(
      intent: intent,
      options: availableTargets,
    );
  }

  Future<void> _showReassignDialog({
    required ClassroomMemberReassignIntent intent,
    required List<BootstrapClassroom> options,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final classroomBloc = context.read<ClassroomBloc>();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? selectedTargetId = options.first.id;
        return BlocProvider<ClassroomBloc>.value(
          value: classroomBloc,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return BlocConsumer<ClassroomBloc, ClassroomState>(
              listenWhen: (previous, current) =>
                  previous.reassignStatus != current.reassignStatus,
              listener: (context, state) {
                if (state.reassignStatus == ClassroomStatus.success ||
                    state.reassignStatus == ClassroomStatus.failure) {
                  Navigator.of(dialogContext).pop();
                }
              },
              buildWhen: (previous, current) =>
                  previous.reassignStatus != current.reassignStatus,
              builder: (context, state) {
                final isLoading = state.reassignStatus == ClassroomStatus.loading;

                return PopScope(
                  canPop: !isLoading,
                  child: AlertDialog(
                    title: Text(l10n.classesOrganisationTransferDialogTitle),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.classesOrganisationTransferDialogMessage(
                            intent.studentDisplayName,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTargetId,
                          isExpanded: true,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: l10n.classesOrganisationTransferTargetLabel,
                            floatingLabelStyle: const TextStyle(
                              color: AppColors.classesFocusRing,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.spacingS),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.spacingS),
                              borderSide: const BorderSide(
                                color: AppColors.classesFocusRing,
                                width: 1.6,
                              ),
                            ),
                          ),
                          items: options
                              .map(
                                (classroom) => DropdownMenuItem<String>(
                                  value: classroom.id,
                                  child: Text(classroom.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setDialogState(() => selectedTargetId = value);
                                },
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: AppDimensions.spacingS),
                          Text(
                            l10n.classesOrganisationTransferInProgress,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            isLoading ? null : () => Navigator.of(dialogContext).pop(),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton.icon(
                        onPressed: isLoading || selectedTargetId == null
                            ? null
                            : () {
                                context.read<ClassroomBloc>().add(
                                  ClassroomMemberReassignRequested(
                                    classroomId: intent.classroomId,
                                    classroomMemberId: intent.classroomMemberId,
                                    targetClassroomId: selectedTargetId!,
                                  ),
                                );
                              },
                        icon: isLoading
                            ? const SizedBox(
                                width: AppDimensions.detailMiniIconSize,
                                height: AppDimensions.detailMiniIconSize,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.swap_horiz),
                        label: Text(l10n.classesOrganisationTransferAction),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(
                            150,
                            AppDimensions.minTouchTarget,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              );
            },
          ),
        );
      },
    );
  }

  List<ClassesOrganisationLevelOption> _buildAcademicOptions(
    List<BootstrapSchoolLevelGroupBundle> bundles,
  ) {
    final options = <ClassesOrganisationLevelOption>[];
    final seen = <String>{};

    final sortedGroups = [...bundles]
      ..sort((a, b) => a.schoolLevelGroup.displayOrder
          .compareTo(b.schoolLevelGroup.displayOrder));

    for (final groupBundle in sortedGroups) {
      final sortedLevels = [...groupBundle.schoolLevels]
        ..sort((a, b) =>
            a.schoolLevel.displayOrder.compareTo(b.schoolLevel.displayOrder));

      for (final levelBundle in sortedLevels) {
        final option = ClassesOrganisationLevelOption(
          schoolLevelGroupId: groupBundle.schoolLevelGroup.id,
          schoolLevelId: levelBundle.schoolLevel.id,
          label: '${groupBundle.schoolLevelGroup.name} - ${levelBundle.schoolLevel.name}',
          splitIntoClassrooms: levelBundle.schoolLevel.splitIntoClassrooms,
          classrooms: levelBundle.classrooms,
        );

        if (seen.add(option.key)) {
          options.add(option);
        }
      }
    }

    return options;
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
    final l10n = AppLocalizations.of(context)!;
    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.classesOrganisationDistributionConfirmTitle),
        content: Text(l10n.classesOrganisationDistributionConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
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

  String _mapClassroomErrorToMessage(
    AppLocalizations l10n,
    ClassroomErrorType errorType,
  ) {
    return switch (errorType) {
      ClassroomErrorType.network => l10n.classesOrganisationErrorNetwork,
      ClassroomErrorType.notFound => l10n.classesOrganisationErrorNotFound,
      ClassroomErrorType.validation => l10n.classesOrganisationErrorValidation,
      ClassroomErrorType.unauthorized => l10n.classesOrganisationErrorUnauthorized,
      ClassroomErrorType.invalidCredentials =>
        l10n.classesOrganisationErrorInvalidCredentials,
      ClassroomErrorType.server => l10n.classesOrganisationErrorServer,
      ClassroomErrorType.storage => l10n.classesOrganisationErrorStorage,
      ClassroomErrorType.auth => l10n.classesOrganisationErrorAuth,
      _ => l10n.classesOrganisationErrorUnknown,
    };
  }

  bool _isSearching(
    ClassroomState classroomState,
    EnrollmentState enrollmentState,
  ) {
    final split = _lastRequest?.selectedLevel?.splitIntoClassrooms ?? false;
    if (split) {
      return classroomState.status == ClassroomStatus.loading ||
          classroomState.membersStatus == ClassroomStatus.loading;
    }
    // Niveau non encore distribué : affichage liste élèves inscrits
    return enrollmentState.summariesStatus == EnrollmentLoadStatus.loading;
  }

  static bool _listenDistributionStatus(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.distributionStatus != current.distributionStatus;
  }

  static bool _listenReassignStatus(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.reassignStatus != current.reassignStatus;
  }

  static bool _buildWhenBootstrapChanges(
    BootstrapContextState previous,
    BootstrapContextState current,
  ) {
    return previous.status != current.status ||
        previous.bootstrap != current.bootstrap;
  }

  static bool _buildWhenSearchFormChanges(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.status != current.status ||
        previous.membersStatus != current.membersStatus ||
        previous.distributionStatus != current.distributionStatus;
  }

  static bool _buildWhenClassroomResultsChange(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.status != current.status ||
        previous.classrooms != current.classrooms ||
        previous.membersStatus != current.membersStatus ||
        previous.membersByClassroom != current.membersByClassroom ||
        previous.membersErrorType != current.membersErrorType;
  }
}
