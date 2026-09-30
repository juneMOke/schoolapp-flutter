import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Un compteur − valeur + : heures supplémentaires, enfants à charge.
class PayrollStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final String Function(int value) format;
  final ValueChanged<int> onChanged;
  final String decreaseLabel;
  final String increaseLabel;

  const PayrollStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.format,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.min = 0,
    this.max = 1 << 20,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String tooltip, int? next) => SizedBox.square(
      dimension: AppDimensions.payrollStepperButton,
      child: IconButton(
        tooltip: tooltip,
        onPressed: next == null ? null : () => onChanged(next),
        icon: Icon(icon),
        style: IconButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          Icons.remove,
          decreaseLabel,
          value - step < min ? null : value - step,
        ),
        SizedBox(
          width: AppDimensions.payrollStepperValueWidth,
          child: Text(
            format(value),
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        button(
          Icons.add,
          increaseLabel,
          value + step > max ? null : value + step,
        ),
      ],
    );
  }
}
