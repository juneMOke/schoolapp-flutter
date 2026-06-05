import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_navigation_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_controls.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/step_page_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/wizard_breadcrumb.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStepper extends StatefulWidget {
  final EnrollmentDetail enrollmentDetail;
  final EnrollmentDetailIntent detailIntent;
  final EnrollmentDetailPolicy detailPolicy;
  final List<EnrollmentStepHandler> stepHandlers;
  final ValueChanged<int>? onStepChanged;

  const EnrollmentStepper({
    super.key,
    required this.enrollmentDetail,
    required this.detailIntent,
    required this.detailPolicy,
    required this.stepHandlers,
    this.onStepChanged,
  });

  @override
  State<EnrollmentStepper> createState() => _EnrollmentStepperState();
}

class _EnrollmentStepperState extends State<EnrollmentStepper> {
  List<EnrollmentStepHandler> get _stepHandlers => widget.stepHandlers;

  bool get _isEnrollmentAlreadyCompleted =>
      widget.enrollmentDetail.enrollmentDetail.status ==
      EnrollmentStatus.completed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepTitles = _stepHandlers
        .map((handler) => handler.title(l10n))
        .toList(growable: false);
    final breadcrumbTitles = <String>[
      l10n.wizardStepShortPersonal,
      l10n.wizardStepShortAddress,
      l10n.wizardStepShortPrevious,
      l10n.wizardStepShortTarget,
      l10n.wizardStepShortGuardian,
      l10n.wizardStepShortCharges,
      l10n.wizardStepShortSummary,
    ];
    final stepCardSubtitles = _stepHandlers
        .map((handler) => handler.subtitle(l10n))
        .toList(growable: false);
    final stepContents = _stepHandlers
        .map(
          (handler) => handler.buildContent(
            HandlerBuildContext(
              detail: widget.enrollmentDetail,
              intent: widget.detailIntent,
              detailPolicy: widget.detailPolicy,
              onRefreshRequested: _refreshAfterSave,
              onSummaryEditRequested: _onSummaryEditRequested,
            ),
          ),
        )
        .toList(growable: false);
    final flowBloc = context.read<EnrollmentStepperFlowBloc>();

