import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/layout/leading_trailing_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une ligne « libellé … montant » d'un détail de paie, chiffres tabulaires
/// alignés à droite. [ink] teinte le montant (une retenue, un arriéré).
class PayrollAmountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? ink;

  const PayrollAmountRow(this.label, this.value, {super.key, this.ink});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    // Le montant garde sa largeur ; le libellé prend le reste. Un `Flexible`
    // à côté d'un `Expanded` bridait l'un et l'autre à la moitié.
    child: LeadingTrailingRow(
      gap: AppSpacing.sm,
      leading: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Text(
        value,
        textAlign: TextAlign.end,
        style: AppTypography.labelLarge.copyWith(
          color: ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}
