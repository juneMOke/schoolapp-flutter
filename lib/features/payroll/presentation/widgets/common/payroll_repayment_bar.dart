import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Ce qu'une avance a déjà rendu : la barre (or, puis vert une fois
/// soldée) et « retenu · reste ». Le registre et la fiche d'un agent.
class PayrollRepaymentBar extends StatelessWidget {
  final double ratio;
  final String deducted;
  final String remaining;

  const PayrollRepaymentBar({
    super.key,
    required this.ratio,
    required this.deducted,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: AppRadius.brPill,
        child: LinearProgressIndicator(
          value: ratio.clamp(0, 1),
          minHeight: AppDimensions.payrollProgressHeight,
          backgroundColor: AppColors.surfaceAlt,
          color: ratio >= 1 ? AppColors.vertSavane : AppColors.orDoux,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '$deducted · $remaining',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
      ),
    ],
  );
}
