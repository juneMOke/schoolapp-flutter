import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Onglets de période (spec §2) : un seul actif (bleu ardoise plein). Premier
/// niveau de la hiérarchie — on n'affiche qu'une période à la fois.
class CoursPeriodeTabs extends StatelessWidget {
  final List<PeriodeVm> periodes;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const double _minTabWidth = 220;

  const CoursPeriodeTabs({
    super.key,
    required this.periodes,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final width = constraints.maxWidth;
        final rawColumns = (width + gap) ~/ (_minTabWidth + gap);
        final columns = rawColumns < 1
            ? 1
            : (rawColumns > periodes.length ? periodes.length : rawColumns);
        final tabWidth = columns <= 1
            ? width
            : (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < periodes.length; i++)
              SizedBox(
                width: tabWidth,
                child: _Tab(
                  periode: periodes[i],
                  active: i == selectedIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final PeriodeVm periode;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.periode,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statutVisual = bucketStatutVisual(periode.statut);
    final label = periodeLabel(l10n, periode);

    return Semantics(
      button: true,
      selected: active,
      label: '$label, ${statutLabel(l10n, periode.statut)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: active ? AppColors.bleuArdoise : AppColors.surfaceRaised,
              borderRadius: AppRadius.brLg,
              border: Border.all(
                color: active ? AppColors.bleuArdoise : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _Medallion(ordre: periode.ordre, active: active),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.titleSmall.copyWith(
                          color: active
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      _StatutLine(
                        statut: periode.statut,
                        color: active
                            ? AppColors.textOnDark.withValues(alpha: 0.82)
                            : AppColors.textMuted,
                        dotColor: active
                            ? AppColors.textOnDark
                            : statutVisual.color,
                        label: statutLabel(l10n, periode.statut),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  final int ordre;
  final bool active;

  const _Medallion({required this.ordre, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? AppColors.textOnDark.withValues(alpha: 0.16)
            : AppColors.bleuProfond,
        borderRadius: AppRadius.brMd,
      ),
      child: Text(
        '$ordre',
        style: AppTypography.titleSmall.copyWith(
          color: active ? AppColors.textOnDark : AppColors.orDoux,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _StatutLine extends StatelessWidget {
  final BucketStatut statut;
  final Color color;
  final Color dotColor;
  final String label;

  const _StatutLine({
    required this.statut,
    required this.color,
    required this.dotColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (statut == BucketStatut.current)
          NotationPulseDot(color: dotColor)
        else
          Icon(
            statut == BucketStatut.closed
                ? Icons.check_rounded
                : Icons.calendar_today_rounded,
            size: 11,
            color: color,
          ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
