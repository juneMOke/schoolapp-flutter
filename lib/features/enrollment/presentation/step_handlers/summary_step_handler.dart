import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_navigation_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/summary_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryStepHandler extends BaseEnrollmentStepHandler {
  SummaryStepHandler();

  @override
  EnrollmentWizardStep get step => EnrollmentWizardStep.summary;

  @override
  int get order => step.index;

  @override
  String title(AppLocalizations l10n) => l10n.summary;

  @override
  String subtitle(AppLocalizations l10n) => l10n.stepSummarySubtitle;

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) {
    if (context.isEnrollmentAlreadyCompleted) {
      return l10n.goToFirstRegistration;
    }
    return context.savingNow
        ? l10n.validatingEnrollment
        : l10n.validateEnrollment;
  }

  @override
  StepValidationResult validate(HandlerValidationContext context) {
    return const StepValidationResult.valid();
  }

  @override
  StepFormState initialState(HandlerInitialStateContext context) {
    return const StepFormState(dirty: false, saving: false, valid: true);
  }

  @override
  Future<StepSubmitResult> submit(HandlerSubmitContext context) async {
    final status = context.detail.enrollmentDetail.status;
    if (status == EnrollmentStatus.completed) {
      AppSnackBar.showInfo(context.context, context.l10n.completedEnrollmentRedirecting);
      EnrollmentNavigationHelper.redirectToFirstRegistrationFromHome(
        context.context,
      );
      return const StepSubmitResult.completed(consumeNavigation: true);
    }

    if (context.enrollmentState.statusUpdateStatus == EnrollmentLoadStatus.loading) {
      return const StepSubmitResult.blocked();
    }

    final enrollmentId = context.detail.enrollmentDetail.id.trim();
    if (enrollmentId.isEmpty) {
      return const StepSubmitResult.blocked();
    }

    context.enrollmentBloc.add(
      EnrollmentStatusUpdateRequested(
        enrollmentId: enrollmentId,
        status: 'COMPLETED',
      ),
    );

    return const StepSubmitResult.dispatched();
  }

  @override
  Widget buildContent(HandlerBuildContext context) {
    return SummaryStep(
      enrollmentDetail: context.detail,
      onEditRequested: context.onSummaryEditRequested,
    );
  }
}
