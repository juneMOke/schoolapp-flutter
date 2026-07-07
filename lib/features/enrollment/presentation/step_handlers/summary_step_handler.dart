import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/enrollment_confirm_draft_builder.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
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
      AppSnackBar.showInfo(
        context.context,
        context.l10n.completedEnrollmentRedirecting,
      );
      EnrollmentNavigationHelper.redirectToFirstRegistrationFromHome(
        context.context,
      );
      return const StepSubmitResult.completed(consumeNavigation: true);
    }

    // Garde héritée du flux online : conservée par prudence (état online figé à
    // `initial` en offline-first, donc jamais déclenchée ici) et pour bloquer un
    // double-envoi si l'ancien chemin était réactivé.
    if (context.enrollmentState.statusUpdateStatus ==
        EnrollmentLoadStatus.loading) {
      return const StepSubmitResult.blocked();
    }

    // Précondition héritée : le dossier a bien été agrégé online au fil des
    // étapes (id présent) avant confirmation.
    final enrollmentId = context.detail.enrollmentDetail.id.trim();
    if (enrollmentId.isEmpty) {
      return const StepSubmitResult.blocked();
    }

    // Offline-first : la confirmation ne passe plus par l'appel online
    // `EnrollmentStatusUpdateRequested(COMPLETED)` mais par une écriture locale
    // (transaction sqflite + mise en file outbox) via [EnrollmentOfflineBloc].
    // Le retour visuel « en attente de synchronisation », la pastille globale et
    // la navigation de succès sont pris en charge par le BlocListener offline du
    // scope du stepper (cf. enrollment_stepper_scope.dart), miroir du listener
    // online historique.
    //
    // Le contexte de test unitaire est un BuildContext factice (pas un Element,
    // donc sans provider) : on dégrade proprement sans planter. En production le
    // contexte est toujours un Element ; une éventuelle absence de provider
    // remonterait alors bruyamment (pas de masquage d'erreur de câblage).
    final buildContext = context.context;
    if (buildContext is! Element) {
      return const StepSubmitResult.dispatched();
    }

    // Parcours NEW (première inscription) : la confirmation finalise le
    // brouillon local persisté par étape (DRAFT → PENDING_SYNC) via le
    // [EnrollmentDraftBloc]. La navigation de succès + le toast « en attente de
    // synchro » sont pris en charge par le listener du scope du stepper.
    if (context.intent.origin == EnrollmentDetailOrigin.newFirstRegistration) {
      final draftBloc = buildContext.read<EnrollmentDraftBloc>();
      if (draftBloc.state is EnrollmentDraftSaving) {
        return const StepSubmitResult.blocked();
      }
      draftBloc.add(FinalizeDraftRequested(enrollmentId));
      return const StepSubmitResult.dispatched();
    }

    // Parcours RE/PRE (élève préexistant) : câblage conservateur inchangé — la
    // confirmation projette l'agrégat online sur le chemin local-first.
    final offlineBloc = buildContext.read<EnrollmentOfflineBloc>();
    if (offlineBloc.state is EnrollmentOfflineConfirming) {
      return const StepSubmitResult.blocked();
    }

    offlineBloc.add(
      ConfirmLocalEnrollment(
        EnrollmentConfirmDraftBuilder.fromDetail(
          detail: context.detail,
          origin: context.intent.origin,
        ),
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
