import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const StudentChargesErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.danger,
            size: AppDimensions.spacingL,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(
                l10n.studentChargesRetry,
                style: AppTextStyles.action.copyWith(color: AppColors.indigo),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
