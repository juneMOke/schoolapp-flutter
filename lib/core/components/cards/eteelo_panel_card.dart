import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une carte de surface bordée, à titre facultatif : la barre de filtres d'une
/// collection, un bloc d'onglet (calendrier, incidents, tableau). Le cadre
/// qui détache un bloc du fond de page, écrit une fois.
class EteeloPanelCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const EteeloPanelCard({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}
