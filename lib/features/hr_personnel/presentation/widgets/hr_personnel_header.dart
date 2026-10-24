import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// L'en-tête d'un écran RH · Personnel sous la barre de la coquille : une
/// ligne de contexte et les actions de l'écran. Le titre, lui, est porté par
/// la barre (ou par `ModuleTopBar` hors coquille).
///
/// Il reste en place sous un vide ou une erreur : « Ouvrir le fichier » ou
/// « Nouvel agent » sont souvent ce qui en fait sortir.
class HrPersonnelHeader extends StatelessWidget {
  final String subtitle;
  final List<Widget> actions;

  const HrPersonnelHeader({
    super.key,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.sm,
    children: [
      Text(
        subtitle,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      if (actions.isNotEmpty)
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        ),
    ],
  );
}
