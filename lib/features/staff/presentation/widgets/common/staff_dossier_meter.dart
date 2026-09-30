import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_dossier.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Jauge du dossier : une barre par pièce exigée, et « Dossier complet » ou
/// « 2/4 pièces ». Verte complète, ambre partielle, rouge vide.
///
/// Rien ne s'affiche quand les pièces exigées ne sont pas encore connues
/// (référentiel pas descendu) : on ne mesure pas contre une liste vide.
class StaffDossierMeter extends StatelessWidget {
  final StaffDossier dossier;

  const StaffDossierMeter({super.key, required this.dossier});

  static const double _barWidth = 12;
  static const double _barHeight = 5;

  @override
  Widget build(BuildContext context) {
    if (!dossier.isKnown) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final color = dossier.isComplete
        ? AppColors.success
        : dossier.isEmpty
        ? AppColors.error
        : AppColors.staffPartialInk;
    final label = dossier.isComplete
        ? l10n.staffDossierComplete
        : l10n.staffDossierProgress(dossier.done, dossier.total);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in dossier.required) ...[
            Container(
              width: _barWidth,
              height: _barHeight,
              decoration: BoxDecoration(
                color: dossier.filled.contains(type.rawCode)
                    ? color
                    : AppColors.border,
                borderRadius: BorderRadius.circular(_barHeight / 2),
              ),
            ),
            const SizedBox(width: AppSpacing.xs / 2),
          ],
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
