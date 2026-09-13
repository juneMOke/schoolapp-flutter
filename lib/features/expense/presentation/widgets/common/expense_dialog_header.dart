import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête des deux modales du module : sur-titre, titre, sous-titre, croix.
class ExpenseDialogHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  const ExpenseDialogHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        AppDimensions.spacingM,
        AppDimensions.spacingS,
        AppDimensions.spacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: AppTextStyles.tableHeader.copyWith(
                    color: AppColors.terreCuite,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.expenseDialogClose,
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
