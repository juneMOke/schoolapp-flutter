import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Deux lignes : les absences (non justifiées d'abord, à l'encre de
/// l'absence), puis les retards et leurs minutes.
class HrPresenceRecapAbsences extends StatelessWidget {
  final int justified;
  final int unjustified;
  final int late;
  final int lateMinutes;

  /// L'encre du pied de tableau, posé sur le bandeau d'en-tête.
  final Color? ink;

  const HrPresenceRecapAbsences({
    super.key,
    required this.justified,
    required this.unjustified,
    required this.late,
    required this.lateMinutes,
    this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = this.ink;
    final base = EteeloColumnTableRow.figures(color: ink);
    final parts = [
      if (unjustified > 0)
        TextSpan(
          text: l10n.hrPresenceRecapUnjustified(unjustified),
          style: base.copyWith(
            color: ink ?? AppColors.presenceMarkAbsentInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      if (justified > 0)
        TextSpan(
          text: l10n.hrPresenceRecapJustified(justified),
          style: base.copyWith(color: ink ?? AppColors.textSecondary),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (parts.isEmpty)
          Text(
            l10n.hrPresenceRecapNoAbsence,
            style: base.copyWith(color: ink ?? AppColors.textMutedAa),
          )
        else
          Text.rich(
            TextSpan(
              children: [
                for (final (i, part) in parts.indexed) ...[
                  if (i > 0) TextSpan(text: ' · ', style: base),
                  part,
                ],
              ],
            ),
          ),
        if (late > 0)
          Text(
            l10n.hrPresenceRecapLates(late, lateMinutes),
            style: AppTypography.bodySmall.copyWith(
              color: ink ?? AppColors.presenceMarkLateInk,
            ),
          ),
      ],
    );
  }
}
