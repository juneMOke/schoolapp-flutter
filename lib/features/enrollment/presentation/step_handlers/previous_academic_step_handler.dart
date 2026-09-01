import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/previous_academic_info_step.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreviousAcademicStepHandler extends BaseEnrollmentStepHandler {
  final EnrollmentStepSubmitController controller;

  PreviousAcademicStepHandler({required this.controller});

  @override
  EnrollmentWizardStep get step => EnrollmentWizardStep.previousAcademic;

  @override
  int get order => step.index;

  @override
  String title(AppLocalizations l10n) => l10n.previousYear;

  @override
  String subtitle(AppLocalizations l10n) => l10n.stepAcademicPreviousSubtitle;

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) {
    return context.savingNow ? l10n.savingAcademicInfo : l10n.saveAcademicInfo;
  }

  @override
  StepFormState initialState(HandlerInitialStateContext context) {
    return StepFormState(
      dirty: false,
      saving: false,
      valid: EnrollmentStepperStateHelper.isAcademicPreviousInfoValid(
        context.detail.enrollmentDetail,
      ),
    );
  }

  @override
  StepValidationResult validate(HandlerValidationContext context) {
    return validateRequiredAndSaved(
      context: context,
      invalidHint: context.l10n.validateAcademicInfoHint,
      dirtyHint: context.l10n.academicInfoSaveHintBeforeContinue,
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

  /// L'étape a besoin de deux faits que le dossier ne porte pas : l'année
  /// scolaire de l'école (pour proposer celle qui la précède) et le nom de
  /// l'établissement (pour « ancien élève »). Ils sont lus ici, en `Selector`,
  /// pour que l'étape elle-même reste un widget de formulaire testable seul.
  @override
  Widget buildContent(HandlerBuildContext context) {
    return BlocSelector<
      AcademicYearContextBloc,
      AcademicYearContextState,
      String?
    >(
      selector: (state) => state.context?.academicYear.name,
      builder: (_, currentAcademicYearName) {
        return BlocSelector<SchoolIdentityCubit, SchoolIdentityState, String?>(
          selector: (state) => state.school?.name,
          builder: (_, schoolName) {
            return PreviousAcademicInfoStep(
              enrollmentDetail: context.detail.enrollmentDetail,
              enrollmentId: context.detail.enrollmentDetail.id,
              enrollmentType: context.detailPolicy.draftEnrollmentType,
              showInlineSaveButton: false,
              flowStepIndex: step.index,
              onRefreshRequested: context.onRefreshRequested,
              isEditable: context.detailPolicy.isStepEditable(step),
              stepController: controller,
              currentAcademicYearName: currentAcademicYearName,
              schoolName: schoolName,
            );
          },
        );
      },
    );
  }
}
