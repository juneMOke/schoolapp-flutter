import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FinanceStatsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const FinanceStatsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: l10n.financeStatsErrorA11yLabel(message),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  l10n.financeStatsErrorTitle,
                  style: AppTextStyles.sectionTitle.copyWith(color: AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(message, style: AppTextStyles.body),
            const SizedBox(height: AppDimensions.spacingM),
            Tooltip(
              message: l10n.financeStatsRetryHint,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.financeStatsRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
