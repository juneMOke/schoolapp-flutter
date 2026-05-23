import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
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

  const EnrollmentStepper({
    super.key,
    required this.enrollmentDetail,
    required this.detailIntent,
    required this.detailPolicy,
    required this.stepHandlers,
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
            AppSnackBar.showSuccess(
              context,
              l10n.enrollmentStatusUpdateSuccess,
            );
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
                final effectiveSavingNow = currentHandler.isSavingNow(flowContext);
                final canSaveCurrentStep = currentHandler.canSave(flowContext);
                final showSaveAction = currentHandler.showSaveAction(flowContext);

                final controls = EnrollmentStepperControls(
                  currentStep: currentStep,
                  isLast: flowState.isLast,
                  isSummaryStep: isSummaryStep,
                  canSave: canSaveCurrentStep,
                  canContinue: currentHandler.canContinue(flowContext),
                  showSaveAction: showSaveAction,
                  savingNow: effectiveSavingNow,
                  saveLabel: currentHandler.saveLabel(
                    l10n,
                    SaveLabelContext(
                      savingNow: effectiveSavingNow,
                      isEnrollmentAlreadyCompleted:
                          _isEnrollmentAlreadyCompleted,
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
                  stepTitles: stepTitles,
                  currentStep: currentStep,
                  progress: progress,
                  onStepTap: (target) =>
                      _onBreadcrumbStepTap(flowBloc, target, currentStep),
                  stepTitle: stepTitles[currentStep],
                  stepSubtitle: stepCardSubtitles[currentStep],
                  stepContent: stepContents[currentStep],
                  controls: controls,
                  isSummaryStep: isSummaryStep,
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
    final boundedStep = step.clamp(0, maxEditableIndex < 0 ? 0 : maxEditableIndex);
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
}

class _EnrollmentStepperLayout extends StatelessWidget {
  final List<String> stepTitles;
  final int currentStep;
  final double progress;
  final ValueChanged<int> onStepTap;
  final String stepTitle;
  final String stepSubtitle;
  final Widget stepContent;
  final Widget controls;
  final bool isSummaryStep;

  const _EnrollmentStepperLayout({
    required this.stepTitles,
    required this.currentStep,
    required this.progress,
    required this.onStepTap,
    required this.stepTitle,
    required this.stepSubtitle,
    required this.stepContent,
    required this.controls,
    required this.isSummaryStep,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StepPageCard(
                    key: ValueKey(currentStep),
                    title: stepTitle,
                    subtitle: stepSubtitle,
                    child: stepContent,
                  ),
                  if (!isSummaryStep) ...[
                    const SizedBox(height: 12),
                    controls,
                  ],
                ],
              ),
            ),
          ),
          if (isSummaryStep) ...[
            const SizedBox(height: 12),
            controls,
          ],
        ],
      ),
    );
  }
}
