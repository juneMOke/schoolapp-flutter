import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un compteur dans la teinte d'un statut : le résumé du rapport journalier,
/// et les indicateurs de la fiche mensuelle.
class PresenceCountTile extends StatelessWidget {
  final PresenceStatus tone;
  final String label;
  final String value;
  final String? detail;

  const PresenceCountTile({
    super.key,
    required this.tone,
    required this.label,
    required this.value,
    this.detail,
  });

  /// Les retards d'un mois : nombre, minutes cumulées, non justifiés.
  PresenceCountTile.lates(
    AppLocalizations l10n, {
    super.key,
    required int count,
    required int minutes,
    required int unjustified,
  }) : tone = PresenceStatus.late,
       label = l10n.presenceMarkKpiLates,
       value = '$count',
       detail = l10n.presenceMarkKpiLatesDetail(minutes, unjustified);

  /// Les absences d'un mois : nombre, justifiées et non justifiées.
  PresenceCountTile.absences(
    AppLocalizations l10n, {
    super.key,
    required int count,
    required int justified,
    required int unjustified,
  }) : tone = PresenceStatus.absent,
       label = l10n.presenceMarkKpiAbsences,
       value = '$count',
       detail = l10n.presenceMarkKpiAbsencesDetail(justified, unjustified);

  @override
  Widget build(BuildContext context) {
    final colors = PresenceTone.of(tone);
    final detail = this.detail;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(colors.icon, size: AppSpacing.lg, color: colors.ink),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(color: colors.ink),
          ),
          if (detail != null)
            Text(
              detail,
              style: AppTypography.bodySmall.copyWith(color: colors.ink),
            ),
        ],
      ),
    );
  }
}
