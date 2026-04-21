import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_controls.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/previous_academic_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/step_page_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/summary_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/target_academic_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/wizard_breadcrumb.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStepper extends StatefulWidget {
  final EnrollmentDetail enrollmentDetail;
  final EnrollmentDetailIntent detailIntent;
  final EnrollmentDetailPolicy detailPolicy;

  const EnrollmentStepper({
    super.key,
    required this.enrollmentDetail,
    required this.detailIntent,
    required this.detailPolicy,
  });

  @override
  State<EnrollmentStepper> createState() => _EnrollmentStepperState();
}

class _EnrollmentStepperState extends State<EnrollmentStepper> {
  static const int _totalSteps = 6;

  final GlobalKey<PersonalInfoStepState> _personalInfoKey =
      GlobalKey<PersonalInfoStepState>();
  final GlobalKey<AddressStepState> _addressKey = GlobalKey<AddressStepState>();
  final GlobalKey<PreviousAcademicInfoStepState> _academicInfoKey =
      GlobalKey<PreviousAcademicInfoStepState>();
  final GlobalKey<TargetAcademicInfoStepState> _academicTargetInfoKey =
      GlobalKey<TargetAcademicInfoStepState>();
  final GlobalKey<GuardianInfoStepState> _guardianInfoKey =
      GlobalKey<GuardianInfoStepState>();

  late final EnrollmentStepperFlowBloc _flowBloc;

  @override
  void initState() {
    super.initState();
    _flowBloc = EnrollmentStepperFlowBloc(
      totalSteps: _totalSteps,
      initialStepStates: _buildInitialStepStates(widget.enrollmentDetail),
    );
  }

