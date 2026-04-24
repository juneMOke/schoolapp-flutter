import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

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
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = theme.textTheme;
    final iconColor = isDestructive
        ? colorScheme.error
        : colorScheme.primary;
    final iconBackgroundColor = isDestructive
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingL,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        AppDimensions.spacingL,
        AppDimensions.spacingL,
        AppDimensions.spacingS,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        0,
        AppDimensions.spacingL,
        AppDimensions.spacingM,
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: AppDimensions.spacingM,
            backgroundColor: iconBackgroundColor,
            child: Icon(
              isDestructive
                  ? Icons.warning_amber_rounded
                  : Icons.help_outline_rounded,
              size: AppDimensions.spacingM,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowButtonSpacing: AppDimensions.spacingS,
      actionsPadding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingM,
        0,
        AppDimensions.spacingM,
        AppDimensions.spacingM,
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close_rounded, size: AppDimensions.spacingM),
          label: Text(cancelLabel),
        ),
        FilledButton.icon(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          icon: Icon(
            isDestructive ? Icons.delete_outline_rounded : Icons.check_rounded,
            size: AppDimensions.spacingM,
          ),
          label: Text(confirmLabel),
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
}) async {
  final result = await showDialog<bool>(
    context: context,
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
