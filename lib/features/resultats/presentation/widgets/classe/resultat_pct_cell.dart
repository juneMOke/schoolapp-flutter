import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_score_palette.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Cellule pourcentage (spec §5) : valeur + mini-barre optionnelle, code couleur
/// autour du seuil. `null` → tiret sourdine. [showBar] masquable (spec Tweak
/// `resBars` — ici la barre n'apparaît que sur la colonne Moyenne).
class ResultatPctCell extends StatelessWidget {
  final double? pourcentage;
  final double seuil;
  final bool showBar;

  const ResultatPctCell({
    super.key,
    required this.pourcentage,
    required this.seuil,
    this.showBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = ResultatsScorePalette.toneFor(pourcentage, seuil);
    final textColor = ResultatsScorePalette.textColor(tone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          resultatsPercent(l10n, pourcentage),
          textAlign: TextAlign.right,
          style: AppTypography.bodyMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (showBar && pourcentage != null) ...[
          const SizedBox(height: 4),
          _MiniBar(
            fraction: (pourcentage! / 100).clamp(0.0, 1.0),
            color: ResultatsScorePalette.barColor(tone),
          ),
        ],
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double fraction;
  final Color color;

  const _MiniBar({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 4,
      child: ClipRRect(
        borderRadius: AppRadius.brPill,
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.surfaceAlt),
            FractionallySizedBox(
              widthFactor: fraction,
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
