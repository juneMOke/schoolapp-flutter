import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre de navigation entre pages de résultats.
class FacturationPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const FacturationPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          l10n.enrollmentPageIndicator(currentPage + 1, totalPages),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: !isLoading && currentPage > 0 ? onPrevious : null,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: l10n.previous,
        ),
        IconButton(
          onPressed:
              !isLoading && currentPage + 1 < totalPages ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: l10n.next,
        ),
      ],
    );
  }
}
