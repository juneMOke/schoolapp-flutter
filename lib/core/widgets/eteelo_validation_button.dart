import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

class EteeloValidationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const EteeloValidationButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isLoading ? AppColors.stateDisabled : AppColors.terreCuite,
          borderRadius: AppRadius.brSm,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.textOnDark,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: AppColors.textOnDark.withValues(
              alpha: 0.7,
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
            textStyle: AppTypography.labelLarge.copyWith(letterSpacing: 0.3),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnDark,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
