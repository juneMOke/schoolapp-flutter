import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Une erreur sur ce versement ? » — le point d'entrée des deux gestes, en
/// bas du détail d'un versement. Une zone secondaire, pas une action
/// principale : on n'y vient que pour réparer.
///
/// Un geste sans droit arrive ici à `null` et son bouton n'est pas dessiné.
class PaymentCorrectionEntryBlock extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onCorrect;

  const PaymentCorrectionEntryBlock({super.key, this.onCancel, this.onCorrect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentCorrectionEntryTitle,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.paymentCorrectionEntryHint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              if (onCancel != null)
                OutlinedButton.icon(
                  key: const ValueKey('payment-correction-cancel'),
                  onPressed: onCancel,
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: Text(l10n.paymentCorrectionCancelAction),
                  // Inline dans un Wrap : le thème impose une largeur infinie
                  // aux boutons, qu'il faut défaire ici.
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              if (onCorrect != null)
                OutlinedButton.icon(
                  key: const ValueKey('payment-correction-correct'),
                  onPressed: onCorrect,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.paymentCorrectionCorrectAction),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
