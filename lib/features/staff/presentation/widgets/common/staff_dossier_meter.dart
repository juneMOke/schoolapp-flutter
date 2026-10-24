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
  /// Une case par pièce exigée, vraie quand elle est versée.
  final List<bool> _slots;

  StaffDossierMeter({super.key, required StaffDossier dossier})
    : _slots = [
        for (final type in dossier.required)
          dossier.filled.contains(type.rawCode),
      ];

  /// Le dossier tel qu'un compte le dit (`3 sur 4`, servi par le serveur) :
  /// les pièces versées d'abord.
  StaffDossierMeter.counts({super.key, required int done, required int total})
    : _slots = [for (var i = 0; i < total; i++) i < done];

  static const double _barWidth = 12;
  static const double _barHeight = 5;

  @override
  Widget build(BuildContext context) {
    final total = _slots.length;
    if (total == 0) return const SizedBox.shrink();
    final done = _slots.where((filled) => filled).length;
    final l10n = AppLocalizations.of(context)!;
    final color = done == total
        ? AppColors.success
        : done == 0
        ? AppColors.error
        : AppColors.staffPartialInk;
    final label = done == total
        ? l10n.staffDossierComplete
        : l10n.staffDossierProgress(done, total);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final filled in _slots) ...[
            Container(
              width: _barWidth,
              height: _barHeight,
              decoration: BoxDecoration(
                color: filled ? color : AppColors.border,
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
