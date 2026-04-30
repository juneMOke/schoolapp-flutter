import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class ClassesListSearchActions extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback? onSearch;
  final bool isSearching;
  final String clearLabel;
  final String searchLabel;

  const ClassesListSearchActions({
    super.key,
    required this.onReset,
    required this.onSearch,
    required this.isSearching,
    required this.clearLabel,
    required this.searchLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: [
        FocusTraversalOrder(
          order: const NumericFocusOrder(7),
          child: Semantics(
            button: true,
            enabled: true,
            label: clearLabel,
            child: Tooltip(
              message: clearLabel,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(clearLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(0, AppDimensions.minTouchTarget),
                  textStyle: AppTextStyles.action,
                ),
              ),
            ),
          ),
        ),
        FocusTraversalOrder(
          order: const NumericFocusOrder(8),
          child: Semantics(
            button: true,
            enabled: onSearch != null,
            label: searchLabel,
            child: Tooltip(
              message: searchLabel,
              child: ElevatedButton.icon(
                onPressed: onSearch,
                icon: isSearching
                    ? const SizedBox(
                        width: AppDimensions.detailMiniIconSize,
                        height: AppDimensions.detailMiniIconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(searchLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: AppColors.surface,
                  disabledBackgroundColor: AppColors.classesDisabledBg,
                  disabledForegroundColor: AppColors.classesDisabledFg,
                  minimumSize: const Size(0, AppDimensions.minTouchTarget),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                    vertical: AppDimensions.spacingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                  ),
                  textStyle: AppTextStyles.action,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
