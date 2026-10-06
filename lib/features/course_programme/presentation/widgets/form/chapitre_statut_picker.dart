import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_statut_visual.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// L'état d'avancement en trois tuiles (icône + libellé), un groupe radio.
class ChapitreStatutPicker extends StatelessWidget {
  final ChapitreStatut value;
  final ValueChanged<ChapitreStatut> onChanged;

  const ChapitreStatutPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.chapitreFormStatutLabel,
      child: Row(
        children: [
          for (final statut in ChapitreStatut.values) ...[
            if (statut != ChapitreStatut.values.first)
              const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Tile(
                statut: statut,
                selected: statut == value,
                onTap: () => onChanged(statut),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final ChapitreStatut statut;
  final bool selected;
  final VoidCallback onTap;

  const _Tile({
    required this.statut,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = ChapitreStatutVisual.of(statut);
    final label = ChapitreStatutVisual.label(
      AppLocalizations.of(context)!,
      statut,
    );
    final ink = selected ? visual.accent : AppColors.textSecondary;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: selected ? visual.soft : AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: selected ? visual.accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.brMd,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                children: [
                  Icon(
                    visual.icon,
                    size: ProgrammeLayout.iconMedium,
                    color: ink,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
