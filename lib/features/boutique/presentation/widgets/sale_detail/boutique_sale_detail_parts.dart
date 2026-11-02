import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Les briques de la fiche d'une vente : la carte, le titre de section, la
/// ligne « libellé — valeur ».
class BoutiqueSaleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BoutiqueSaleCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingM,
      vertical: AppDimensions.spacingS,
    ),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class BoutiqueSaleSectionTitle extends StatelessWidget {
  final String label;

  const BoutiqueSaleSectionTitle({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textMutedAa,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w600,
    ),
  );
}

class BoutiqueSaleInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  const BoutiqueSaleInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
                color: muted ? AppColors.textMutedAa : AppColors.bleuProfond,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