  @override
  void didUpdateWidget(covariant EnrollmentStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enrollmentDetail != widget.enrollmentDetail) {
      _flowBloc.add(
        EnrollmentStepperStatesSynced(
          _buildInitialStepStates(widget.enrollmentDetail),
        ),
      );
    }
  }

  @override
  void dispose() {
    _flowBloc.close();
    super.dispose();
  }

  Map<int, StepFormState> _buildInitialStepStates(EnrollmentDetail detail) {
    return <int, StepFormState>{
      0: StepFormState(
        dirty: false,
        saving: false,
        valid: EnrollmentStepperStateHelper.isPersonalInfoValid(
          detail.studentDetail,
        ),
      ),
      1: StepFormState(
        dirty: false,
        saving: false,
        valid: EnrollmentStepperStateHelper.isAddressValid(
          detail.studentDetail,
        ),
      ),
      2: StepFormState(
        dirty: false,
        saving: false,
        valid: EnrollmentStepperStateHelper.isAcademicPreviousInfoValid(
          detail.enrollmentDetail,
        ),
      ),
      3: StepFormState(
        dirty: false,
        saving: false,
        valid: EnrollmentStepperStateHelper.isAcademicTargetInfoValid(
          detail.enrollmentDetail,
        ),
      ),
      4: StepFormState(
        dirty: false,
        saving: false,
        valid: EnrollmentStepperStateHelper.isGuardianInfoValid(
          detail.parentDetails,
        ),
      ),
    };
  }

  String _saveLabelForStep(AppLocalizations l10n, int step, bool savingNow) {
    return switch (step) {
      0 => savingNow ? l10n.savingPersonalInfo : l10n.savePersonalInfo,
      1 => savingNow ? l10n.savingAddress : l10n.saveAddress,
      2 => savingNow ? l10n.savingAcademicInfo : l10n.saveAcademicInfo,
      3 => savingNow ? l10n.savingAcademicInfo : l10n.saveAcademicInfo,
      4 => savingNow ? l10n.savingPersonalInfo : l10n.savePersonalInfo,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepTitles = _stepTitles(l10n);
    final stepSubtitles = _stepSubtitles(l10n);
    final steps = _stepContents();

    return BlocProvider<EnrollmentStepperFlowBloc>.value(
      value: _flowBloc,
      child: BlocBuilder<EnrollmentStepperFlowBloc, EnrollmentStepperFlowState>(
        builder: (context, flowState) {
          final currentStep = flowState.currentStep;
          final progress = (currentStep + 1) / stepTitles.length;
          final currentStepState = flowState.stateOf(currentStep);
          final currentWizardStep = EnrollmentWizardStepX.fromIndex(
            currentStep,
          );
          final stepIsEditable = widget.detailPolicy.isStepEditable(
            currentWizardStep,
          );
          final canSaveCurrentStep =
              flowState.canSave &&
              widget.detailPolicy.canSaveStep(currentWizardStep);
          final showSaveAction =
              flowState.showSaveAction &&
              widget.detailPolicy.canSaveStep(currentWizardStep);

          return Padding(
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WizardBreadcrumb(
                  titles: stepTitles,
                  currentStep: currentStep,
                  progress: progress,
                  onStepTap: (target) =>
                      _onBreadcrumbStepTap(target, currentStep),
                ),
                const SizedBox(height: 12),
                StepPageCard(
                  key: ValueKey(currentStep),
                  title: stepTitles[currentStep],
                  subtitle: stepSubtitles[currentStep],
                  child: _buildStepContent(steps[currentStep]),
                ),
                const SizedBox(height: 12),
                EnrollmentStepperControls(
                  currentStep: currentStep,
                  isLast: flowState.isLast,
                  canSave: canSaveCurrentStep,
                  canContinue: flowState.canContinue,
                  showSaveAction: showSaveAction,
                  savingNow: currentStepState.saving,
                  saveLabel: _saveLabelForStep(
                    l10n,
                    currentStep,
                    currentStepState.saving,
                  ),
                  onPrevious: () {
                    _flowBloc.add(
                      EnrollmentStepperCurrentStepChanged(currentStep - 1),
                    );
                  },
                  onSave: () => _onSavePressed(currentStep, flowState),
                  onContinue: () {
                    if (!_validateCurrentStep(
                      currentStep,
                      flowState,
                      isEditable: stepIsEditable,
                    )) {
                      return;
                    }
                    if (flowState.isLast) {
                      _showHint(l10n.enrollmentReadyForValidation);
                      return;
                    }
                    _flowBloc.add(
                      EnrollmentStepperCurrentStepChanged(currentStep + 1),
                    );
                    _resetContentScroll();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _stepTitles(AppLocalizations l10n) {
    return [
      l10n.personalInformation,
      l10n.address,
      l10n.previousYear,
      l10n.targetYear,
      l10n.guardianInformation,
      l10n.summary,
    ];
  }

  List<String> _stepSubtitles(AppLocalizations l10n) {
    return [
      l10n.stepPersonalInfoSubtitle,
      l10n.stepAddressSubtitle,
      l10n.stepAcademicPreviousSubtitle,
      l10n.stepAcademicTargetSubtitle,
      l10n.stepGuardianSubtitle,
      l10n.stepSummarySubtitle,
    ];
  }

  List<Widget> _stepContents() {
    final effectiveStudentId = _resolveStudentId();
    final canEditPersonal = widget.detailPolicy.isStepEditable(
      EnrollmentWizardStep.personalInfo,
    );
    final canEditAddress = widget.detailPolicy.isStepEditable(
      EnrollmentWizardStep.address,
    );
    final canEditPreviousAcademic = widget.detailPolicy.isStepEditable(
      EnrollmentWizardStep.previousAcademic,
    );
    final canEditTargetAcademic = widget.detailPolicy.isStepEditable(
      EnrollmentWizardStep.targetAcademic,
    );
    final canEditGuardian = widget.detailPolicy.isStepEditable(
      EnrollmentWizardStep.guardian,
    );

    return [
      PersonalInfoStep(
        key: _personalInfoKey,
        studentDetail: widget.enrollmentDetail.studentDetail,
        enrollmentId: widget.enrollmentDetail.enrollmentDetail.id,
        detailIntent: widget.detailIntent,
        detailPolicy: widget.detailPolicy,
        showInlineSaveButton: false,
        flowStepIndex: 0,
        onRefreshRequested: _refreshAfterSave,
        isEditable: canEditPersonal,
      ),
      AddressStep(
        key: _addressKey,
        studentDetail: widget.enrollmentDetail.studentDetail,
        enrollmentId: widget.enrollmentDetail.enrollmentDetail.id,
        showInlineSaveButton: false,
        flowStepIndex: 1,
        onRefreshRequested: _refreshAfterSave,
        isEditable: canEditAddress,
      ),
      PreviousAcademicInfoStep(
        key: _academicInfoKey,
        enrollmentDetail: widget.enrollmentDetail.enrollmentDetail,
        enrollmentId: widget.enrollmentDetail.enrollmentDetail.id,
        showInlineSaveButton: false,
        flowStepIndex: 2,
        onRefreshRequested: _refreshAfterSave,
        isEditable: canEditPreviousAcademic,
      ),
      TargetAcademicInfoStep(
        key: _academicTargetInfoKey,
        studentDetail: widget.enrollmentDetail.studentDetail,
        studentId: effectiveStudentId,
        enrollmentId: widget.enrollmentDetail.enrollmentDetail.id,
        showInlineSaveButton: false,
        flowStepIndex: 3,
        onRefreshRequested: _refreshAfterSave,
        isEditable: canEditTargetAcademic,
      ),
      GuardianInfoStep(
        key: _guardianInfoKey,
        parentDetails: widget.enrollmentDetail.parentDetails,
        studentId: effectiveStudentId,
        flowStepIndex: 4,
        enrollmentId: widget.enrollmentDetail.enrollmentDetail.id,
        showInlineSaveButton: false,
        onRefreshRequested: _refreshAfterSave,
        isEditable: canEditGuardian,
      ),
      SummaryStep(enrollmentDetail: widget.enrollmentDetail),
    ];
  }

  String _resolveStudentId() {
    final detailStudentId = widget.enrollmentDetail.studentDetail.id.trim();
    if (detailStudentId.isNotEmpty) {
      return detailStudentId;
    }

    return widget.detailIntent.studentId?.trim() ?? '';
  }

  void _onBreadcrumbStepTap(int targetStep, int currentStep) {
    if (targetStep <= currentStep) {
      _flowBloc.add(EnrollmentStepperCurrentStepChanged(targetStep));
      _resetContentScroll();
      return;
    }
    _showHint(AppLocalizations.of(context)!.stepForwardHint);
  }

  bool _validateCurrentStep(
    int currentStep,
    EnrollmentStepperFlowState flowState, {
    required bool isEditable,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final currentState = flowState.stateOf(currentStep);

    switch (currentStep) {
      case 0:
        if (!currentState.valid) {
          _showHint(l10n.validatePersonalInfoHint);
          return false;
        }
        if (isEditable && currentState.dirty) {
          _showHint(l10n.personalInfoSaveHintBeforeContinue);
          return false;
        }
        return true;
      case 1:
        if (!currentState.valid) {
          _showHint(l10n.validateAddressHint);
          return false;
        }
        if (isEditable && currentState.dirty) {
          _showHint(l10n.addressSaveHintBeforeContinue);
          return false;
        }
        return true;
      case 2:
        if (!currentState.valid) {
          _showHint(l10n.validateAcademicInfoHint);
          return false;
        }
        if (isEditable && currentState.dirty) {
          _showHint(l10n.academicInfoSaveHintBeforeContinue);
          return false;
        }
        return true;
      case 3:
        if (!currentState.valid) {
          _showHint(l10n.validateAcademicInfoHint);
          return false;
        }
        if (isEditable && currentState.dirty) {
          _showHint(l10n.academicInfoSaveHintBeforeContinue);
          return false;
        }
        return true;
      case 4:
        if (!currentState.valid) {
          _showHint(l10n.validateGuardianInfoHint);
          return false;
        }
        if (isEditable && currentState.dirty) {
          _showHint(l10n.personalInfoSaveHintBeforeContinue);
          return false;
        }
        return true;
      case 5:
        return true;
      default:
        return false;
    }
  }

  void _showHint(String message) {
    AppSnackBar.showWarning(context, message);
  }

  void _onSavePressed(int currentStep, EnrollmentStepperFlowState flowState) {
    if (currentStep == 0) {
      if (flowState.stateOf(0).saving) return;
      final formState = _personalInfoKey.currentState;
      if (formState == null) return;
      formState.submitForm();
      return;
    }
    if (currentStep == 1) {
      if (flowState.stateOf(1).saving) return;
      final formState = _addressKey.currentState;
      if (formState == null) return;
      formState.submitForm();
      return;
    }
    if (currentStep == 2) {
      if (flowState.stateOf(2).saving) return;
      final formState = _academicInfoKey.currentState;
      if (formState == null) return;
      formState.submitForm();
      return;
    }
    if (currentStep == 3) {
      if (flowState.stateOf(3).saving) return;
      final formState = _academicTargetInfoKey.currentState;
      if (formState == null) return;
      formState.submitForm();
    }
    if (currentStep == 4) {
      if (flowState.stateOf(4).saving) return;
      final formState = _guardianInfoKey.currentState;
      if (formState == null) return;
      formState.submitForm();
      return;
    }
  }

  void _resetContentScroll() {
    // Le scroll est maintenant géré par le SingleChildScrollView parent.
  }

  void _refreshAfterSave() {
    if (!mounted) return;
    final enrollmentBloc = context.read<EnrollmentBloc>();
    widget.detailPolicy.requestLoad(
      enrollmentBloc,
      widget.detailIntent,
      silent: true,
    );
    enrollmentBloc.add(const EnrollmentSummariesRefreshRequested());
  }

  Widget _buildStepContent(Widget stepContent) {
    return stepContent;
  }
}
