import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête de semaine (spec §2) : titre de la « semaine type » (l'emploi du
/// temps est **récurrent**, sans dates) et compteur de charge — nombre de
/// séances et heures de cours cumulées. N'est affiché qu'en état `ready` avec au
/// moins une séance (contrôlé par l'appelant).
class ScheduleWeekHeader extends StatelessWidget {
  final int sessionCount;
  final double hours;

  const ScheduleWeekHeader({
    super.key,
    required this.sessionCount,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      header: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            l10n.scheduleWeekTitle,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            l10n.scheduleLoadSummary(sessionCount, hours),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
