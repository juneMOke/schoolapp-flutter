import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Affiche une dialog de confirmation pour l'opération irréversible de paiement.
/// Retourne `true` si l'utilisateur confirme, `false` sinon.
Future<bool> showCreatePaymentConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ConfirmDialog(
      title: l10n.facturationCreatePaymentConfirmTitle,
      message: l10n.facturationCreatePaymentConfirmMessage,
      cancelLabel: l10n.facturationCreatePaymentConfirmCancel,
      confirmLabel: l10n.facturationCreatePaymentConfirmValidate,
    ),
  );

  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
      ),
      backgroundColor: AppColors.financeDetailCard,
      title: Row(
        children: [
          Container(
            width: AppDimensions.spacingL,
            height: AppDimensions.spacingL,
            decoration: BoxDecoration(
              color: AppColors.financeDetailDangerSoft,
              borderRadius: BorderRadius.circular(AppDimensions.spacingS),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: AppDimensions.detailMiniIconSize,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: AppTextStyles.action.copyWith(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.financeDetailPaymentsAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: AppTextStyles.action.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
