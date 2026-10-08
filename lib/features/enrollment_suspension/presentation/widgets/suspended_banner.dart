import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_labels.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_start_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau « élève désactivé » en tête d'un dossier : on ne consulte pas
/// le dossier sans voir l'état. Date, motif, précision, et « Réactiver ».
class SuspendedBanner extends StatelessWidget {
  final StudentSuspension suspension;
  final VoidCallback onReactivate;

  const SuspendedBanner({
    super.key,
    required this.suspension,
    required this.onReactivate,
  });

  static const double _medallion = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = suspension.reason?.label(l10n);
    final precision = suspension.precision;
    final title =
        StringBuffer(l10n.suspensionBannerTitle(suspension.suspendedAt))
          ..write(reason == null ? '' : ' · $reason')
          ..write(precision == null ? '' : ' — $precision')
          ..write('.');
    final refused = suspension.syncState == RecordSyncState.failed
        ? suspension.syncError
        : null;
    return Semantics(
      liveRegion: true,
      child: EteeloDashedContainer(
        backgroundColor: AppColors.suspendedSurface,
        borderColor: AppColors.suspendedBorder,
        borderRadius: AppRadius.brMd,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 3,
          vertical: AppSpacing.md,
        ),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _medallion,
                  height: _medallion,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.suspendedInk,
                  ),
                  child: const Icon(
                    Icons.person_remove_outlined,
                    size: 15,
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 220,
                    maxWidth: 640,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$title ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: l10n.suspensionBannerEffects),
                        if (refused != null)
                          TextSpan(
                            text: '\n${l10n.suspensionBannerRefused(refused)}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                      ],
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.suspendedInk,
                    ),
                  ),
                ),
              ],
            ),
            SuspensionGate(
              child: EteeloButton.secondary(
                label: l10n.reactivationConfirm,
                icon: Icons.how_to_reg_outlined,
                fullWidth: false,
                onPressed: onReactivate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
