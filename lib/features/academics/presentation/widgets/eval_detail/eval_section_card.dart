import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Carte d'une section du détail d'une évaluation (Sujet, Copie,
/// Publication) : titre, sous-titre, pastilles à droite, puis le corps.
///
/// Pliable quand [onToggle] est fourni : l'en-tête devient un bouton
/// (Entrée / Espace) et porte un chevron.
class EvalSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> trailing;
  final bool expanded;
  final VoidCallback? onToggle;
  final Widget child;

  const EvalSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing = const [],
    this.expanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ...trailing,
              ],
            ),
          ),
          if (onToggle != null)
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: AppMotion.standard,
              child: const Icon(
                Icons.expand_more_rounded,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onToggle == null)
            header
          else
            Semantics(
              button: true,
              expanded: expanded,
              child: InkWell(onTap: onToggle, child: header),
            ),
          AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.outCurve,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
