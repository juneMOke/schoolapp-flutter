import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final refused = suspension.syncState == RecordSyncState.failed;
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text:
                '${l10n.suspensionBannerHeadline(suspension.suspendedAt, suspension.reason?.label(l10n) ?? _none, suspension.precision ?? _none)} ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: l10n.suspensionBannerEffects),
          if (refused)
            TextSpan(
              text: '\n${l10n.suspensionBannerRefused}',
              style: const TextStyle(color: AppColors.error),
            ),
        ],
      ),
      style: AppTypography.bodySmall.copyWith(color: AppColors.suspendedInk),
    );
    final action = SuspensionGate(
      child: EteeloButton.secondary(
        label: l10n.reactivationConfirm,
        icon: Icons.how_to_reg_outlined,
        fullWidth: false,
        onPressed: onReactivate,
      ),
    );
    return Semantics(
      liveRegion: true,
      child: EteeloDashedContainer(
        backgroundColor: AppColors.suspendedSurface,
        borderColor: AppColors.suspendedBorder,
        borderRadius: AppRadius.brMd,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Medallion(),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: text),
              ],
            );
            // Étroit : le bouton passe sous le texte, qui garde la largeur.
            if (constraints.maxWidth < AppDimensions.suspensionBannerStackMax) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  identity,
                  const SizedBox(height: AppSpacing.sm),
                  action,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: AppSpacing.md),
                action,
              ],
            );
          },
        ),
      ),
    );
  }

  /// La valeur `select` de l'ARB qui dit « absent ».
  static const String _none = 'none';
}

class _Medallion extends StatelessWidget {
  const _Medallion();

  @override
  Widget build(BuildContext context) => Container(
    width: AppDimensions.suspensionBannerMedallion,
    height: AppDimensions.suspensionBannerMedallion,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.suspendedInk,
    ),
    child: const Icon(
      Icons.person_remove_outlined,
      size: AppDimensions.insPaveMedallionIconSize,
      color: AppColors.textOnDark,
    ),
  );
}
