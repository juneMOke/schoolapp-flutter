import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Les deux atomes qui disent « où en est ce frais » : la jauge, et la ligne de
/// montants sous elle.
///
/// Partagés par la **tranche** et par l'**en-tête de nature** qui la coiffe
/// (GF-3). Les deux disent la même chose de la même donnée, à une maille près :
/// les laisser diverger ferait lire deux barres différentes empilées à trois
/// pixels l'une de l'autre.

/// La barre de remplissage d'un frais.
class FeeProgressBar extends StatelessWidget {
  /// Entre 0 et 1 — déjà borné par l'appelant.
  final double progress;

  /// Teinte du statut (cf. `FeeStatusVisuals`).
  final Color fill;

  const FeeProgressBar({super.key, required this.progress, required this.fill});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 7,
        backgroundColor: AppColors.surfaceAlt,
        valueColor: AlwaysStoppedAnimation<Color>(fill),
      ),
    );
  }
}

/// « Attendu 350 000 FC · Payé 150 000 FC · 200 000 FC restant ».
///
/// Le reste ne s'affiche qu'à partir du moment où il en reste : sur un frais
/// soldé, « 0 restant » ajouterait un chiffre à lire pour ne rien apprendre.
class FeeAmountsRow extends StatelessWidget {
  final String expectedLabel;
  final String paidLabel;
  final String expected;
  final String paid;

  /// Déjà composé (« 200 000 FC restant »), ou `null` si le frais est soldé.
  final String? remainingText;

  const FeeAmountsRow({
    super.key,
    required this.expectedLabel,
    required this.paidLabel,
    required this.expected,
    required this.paid,
    required this.remainingText,
  });

  @override
  Widget build(BuildContext context) {
    final mutedStyle = AppTextStyles.caption.copyWith(
      color: AppColors.textMuted,
    );
    final strongStyle = AppTextStyles.caption.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );

    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$expectedLabel ', style: mutedStyle),
              TextSpan(text: expected, style: strongStyle),
            ],
          ),
        ),
        Text('·', style: mutedStyle),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$paidLabel ', style: mutedStyle),
              TextSpan(text: paid, style: strongStyle),
            ],
          ),
        ),
        if (remainingText != null) ...[
          Text('·', style: mutedStyle),
          Text(
            remainingText!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.feeStatusDue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
