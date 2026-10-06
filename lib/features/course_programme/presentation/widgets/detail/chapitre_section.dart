import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// Une section du détail d'un chapitre (spec §9) : carte sans padding,
/// en-tête (icône, titre, compteur, action à droite), contenu sous un filet.
class ChapitreSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final Widget? action;
  final Widget child;

  const ChapitreSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.count,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: ProgrammeLayout.sectionIcon,
                  color: AppColors.bleuArdoise,
                ),
                const SizedBox(width: AppSpacing.sm),
                // Le titre cède la place à l'action sur un écran étroit.
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        text: title,
                        children: [
                          if (count != null)
                            TextSpan(
                              text: '  $count',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textMuted,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                        ],
                      ),
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Sur un téléphone, l'action se resserre plutôt que de
                // déborder (quelques pour cent au plus).
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: ProgrammeLayout.sectionActionMinHeight,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: action ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

/// Le message d'une section vide.
class ChapitreSectionEmpty extends StatelessWidget {
  final String message;

  const ChapitreSectionEmpty(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Text(
      message,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
    ),
  );
}
