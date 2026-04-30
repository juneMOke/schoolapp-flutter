import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const ClassesListPaginationBar({
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
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Semantics(
          button: true,
          enabled: !isLoading && currentPage > 0,
          label: l10n.previousPage,
          child: IconButton(
            onPressed: !isLoading && currentPage > 0 ? onPrevious : null,
            tooltip: l10n.previousPage,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.indigo,
            disabledColor: AppColors.classesDisabledFg,
          ),
        ),
        Semantics(
          button: true,
          enabled: !isLoading && currentPage + 1 < totalPages,
          label: l10n.nextPage,
          child: IconButton(
            onPressed: !isLoading && currentPage + 1 < totalPages ? onNext : null,
            tooltip: l10n.nextPage,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.indigo,
            disabledColor: AppColors.classesDisabledFg,
          ),
        ),
      ],
    );
  }
}
