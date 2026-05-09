import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isDestructive ? AppColors.danger : AppColors.bleuArdoise;
    final iconBackgroundColor = isDestructive
        ? AppColors.financeDetailDangerSoft
        : AppColors.bleuArdoise.withValues(alpha: 0.12);
    final borderColor = isDestructive
        ? AppColors.danger.withValues(alpha: 0.24)
        : AppColors.borderStrong.withValues(alpha: 0.22);

    return AlertDialog(
      backgroundColor: AppColors.financeDetailCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingL,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        side: BorderSide(color: borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppDimensions.detailCardPadding,
        AppDimensions.detailCardPadding,
        AppDimensions.detailCardPadding,
        AppDimensions.spacingS,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppDimensions.detailCardPadding,
        0,
        AppDimensions.detailCardPadding,
        AppDimensions.spacingM,
      ),
      title: Row(
        children: [
          Container(
            width: AppDimensions.spacingXL + AppDimensions.spacingXS,
            height: AppDimensions.spacingXL + AppDimensions.spacingXS,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            ),
            child: Icon(
              isDestructive
                  ? Icons.warning_amber_rounded
                  : Icons.help_outline_rounded,
              size: AppDimensions.spacingL,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(
        AppDimensions.detailCardPadding,
        0,
        AppDimensions.detailCardPadding,
        AppDimensions.detailCardPadding,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                    side: BorderSide(color: AppColors.borderStrong),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: AppDimensions.spacingM,
                  ),
                  label: Text(
                    cancelLabel,
                    style: AppTextStyles.action.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                    backgroundColor: isDestructive
                        ? colorScheme.error
                        : AppColors.bleuArdoise,
                    foregroundColor: isDestructive
                        ? colorScheme.onError
                        : AppColors.blancCasse,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(
                    isDestructive
                        ? Icons.delete_outline_rounded
                        : Icons.check_rounded,
                    size: AppDimensions.spacingM,
                  ),
                  label: Text(
                    confirmLabel,
                    style: AppTextStyles.action.copyWith(
                      color: isDestructive
                          ? colorScheme.onError
                          : AppColors.blancCasse,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool isDestructive = false,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );

  return result ?? false;
}
