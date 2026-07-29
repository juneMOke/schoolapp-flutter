import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_result_medallion.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Issue de la sur-couche de finalisation (traitement → succès | échec).
enum EnrollmentFinalizeOutcome { succeeded, failed }

/// Sur-couche affichée à la validation finale de l'inscription (dernière
/// étape du wizard, après la confirmation) : la finalisation du brouillon
/// local (DRAFT → PENDING_SYNC) est dispatchée par la sur-couche elle-même,
/// qui traverse `processing → succès | échec` dans le même vocabulaire que
/// l'encaissement (Finances) et la répartition de classes (médaillon,
/// `EteeloErrorResult`). Succès → l'appelant redirige vers l'accueil ; échec →
/// le formulaire reste éditable, l'utilisateur peut réessayer ou fermer.
Future<EnrollmentFinalizeOutcome> showEnrollmentFinalizeOverlay({
  required BuildContext context,
  required EnrollmentOfflineBloc offlineBloc,
  required String enrollmentId,
}) async {
  final outcome = await showDialog<EnrollmentFinalizeOutcome>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => BlocProvider<EnrollmentOfflineBloc>.value(
      value: offlineBloc,
      child: _EnrollmentFinalizeOverlay(enrollmentId: enrollmentId),
    ),
  );
  return outcome ?? EnrollmentFinalizeOutcome.failed;
}

enum _Phase { processing, success, error }

class _EnrollmentFinalizeOverlay extends StatefulWidget {
  final String enrollmentId;

  const _EnrollmentFinalizeOverlay({required this.enrollmentId});

  @override
  State<_EnrollmentFinalizeOverlay> createState() =>
      _EnrollmentFinalizeOverlayState();
}

class _EnrollmentFinalizeOverlayState
    extends State<_EnrollmentFinalizeOverlay> {
  _Phase _phase = _Phase.processing;
  bool _awaitingBloc = false;

  @override
  void initState() {
    super.initState();
    // Démarre la finalisation une fois le BlocListener attaché.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _finalize();
    });
  }

  void _finalize() {
    if (_awaitingBloc) return;
    setState(() {
      _phase = _Phase.processing;
      _awaitingBloc = true;
    });
    context.read<EnrollmentOfflineBloc>().add(
      FinalizeDraftRequested(widget.enrollmentId),
    );
  }

  void _onBlocState(EnrollmentOfflineState state) {
    if (!mounted || !_awaitingBloc) return;
    if (state is EnrollmentDraftFinalizedPendingSync) {
      _awaitingBloc = false;
      // Écriture locale confirmée : pastille globale de synchronisation +
      // push opportuniste déjà déclenché par le repository.
      context.read<SyncStatusCubit>().notifyLocalWrite();
      setState(() => _phase = _Phase.success);
    } else if (state is EnrollmentDraftFinalizeError) {
      _awaitingBloc = false;
      setState(() => _phase = _Phase.error);
    }
  }

  void _close(EnrollmentFinalizeOutcome outcome) =>
      Navigator.of(context).pop(outcome);

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (_, state) => _onBlocState(state),
      // Pendant le traitement, la sortie est neutralisée (scrim non-dismissible
      // ET retour système) : une issue succès|échec est toujours rendue avant
      // fermeture — jamais de sortie silencieuse sur une écriture en vol.
      child: PopScope(
        canPop: _phase != _Phase.processing,
        child: Dialog(
          backgroundColor: AppColors.surfaceRaised,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingXL,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXL),
            child: AnimatedSwitcher(
              duration: AppMotion.standard,
              switchInCurve: AppMotion.outCurve,
              child: KeyedSubtree(
                key: ValueKey(_phase),
                child: switch (_phase) {
                  _Phase.processing => const _ProcessingBody(),
                  _Phase.success => _SuccessBody(
                    onContinue: () =>
                        _close(EnrollmentFinalizeOutcome.succeeded),
                  ),
                  _Phase.error => _ErrorBody(
                    onRetry: _finalize,
                    onClose: () => _close(EnrollmentFinalizeOutcome.failed),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingBody extends StatelessWidget {
  const _ProcessingBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EteeloResultMedallion(kind: EteeloResultKind.processing),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          l10n.enrollmentFinalizeProcessingTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  final VoidCallback onContinue;

  const _SuccessBody({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EteeloResultMedallion(kind: EteeloResultKind.success),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          l10n.enrollmentFinalizeSuccessTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          // Écriture locale confirmée : retour visuel « en attente de
          // synchronisation » (offline-first).
          l10n.offlineEnrollmentQueued,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        EteeloButton.primary(
          label: l10n.enrollmentFinalizeContinueAction,
          onPressed: onContinue,
          size: EteeloButtonSize.regular,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ErrorBody({required this.onRetry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloErrorResult(
      type: EteeloErrorType.unknown,
      title: l10n.enrollmentFinalizeErrorTitle,
      // Échec de l'écriture locale offline (base/outbox).
      message: l10n.offlineWriteError,
      primaryAction: EteeloButton.primary(
        label: l10n.enrollmentFinalizeRetryAction,
        onPressed: onRetry,
        fullWidth: false,
      ),
      secondaryAction: EteeloButton.ghost(
        label: l10n.enrollmentFinalizeCloseAction,
        onPressed: onClose,
        fullWidth: false,
      ),
    );
  }
}
