import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreRegistrationsInfoBar extends StatelessWidget {
  final int count;
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final String? statusLabel;
  final bool showStatusBadge;
  final Widget? action;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const PreRegistrationsInfoBar({
    super.key,
    required this.count,
    required this.isLoading,
    this.onRefresh,
    this.statusLabel,
    this.showStatusBadge = true,
    this.action,
    this.currentPage = 0,
    this.totalPages = 0,
    this.onPreviousPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canGoPrevious = !isLoading && onPreviousPage != null && currentPage > 0;
    final canGoNext =
        !isLoading && onNextPage != null && currentPage + 1 < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.14),
            const Color(0xFF10B981).withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading
                  ? l10n.loadingStudents
                  : l10n.enrollmentResultsCount(count),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          if (showStatusBadge) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (totalPages > 0) ...[
            Text(
              l10n.enrollmentPageIndicator(currentPage + 1, totalPages),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            IconButton(
              onPressed: canGoPrevious ? onPreviousPage : null,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: l10n.previousPage,
              color: AppTheme.primaryColor,
            ),
            IconButton(
              onPressed: canGoNext ? onNextPage : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: l10n.nextPage,
              color: AppTheme.primaryColor,
            ),
          ],
          if (action != null) ...[
            action!,
            const SizedBox(width: 6),
          ],
          Tooltip(
            message: l10n.refresh,
            child: IconButton(
              onPressed:
                  isLoading || onRefresh == null ? null : () => onRefresh!(),
              icon:
                  isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.refresh_rounded),
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
