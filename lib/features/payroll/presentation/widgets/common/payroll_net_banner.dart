import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le bandeau plein d'un net, au fond d'un pavé « encaissé » : éléments variables, versement.
class PayrollNetBanner extends StatelessWidget {
  final String label;
  final String amount;

  const PayrollNetBanner({
    super.key,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    decoration: BoxDecoration(
      borderRadius: AppRadius.brMd,
      color: DashboardTones.pave(DashboardSense.encaisse),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: DashboardTones.inkLibelle,
            ),
          ),
        ),
        Text(
          amount,
          style: AppTypography.headlineMedium.copyWith(
            color: DashboardTones.inkValeur,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
