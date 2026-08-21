import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_finalize_overlay.dart';
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
    // Dossier clos OU consultation lecture seule (dont un dossier LOCAL non
    // synchronisé ouvert depuis le listing) : rien à finaliser → retour.
    if (status == EnrollmentStatus.completed ||
        context.detailPolicy.isReadOnlyConsultation) {
      AppSnackBar.showInfo(
        context.context,
        context.l10n.completedEnrollmentRedirecting,
      );
      EnrollmentNavigationHelper.leaveWizardToListing(context.context);
      return const StepSubmitResult.completed(consumeNavigation: true);
    }

    // Précondition héritée : le dossier a bien été agrégé online au fil des
    // étapes (id présent) avant confirmation.
    final enrollmentId = context.detail.enrollmentDetail.id.trim();
    if (enrollmentId.isEmpty) {
      return const StepSubmitResult.blocked();
    }

    // Offline-first : la confirmation ne passe plus par l'appel online
    // `EnrollmentStatusUpdateRequested(COMPLETED)` mais par la **finalisation
    // du brouillon local** (DRAFT → PENDING_SYNC + 1 agrégat outbox) — même
    // chemin pour TOUS les parcours : NEW vierge comme RE/PRE/reprise seedés
    // depuis le dossier serveur. Le retour visuel « en attente de synchro »
    // et la pastille globale sont pris en charge par la popin de résultat
    // (`EnrollmentFinalizeOverlay`) ; la navigation de succès est déclenchée
    // ci-dessous, une fois la popin refermée.
    //
    // Le contexte de test unitaire est un BuildContext factice (pas un Element,
    // donc sans provider) : on dégrade proprement sans planter. En production le
    // contexte est toujours un Element ; une éventuelle absence de provider
    // remonterait alors bruyamment (pas de masquage d'erreur de câblage).
    final buildContext = context.context;
    if (buildContext is! Element) {
      return const StepSubmitResult.dispatched();
    }

    final offlineBloc = buildContext.read<EnrollmentOfflineBloc>();
    if (offlineBloc.state is EnrollmentDraftSaving) {
      return const StepSubmitResult.blocked();
    }

    // Dernière étape : confirmation explicite avant la finalisation (bascule
    // DRAFT → PENDING_SYNC irréversible côté wizard — le brouillon n'est plus
    // ré-ouvrable ensuite). Le dialogue est modal : pas de double dispatch.
    final confirmed = await showAppConfirmationDialog(
      context: buildContext,
      title: context.l10n.enrollmentFinalizeConfirmTitle,
      message: context.l10n.enrollmentFinalizeConfirmMessage,
      confirmLabel: context.l10n.validateEnrollment,
      cancelLabel: context.l10n.cancel,
      headerIcon: Icons.fact_check_outlined,
      confirmIcon: Icons.check_rounded,
    );
    if (!confirmed || !context.context.mounted) {
      return const StepSubmitResult.noop();
    }

    // Re-vérification après l'attente du dialogue (TOCTOU) : une écriture
    // d'étape en file au moment du tap a pu démarrer pendant l'ouverture — on
    // ne finalise jamais par-dessus une écriture en cours.
    if (offlineBloc.state is EnrollmentDraftSaving) {
      return const StepSubmitResult.blocked();
    }
    if (!context.context.mounted) {
      return const StepSubmitResult.blocked();
    }

    // La finalisation elle-même (dispatch + processing → succès | échec) est
    // portée par la sur-couche : elle dispatche `FinalizeDraftRequested` et
    // affiche le résultat pendant que l'écriture locale se déroule.
    final outcome = await showEnrollmentFinalizeOverlay(
      context: buildContext,
      offlineBloc: offlineBloc,
      enrollmentId: enrollmentId,
      finalStatus: context.detailPolicy.finalizeStatus,
    );
    if (!context.context.mounted) {
      return const StepSubmitResult.dispatched();
    }

    if (outcome == EnrollmentFinalizeOutcome.failed) {
      // Échec : le formulaire reste éditable, aucune navigation.
      return const StepSubmitResult.blocked();
    }
    if (!context.context.mounted) {
      return const StepSubmitResult.blocked();
    }

    // Retour au listing : on dépile quand le wizard a été ouvert par `push`
    // (reprise d'un brouillon / candidat RE-PRE) — sans quoi la redirection
    // vers l'accueil serait inerte et le listing resterait figé sur l'état
    // d'AVANT la finalisation (dossier encore badgé « Brouillon »).
    EnrollmentNavigationHelper.leaveWizardToListing(buildContext);
    return const StepSubmitResult.completed(consumeNavigation: true);
  }

  @override
  Widget buildContent(HandlerBuildContext context) {
    return SummaryStep(
      enrollmentDetail: context.detail,
      onEditRequested: context.onSummaryEditRequested,
    );
  }
}
