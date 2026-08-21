import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';

/// Pastille douce d'un statut de frais : icône + libellé, teintes portées par
/// [FeeStatusVisuals] (spec Facturation §20).
///
/// Partagée par la ligne de frais du détail Facturation et le tableau du
/// Contrôle des frais : les deux écrans disent la même chose du même statut,
/// ils doivent le dire de la même façon.
class FeeStatusBadge extends StatelessWidget {
  final String label;
  final FeeStatusVisuals visuals;

  const FeeStatusBadge({super.key, required this.label, required this.visuals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: visuals.soft,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: visuals.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visuals.icon, size: 14, color: visuals.color),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: visuals.color),
          ),
        ],
      ),
    );
  }
}
