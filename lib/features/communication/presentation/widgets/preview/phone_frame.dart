import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Le téléphone de l'aperçu : 300 × 580, rayon 40.
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: AppDimensions.communicationPhoneWidth,
      height: AppDimensions.communicationPhoneHeight,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(
          AppDimensions.communicationPhoneRadius,
        ),
        boxShadow: AppElevation.shadowPop,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimensions.communicationPhoneRadius - AppSpacing.sm,
        ),
        child: ColoredBox(color: AppColors.surface, child: child),
      ),
    ),
  );
}
