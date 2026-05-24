import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class ClassesStatsEmptyChartState extends StatelessWidget {
  final String message;

  const ClassesStatsEmptyChartState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.enrollmentStatsChartSectionHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.textMuted,
              size: 28,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
