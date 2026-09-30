import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le bandeau bleu profond d'un net : éléments variables, versement.
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
    decoration: const BoxDecoration(
      borderRadius: AppRadius.brMd,
      gradient: LinearGradient(
        colors: [
          AppColors.staffAttendanceBannerStart,
          AppColors.staffAttendanceBannerMid,
        ],
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.staffAttendanceOnBannerMuted,
            ),
          ),
        ),
        Text(
          amount,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.staffAttendanceOnBanner,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
