import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/extreme_eleve.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe_stats.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de synthèse de classe (spec §3) : moyenne (médaillon), répartition
/// réussites / échecs / non classés (pastilles + barre empilée), et deux
/// extrêmes (meilleure / plus basse note) avec l'élève concerné.
class ResultatsSyntheseCard extends StatelessWidget {
  final ResultatsClasseStats stats;
  final String periodeLongLabel;

  const ResultatsSyntheseCard({
    super.key,
    required this.stats,
    required this.periodeLongLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ResultatsCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _moyenneBlock(l10n),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
            child: _repartitionBlock(l10n),
          ),
          if (stats.best != null || stats.worst != null) _extremesBlock(l10n),
        ],
      ),
    );
  }

  Widget _moyenneBlock(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.bleuArdoiseSoft,
            borderRadius: AppRadius.brLg,
          ),
          child: const Icon(
            Icons.percent_rounded,
            color: AppColors.bleuArdoise,
            size: 26,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resultatsPercent(l10n, stats.moyenneClasse),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.bleuProfond,
                ),
              ),
              Text(
                l10n.resultatsSummaryAverageCaption(periodeLongLabel),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _repartitionBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendDot(
              color: AppColors.vertSavane,
              label: l10n.resultatsSummaryReussites(stats.reussites),
            ),
            _LegendDot(
              color: AppColors.error,
              label: l10n.resultatsSummaryEchecs(stats.echecs),
            ),
            _LegendDot(
              color: AppColors.borderStrong,
              label: l10n.resultatsSummaryNonClasses(stats.nonClasses),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _StackedBar(
          reussites: stats.reussites,
          echecs: stats.echecs,
          nonClasses: stats.nonClasses,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.resultatsSummaryFootnote(stats.effectif, stats.seuil.round()),
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _extremesBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stats.best != null)
          _ExtremeRow(
            icon: Icons.trending_up_rounded,
            color: AppColors.vertSavane,
            eleve: stats.best!,
            l10n: l10n,
          ),
        if (stats.best != null && stats.worst != null)
          const SizedBox(height: AppSpacing.xs),
        if (stats.worst != null)
          _ExtremeRow(
            icon: Icons.trending_down_rounded,
            color: AppColors.error,
            eleve: stats.worst!,
            l10n: l10n,
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StackedBar extends StatelessWidget {
  final int reussites;
  final int echecs;
  final int nonClasses;

  const _StackedBar({
    required this.reussites,
    required this.echecs,
    required this.nonClasses,
  });

  @override
  Widget build(BuildContext context) {
    final total = reussites + echecs + nonClasses;
    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: SizedBox(
        height: 8,
        child: total == 0
            ? const ColoredBox(color: AppColors.surfaceAlt)
            : Row(
                children: [
                  if (reussites > 0)
                    Expanded(
                      flex: reussites,
                      child: const ColoredBox(color: AppColors.vertSavane),
                    ),
                  if (echecs > 0)
                    Expanded(
                      flex: echecs,
                      child: const ColoredBox(color: AppColors.error),
                    ),
                  if (nonClasses > 0)
                    Expanded(
                      flex: nonClasses,
                      child: const ColoredBox(color: AppColors.borderStrong),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ExtremeRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final ExtremeEleve eleve;
  final AppLocalizations l10n;

  const _ExtremeRow({
    required this.icon,
    required this.color,
    required this.eleve,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            eleve.nomComplet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          resultatsPercent(l10n, eleve.pourcentage),
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
