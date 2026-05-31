import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class FinanceStatsEmptyState extends StatelessWidget {
  final String message;
  final String? hint;
  final String? semanticLabel;

  const FinanceStatsEmptyState({
    super.key,
    required this.message,
    this.hint,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel ?? message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.spacingM),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: AppDimensions.spacingXL,
                height: AppDimensions.spacingXL,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hint != null && hint!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        hint!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
