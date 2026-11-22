import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// La légende des domaines, teintée et cliquable : un domaine filtre la page,
/// le toucher à nouveau annule ; « Tous les domaines » efface le filtre.
class DomainLegend extends StatelessWidget {
  final Map<String, String> domains;
  final List<String> order;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String clearLabel;

  const DomainLegend({
    super.key,
    required this.domains,
    required this.order,
    required this.selected,
    required this.onSelected,
    required this.clearLabel,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final MapEntry(key: id, value: label) in domains.entries)
        _DomainChip(
          label: label,
          tone: CourseDomainTones.forDomain(id, order),
          selected: selected == id,
          onTap: () => onSelected(selected == id ? null : id),
        ),
      if (selected != null)
        TextButton.icon(
          onPressed: () => onSelected(null),
          icon: const Icon(Icons.close_rounded, size: AppSpacing.md),
          label: Text(clearLabel),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.terreCuiteInk,
            textStyle: AppTypography.labelSmall,
            minimumSize: const Size(
              AppDimensions.minTouchTarget,
              AppDimensions.minTouchTarget,
            ),
          ),
        ),
    ],
  );
}

class _DomainChip extends StatelessWidget {
  final String label;
  final CourseDomainTone tone;
  final bool selected;
  final VoidCallback onTap;

  const _DomainChip({
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? AppColors.textOnDark : tone.strong;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        // La zone de toucher atteint 48 dp ; la puce garde sa hauteur.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.filterChipHeight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: selected ? tone.ink : tone.soft,
                borderRadius: AppRadius.brPill,
                border: Border.all(
                  color: selected
                      ? tone.ink
                      : ColorMix.tint(
                          AppColors.border,
                          tone.ink,
                          AppDimensions.timetableLegendBorderPercent,
                        ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppDimensions.timetableLegendDot,
                    height: AppDimensions.timetableLegendDot,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.textOnDark : tone.ink,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.timetableLegendDotRadius,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
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
