import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_read_only_banner.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_controls.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_layout.dart';
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

  // « Rien à valider » : dossier serveur clos, OU consultation lecture seule
  // (dont un dossier LOCAL non synchronisé ouvert depuis le listing). Dans ces
  // cas le résumé propose « retour » et ne finalise jamais.
  bool get _isEnrollmentAlreadyCompleted =>
      widget.enrollmentDetail.enrollmentDetail.status ==
          EnrollmentStatus.completed ||
      widget.detailPolicy.isReadOnlyConsultation;

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

    // La validation vit désormais dans le brouillon local (finalisation) : le
    // spinner du résumé suit l'écriture locale en cours, plus un statut online.
    return BlocBuilder<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      buildWhen: (prev, curr) =>
          (prev is EnrollmentDraftSaving) != (curr is EnrollmentDraftSaving),
      builder: (context, offlineState) {
        final isStatusUpdateLoading = offlineState is EnrollmentDraftSaving;

        return BlocConsumer<
          EnrollmentStepperFlowBloc,
          EnrollmentStepperFlowState
        >(
          // L'étape courante est notifiée à la page via un listener (après la
          // phase de build) : appeler onStepChanged depuis le builder
          // déclencherait un setState pendant le build (illégal, crash lors
          // d'une relayout déclenchée par un LayoutBuilder).
          listenWhen: (prev, curr) => prev.currentStep != curr.currentStep,
          listener: (context, flowState) {
            widget.onStepChanged?.call(flowState.currentStep);
          },
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

            return EnrollmentStepperLayout(
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
              // Dossier en consultation lecture seule → bandeau d'avis au-dessus
              // de chaque étape. Exclut le cas Frais-verrouillé-en-création.
              stepBanner: widget.detailPolicy.isReadOnlyConsultation
                  ? const EnrollmentReadOnlyBanner()
                  : null,
              controls: controls,
            );
          },
        );
      },
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

    // Parcours brouillon offline-first (tous les flux d'édition) : la
    // ré-hydratation entre étapes se fait depuis la base LOCALE (brouillon) et
    // non via un GET serveur. L'agrégat est reconstruit par la page hôte à la
    // réception du détail local.
    if (widget.detailPolicy.usesLocalDraft) {
      final enrollmentId = widget.enrollmentDetail.enrollmentDetail.id.trim();
      if (enrollmentId.isEmpty) return;
      context.read<EnrollmentOfflineBloc>().add(
        LoadDraftDetailRequested(enrollmentId),
      );
      return;
    }

    // Consultation lecture seule uniquement (les flux d'édition sont pris en
    // charge par la branche brouillon ci-dessus) : la ré-hydratation locale
    // suffit. Les listings tournent désormais sur `EnrollmentLocalListBloc`,
    // donc plus aucun rafraîchissement de `EnrollmentBloc.summaries` ici.
    widget.detailPolicy.requestLoad(
      context.read<EnrollmentBloc>(),
      widget.detailIntent,
      silent: true,
    );
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
