import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummarySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final Widget child;

  const SummarySectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.bleuArdoise.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.bleuArdoise),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.bleuArdoise,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SecondaryButton(
                  label: l10n.editEnrollment,
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                  fullWidth: false,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: child,
          ),
        ],
      ),
    );
  }
}