    return BlocListener<EnrollmentBloc, EnrollmentState>(
      listenWhen: (prev, curr) =>
          prev.statusUpdateStatus != curr.statusUpdateStatus,
      listener: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final enrollmentBloc = context.read<EnrollmentBloc>();
        if (state.statusUpdateStatus == EnrollmentLoadStatus.success) {
          AppSnackBar.showSuccess(context, l10n.enrollmentStatusUpdateSuccess);
          enrollmentBloc.add(const EnrollmentStatusUpdateResultConsumed());
          EnrollmentNavigationHelper.redirectToFirstRegistrationFromHome(
            context,
          );
        } else if (state.statusUpdateStatus == EnrollmentLoadStatus.failure) {
          AppSnackBar.showError(
            context,
            l10n.enrollmentStatusUpdateError(state.errorMessage ?? ''),
          );
          enrollmentBloc.add(const EnrollmentStatusUpdateResultConsumed());
        }
      },
      child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        buildWhen: (prev, curr) =>
            prev.statusUpdateStatus != curr.statusUpdateStatus,
        builder: (context, enrollmentState) {
          final isStatusUpdateLoading =
              enrollmentState.statusUpdateStatus ==
              EnrollmentLoadStatus.loading;

          return BlocBuilder<
            EnrollmentStepperFlowBloc,
            EnrollmentStepperFlowState
          >(
            builder: (context, flowState) {
              final currentStep = flowState.currentStep;
              widget.onStepChanged?.call(currentStep);
              final progress = (currentStep + 1) / stepTitles.length;
              final currentStepState = flowState.stateOf(currentStep);
              final currentHandler = _stepHandlers[currentStep];
              final currentWizardStep = currentHandler.step;
              final isSummaryStep = currentHandler.isSummaryStep;
              final stepIsEditable = widget.detailPolicy.isStepEditable(
                currentWizardStep,
              );
              final flowContext = HandlerFlowContext(
                flowState: flowState,
                currentStepIndex: currentStep,
                currentStep: currentWizardStep,
                currentStepState: currentStepState,
                isStatusUpdateLoading: isStatusUpdateLoading,
                detail: widget.enrollmentDetail,
                intent: widget.detailIntent,
                detailPolicy: widget.detailPolicy,
              );
              final effectiveSavingNow = currentHandler.isSavingNow(
                flowContext,
              );
              final canSaveCurrentStep = currentHandler.canSave(flowContext);
              final showSaveAction = currentHandler.showSaveAction(flowContext);

              final controls = EnrollmentStepperControls(
                currentStep: currentStep,
                isLast: flowState.isLast,
                isSummaryStep: isSummaryStep,
                dirty: currentStepState.dirty,
                valid: currentStepState.valid,
                canSave: canSaveCurrentStep,
                canContinue: currentHandler.canContinue(flowContext),
                showSaveAction: showSaveAction,
                savingNow: effectiveSavingNow,
                saveLabel: currentHandler.saveLabel(
                  l10n,
                  SaveLabelContext(
                    savingNow: effectiveSavingNow,
                    isEnrollmentAlreadyCompleted: _isEnrollmentAlreadyCompleted,
                    enrollmentState: enrollmentState,
                  ),
                ),
                onPrevious: () {
                  flowBloc.add(
                    EnrollmentStepperCurrentStepChanged(currentStep - 1),
                  );
                },
                onSave: () {
                  _onSavePressed(currentStep, flowState);
                },
                onContinue: () {
                  _onContinuePressed(
                    handler: currentHandler,
                    flowContext: flowContext,
                    isEditable: stepIsEditable,
                  );
                },
              );

              return _EnrollmentStepperLayout(
                stepTitles: breadcrumbTitles,
                currentStep: currentStep,
                progress: progress,
                onStepTap: (target) =>
                    _onBreadcrumbStepTap(flowBloc, target, currentStep),
                stepTitle: stepTitles[currentStep],
                stepSubtitle: stepCardSubtitles[currentStep],
                stepContent: stepContents[currentStep],
                stepEyebrow:
                    '${l10n.stepIndicator(currentStep + 1, stepTitles.length)} · ${breadcrumbTitles[currentStep]}',
                stepAccentColor: _stepAccentColor(currentWizardStep),
                stepIcon: _stepIcon(currentWizardStep),
                controls: controls,
              );
            },
          );
        },
      ),
    );
  }

  void _onSummaryEditRequested(int step) {
    final maxEditableIndex = _stepHandlers.lastIndexWhere(
      (handler) => !handler.isSummaryStep,
    );
    final boundedStep = step.clamp(
      0,
      maxEditableIndex < 0 ? 0 : maxEditableIndex,
    );
    context.read<EnrollmentStepperFlowBloc>().add(
      EnrollmentStepperCurrentStepChanged(boundedStep),
    );
  }

  void _onBreadcrumbStepTap(
    EnrollmentStepperFlowBloc flowBloc,
    int targetStep,
    int currentStep,
  ) {
    if (targetStep <= currentStep) {
      flowBloc.add(EnrollmentStepperCurrentStepChanged(targetStep));
      return;
    }
    _showHint(AppLocalizations.of(context)!.stepForwardHint);
  }

  void _onContinuePressed({
    required EnrollmentStepHandler handler,
    required HandlerFlowContext flowContext,
    required bool isEditable,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final result = handler.continueFlow(
      HandlerContinueContext(
        flow: flowContext,
        validation: HandlerValidationContext(
          stepState: flowContext.currentStepState,
          isEditable: isEditable,
          detail: widget.enrollmentDetail,
          detailPolicy: widget.detailPolicy,
          l10n: l10n,
        ),
      ),
    );

    if (result.hintKey != null && result.hintKey!.trim().isNotEmpty) {
      _showHint(result.hintKey!);
    }

    if (result.status == StepContinueStatus.advance &&
        result.nextStepIndex != null) {
      context.read<EnrollmentStepperFlowBloc>().add(
        EnrollmentStepperCurrentStepChanged(result.nextStepIndex!),
      );
    }
  }

  void _showHint(String message) {
    AppSnackBar.showWarning(context, message);
  }

  Future<void> _onSavePressed(
    int currentStep,
    EnrollmentStepperFlowState flowState,
  ) async {
    if (flowState.stateOf(currentStep).saving) return;

    final handler = _stepHandlers[currentStep];
    final enrollmentBloc = context.read<EnrollmentBloc>();
    await handler.submit(
      HandlerSubmitContext(
        context: context,
        enrollmentBloc: enrollmentBloc,
        flowBloc: context.read<EnrollmentStepperFlowBloc>(),
        enrollmentState: enrollmentBloc.state,
        detail: widget.enrollmentDetail,
        intent: widget.detailIntent,
        detailPolicy: widget.detailPolicy,
        l10n: AppLocalizations.of(context)!,
      ),
    );
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

  // Teinte d'accent par étape — indexée sur l'identité de l'étape (et non sa
  // position), donc robuste à la réorganisation Tuteurs/Frais. Sept teintes
  // distinctes : le résumé ne réutilise plus le vert-savane des frais.
  Color _stepAccentColor(EnrollmentWizardStep step) {
    return switch (step) {
      EnrollmentWizardStep.personalInfo => AppColors.bleuArdoise,
      EnrollmentWizardStep.address => AppColors.info,
      EnrollmentWizardStep.previousAcademic => AppColors.orDoux,
      EnrollmentWizardStep.targetAcademic => AppColors.terreCuite,
      EnrollmentWizardStep.studentCharges => AppColors.vertSavane,
      EnrollmentWizardStep.guardian => AppColors.warning,
      EnrollmentWizardStep.summary => AppColors.bleuProfond,
    };
  }

  IconData _stepIcon(EnrollmentWizardStep step) {
    return switch (step) {
      EnrollmentWizardStep.personalInfo => Icons.badge_outlined,
      EnrollmentWizardStep.address => Icons.home_work_outlined,
      EnrollmentWizardStep.previousAcademic => Icons.history_edu_outlined,
      EnrollmentWizardStep.targetAcademic => Icons.trending_up_rounded,
      EnrollmentWizardStep.studentCharges => Icons.payments_outlined,
      EnrollmentWizardStep.guardian => Icons.family_restroom_outlined,
      EnrollmentWizardStep.summary => Icons.fact_check_outlined,
    };
  }
}

class _EnrollmentStepperLayout extends StatelessWidget {
  final List<String> stepTitles;
  final int currentStep;
  final double progress;
  final ValueChanged<int> onStepTap;
  final String stepTitle;
  final String stepSubtitle;
  final String stepEyebrow;
  final Color stepAccentColor;
  final IconData stepIcon;
  final Widget stepContent;
  final Widget controls;

  const _EnrollmentStepperLayout({
    required this.stepTitles,
    required this.currentStep,
    required this.progress,
    required this.onStepTap,
    required this.stepTitle,
    required this.stepSubtitle,
    required this.stepEyebrow,
    required this.stepAccentColor,
    required this.stepIcon,
    required this.stepContent,
    required this.controls,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardBreadcrumb(
            titles: stepTitles,
            currentStep: currentStep,
            progress: progress,
            onStepTap: onStepTap,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : AppMotion.stepIn,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      if (reduceMotion) return child;
                      // etStepIn : fondu + glissement translateY 10 → 0.
                      return FadeTransition(
                        opacity: animation,
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, inner) => Transform.translate(
                            offset: Offset(0, (1 - animation.value) * 10),
                            child: inner,
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: StepPageCard(
                      key: ValueKey(currentStep),
                      eyebrow: stepEyebrow,
                      title: stepTitle,
                      subtitle: stepSubtitle,
                      accentColor: stepAccentColor,
                      icon: stepIcon,
                      child: stepContent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pied fixe : barre d'actions ancrée hors du défilement, identique
          // pour toutes les étapes (PARCOURS 21).
          controls,
        ],
      ),
    );
  }
}
