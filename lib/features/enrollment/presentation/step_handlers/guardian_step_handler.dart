import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/parent_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianStepHandler extends BaseEnrollmentStepHandler {
  final EnrollmentStepSubmitController controller;

  GuardianStepHandler({required this.controller});

  @override
  EnrollmentWizardStep get step => EnrollmentWizardStep.guardian;

  @override
  int get order => step.index;

  @override
  String title(AppLocalizations l10n) => l10n.guardianInformation;

  @override
  String subtitle(AppLocalizations l10n) => l10n.stepGuardianSubtitle;

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) {
    return context.savingNow ? l10n.savingGuardianInfo : l10n.saveGuardianInfo;
  }

  @override
  StepFormState initialState(HandlerInitialStateContext context) {
    return StepFormState(
      dirty: false,
      saving: false,
      valid: EnrollmentStepperStateHelper.isGuardianInfoValid(
        context.detail.parentDetails,
      ),
    );
  }

  @override
  StepValidationResult validate(HandlerValidationContext context) {
    return validateRequiredAndSaved(
      context: context,
      invalidHint: context.l10n.validateGuardianInfoHint,
      dirtyHint: context.l10n.personalInfoSaveHintBeforeContinue,
    );
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
    final readOnlyDossier = !context.detailPolicy.isStepEditable(step);
    // `Builder` pour disposer d'un BuildContext SOUS les providers de la page :
    // le handler, lui, n'en a aucun. Le widget reste ainsi ignorant du
    // `ParentBloc` — c'est le handler qui décide d'où part l'écriture.
    return Builder(
      builder: (innerContext) => GuardianInfoStep(
        parentDetails: context.detail.parentDetails,
        studentId: resolveStudentId(context),
        flowStepIndex: step.index,
        enrollmentId: context.detail.enrollmentDetail.id,
        showInlineSaveButton: false,
        onRefreshRequested: context.onRefreshRequested,
        isEditable: context.detailPolicy.isStepEditable(step),
        // **La seule écriture qui survit à la finalisation.** Sur un dossier en
        // consultation, la désignation du contact d'urgence reste ouverte et
        // part en ligne ; tout le reste demeure figé. C'est un choix, pas un
        // oubli : c'est l'information qu'on relira un jour d'accident, et la
        // faire dépendre d'une réouverture du dossier la rendrait inutilisable
        // au moment où elle sert.
        onEmergencyContactCommitted: readOnlyDossier
            ? (parentId) {
                final studentId = resolveStudentId(context).trim();
                if (studentId.isEmpty) return;
                innerContext.read<ParentBloc>().add(
                  ParentEmergencyContactRequested(
                    studentId: studentId,
                    parentId: parentId,
                  ),
                );
              }
            : null,
        stepController: controller,
      ),
    );
  }
}
