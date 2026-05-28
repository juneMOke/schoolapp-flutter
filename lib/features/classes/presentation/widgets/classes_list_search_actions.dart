import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimensions.spacingS,
      children: [
        FocusTraversalOrder(
          order: const NumericFocusOrder(7),
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text(clearLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(112, AppDimensions.minTouchTarget),
              textStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
            ),
          ),
        ),
        FocusTraversalOrder(
          order: const NumericFocusOrder(8),
          child: ElevatedButton.icon(
            onPressed: onSearch,
            icon: isSearching
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnDark,
                    ),
                  )
                : const Icon(Icons.search_rounded, size: 14),
            label: Text(searchLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bleuArdoise,
              foregroundColor: AppColors.textOnDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(112, AppDimensions.minTouchTarget),
              textStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
              disabledBackgroundColor: AppColors.stateDisabled,
              disabledForegroundColor: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
