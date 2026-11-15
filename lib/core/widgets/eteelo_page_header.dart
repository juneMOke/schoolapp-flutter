import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// L'en-tête d'un écran : sur-titre, titre, sous-titre et actions (né dans
/// Communication, partagé depuis la Trésorerie).
/// Il reste visible dans tous les états, chargement et erreur compris.
class EteeloPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Le style du titre, quand la spec d'un écran en impose un autre (la
  /// Trésorerie : Lora 32, bleu profond). `null` — le défaut — : titre de
  /// section habituel.
  final TextStyle? titleStyle;

  const EteeloPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.terreCuite,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              header: true,
              child: Text(
                title,
                style:
                    titleStyle ??
                    AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        if (actions.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: actions,
          ),
      ],
    );
  }
}
