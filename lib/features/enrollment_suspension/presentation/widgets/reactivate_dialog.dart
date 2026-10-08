import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_labels.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_notice.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_target_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Modale « Réactiver » : on rappelle depuis quand et pourquoi, puis on
/// confirme. Le rappel n'apparaît que pour un seul élève.
class ReactivateDialog extends StatelessWidget {
  final List<SuspensionCandidate> candidates;

  /// La période ouverte de l'élève, pour le rappel ; `null` en lot.
  final StudentSuspension? suspension;

  const ReactivateDialog({
    super.key,
    required this.candidates,
    this.suspension,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = candidates.length;
    final suspension = count == 1 ? this.suspension : null;
    return BlocConsumer<SuspensionGestureCubit, SuspensionGestureState>(
      listenWhen: (_, state) => state is SuspensionGestureDone,
      listener: (context, state) =>
          Navigator.of(context).pop((state as SuspensionGestureDone).count),
      builder: (context, state) {
        final busy = state is SuspensionGestureBusy;
        return PopScope(
          canPop: !busy,
          child: EteeloFormDialog(
            eyebrow: l10n.suspensionDialogEyebrow,
            title: l10n.reactivationDialogTitle(count),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SuspensionTargetHeader(candidates: candidates),
                if (suspension != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _Reminder(suspension: suspension),
                ],
                const SizedBox(height: AppSpacing.lg),
                SuspensionNotice(body: l10n.reactivationInfo),
                if (state is SuspensionGestureFailed)
                  SuspensionGestureError(message: l10n.suspensionWriteFailed),
              ],
            ),
            actions: [
              EteeloButton.ghost(
                label: l10n.suspensionCancel,
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                fullWidth: false,
              ),
              EteeloButton.success(
                label: l10n.reactivationConfirm,
                icon: Icons.how_to_reg_outlined,
                isLoading: busy,
                loadingLabel: l10n.reactivationBusy,
                onPressed: () => context
                    .read<SuspensionGestureCubit>()
                    .reactivate([for (final c in candidates) c.target]),
                fullWidth: false,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// « Désactivé le … · Motif … ».
class _Reminder extends StatelessWidget {
  final StudentSuspension suspension;

  const _Reminder({required this.suspension});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = [
      suspension.reason?.label(l10n),
      suspension.precision,
    ].whereType<String>().join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(
          l10n.reactivationSinceLabel,
          l10n.suspensionDate(suspension.suspendedAt),
        ),
        const SizedBox(height: AppSpacing.xs),
        _line(l10n.reactivationReasonLabel, reason.isEmpty ? '—' : reason),
      ],
    );
  }

  Widget _line(String label, String value) => Text.rich(
    TextSpan(
      text: '$label  ',
      style: AppTypography.labelSmall.copyWith(color: AppColors.textMutedAa),
      children: [
        TextSpan(
          text: value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
