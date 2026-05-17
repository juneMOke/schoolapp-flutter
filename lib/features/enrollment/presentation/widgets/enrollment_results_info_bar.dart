import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentResultsInfoBar extends StatelessWidget {
  final int count;
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final String? statusLabel;
  final bool showStatusBadge;
  final Widget? action;

  const EnrollmentResultsInfoBar({
    super.key,
    required this.count,
    required this.isLoading,
    this.onRefresh,
    this.statusLabel,
    this.showStatusBadge = true,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.bleuArdoise.withValues(alpha: 0.14),
              borderRadius: AppRadius.brSm,
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 16,
              color: AppColors.bleuArdoise,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading
                  ? l10n.loadingStudents
                  : l10n.enrollmentResultsCount(count),
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (showStatusBadge) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(
                statusLabel ?? '',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.bleuArdoise,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (action != null) ...[action!, const SizedBox(width: 6)],
          Tooltip(
            message: l10n.refresh,
            child: IconButton(
              onPressed: isLoading || onRefresh == null
                  ? null
                  : () => onRefresh!(),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              color: AppColors.bleuArdoise,
            ),
          ),
        ],
      ),
    );
  }
}
