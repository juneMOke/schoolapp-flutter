import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesStepHandler extends BaseEnrollmentStepHandler {
  final EnrollmentStepSubmitController controller;

  StudentChargesStepHandler({required this.controller});

  @override
  EnrollmentWizardStep get step => EnrollmentWizardStep.studentCharges;

  @override
  int get order => step.index;

  @override
  String title(AppLocalizations l10n) => l10n.studentChargesStepTitle;

  @override
  String subtitle(AppLocalizations l10n) => l10n.studentChargesStepSubtitle;

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) {
    return context.savingNow
        ? l10n.studentChargesSavingAction
        : l10n.studentChargesSaveAction;
  }

  // Frais : étape en lecture seule (PARCOURS 21) — pas d'enregistrement ni
  // d'indicateur, uniquement « Continuer » (actif hors chargement).
  @override
  bool showSaveAction(HandlerFlowContext context) => false;

  /// Le semis ne peut rien dire de cette étape : sa validité dépend de la
  /// grille tarifaire et des créances chargées, que le dossier ne porte pas.
  /// Il se pose donc invalide, et c'est l'étape montée qui tranche dès qu'elle
  /// se signale — le rechargement du dossier ne la déloge plus (cf.
  /// `EnrollmentStepperFlowBloc._onStatesSynced`).
  @override
  StepFormState initialState(HandlerInitialStateContext context) {
    return const StepFormState(dirty: false, saving: false, valid: false);
  }

  @override
  StepValidationResult validate(HandlerValidationContext context) {
    if (!context.stepState.valid) {
      return StepValidationResult.invalid(
        hintKey: context.l10n.studentChargesSaveHintBeforeContinue,
        errorType: StepValidationErrorType.invalidForm,
      );
    }

    if (context.isEditable && context.stepState.dirty) {
      return StepValidationResult.invalid(
        hintKey: context.l10n.studentChargesSaveHintBeforeContinue,
        errorType: StepValidationErrorType.unsavedChanges,
      );
    }

    return const StepValidationResult.valid();
  }

  @override
  Future<StepSubmitResult> submit(HandlerSubmitContext context) async {
    if (!controller.isBound) {
      return const StepSubmitResult.noop();
    }
    controller.submitForm();
    return const StepSubmitResult.dispatched();
  }

  @override
  Widget buildContent(HandlerBuildContext context) {
    return StudentChargesStep(
      studentId: resolveStudentId(context),
      levelId: resolveLevelId(context),
      enrollmentStatus: context.detail.enrollmentDetail.status,
      showInlineSaveButton: false,
      flowStepIndex: step.index,
      isEditable: false,
      stepController: controller,
      // Flux brouillon local (création/édition) : l'étape GÉNÈRE les créances
      // provisoires depuis la grille locale (FF5) avant de les lire — la
      // consultation lecture seule se contente de lire le grand-livre.
      initializeDraftCharges: context.detailPolicy.usesLocalDraft,
      academicYearId: context.detail.enrollmentDetail.academicYearId,
      schoolLevelGroupId: context.detail.enrollmentDetail.schoolLevelGroupId,
      // Réductions (ADR-021 V1) : déclaratives, sans effet sur les montants.
      // Elles se cochent tant que le dossier se saisit — `isEditable: false`
      // ci-dessus ne concerne QUE les montants des créances.
      enrollmentId: context.detail.enrollmentDetail.id,
      reductionsEditable: !context.detailPolicy.isReadOnlyConsultation,
    );
  }
}
