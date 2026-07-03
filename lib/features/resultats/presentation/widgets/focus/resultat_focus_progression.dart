import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/progression_point.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_score_palette.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Progression P1..Pn (spec §7) : une barre par sous-période de l'année, les
/// périodes hors groupe grisées, avec le delta de points (P dernier − P premier).
class ResultatFocusProgression extends StatelessWidget {
  final List<ProgressionPoint> progression;
  final double? deltaPts;
  final double seuil;

  const ResultatFocusProgression({
    super.key,
    required this.progression,
    required this.deltaPts,
    required this.seuil,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ResultatsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.resultatsProgressionTitle,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.bleuProfond,
                  ),
                ),
              ),
              if (deltaPts != null) _DeltaPill(deltaPts: deltaPts!, l10n: l10n),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final point in progression)
                  Expanded(
                    child: _Bar(point: point, seuil: seuil, l10n: l10n),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final ProgressionPoint point;
  final double seuil;
  final AppLocalizations l10n;

  const _Bar({required this.point, required this.seuil, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final pct = point.pourcentage;
    final inGroup = point.dansGroupe;
    final tone = ResultatsScorePalette.toneFor(pct, seuil);
    final barColor = inGroup
        ? ResultatsScorePalette.barColor(tone)
        : AppColors.surfaceAlt;
    final valueColor = inGroup ? AppColors.textPrimary : AppColors.textMuted;
    final fraction = ((pct ?? 0) / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Text(
            pct == null ? l10n.resultatsDash : '${pct.round()}',
            style: AppTypography.labelSmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: fraction,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 30),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: AppRadius.brSm,
                    border: inGroup
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.resultatsProgressionPointLabel(point.indexGlobal),
            style: AppTypography.labelSmall.copyWith(
              color: inGroup ? AppColors.bleuArdoise : AppColors.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final double deltaPts;
  final AppLocalizations l10n;

  const _DeltaPill({required this.deltaPts, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final positive = deltaPts >= 0;
    final color = positive ? AppColors.vertSavane : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: positive ? AppColors.bleuArdoiseSoft : AppColors.terreCuiteSoft,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            resultatsDelta(l10n, deltaPts),
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
