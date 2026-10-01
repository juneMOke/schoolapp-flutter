import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_heading.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_row_controls.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte d'une personne dans la grille d'un registre. **Toute** la carte
/// fait avancer le cycle (présent › en retard › absent) ; les boutons du pied
/// ont leur propre geste et ne font pas avancer le cycle.
///
/// [timeExtras] s'ajoutent à l'arrivée tant que le statut en porte une (le
/// départ et les heures prestées du Pointage) ; [badge] se pose à droite de
/// l'en-tête.
class PresenceCard extends StatelessWidget {
  final PresenceRowView row;
  final PresenceRowActions actions;
  final PresenceSchedule schedule;
  final List<Widget> timeExtras;
  final Widget? badge;

  const PresenceCard({
    super.key,
    required this.row,
    required this.actions,
    required this.schedule,
    this.timeExtras = const [],
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final tone = PresenceTone.of(row.status);
    final unmarked = row.status == PresenceStatus.none;
    return Material(
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(
          color: unmarked ? tone.border : tone.color,
          width: AppDimensions.presenceMarkBorderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actions.cycle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [tone.soft, AppColors.surfaceRaised],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PresencePersonHeading(row: row, trailing: badge),
                const SizedBox(height: AppSpacing.md),
                _StatusBlock(row: row, schedule: schedule),
                const SizedBox(height: AppSpacing.md),
                _Footer(row: row, actions: actions, timeExtras: timeExtras),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  final PresenceRowView row;
  final PresenceSchedule schedule;

  const _StatusBlock({required this.row, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceTone.of(row.status);
    return Row(
      children: [
        AnimatedContainer(
          // Le médaillon change de teinte au pointage ; mouvement réduit
          // respecté.
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.pop,
          curve: AppMotion.outCurve,
          width: AppDimensions.presenceMarkMedallionSize,
          height: AppDimensions.presenceMarkMedallionSize,
          decoration: BoxDecoration(color: tone.color, shape: BoxShape.circle),
          child: Icon(
            tone.icon,
            color: AppColors.textOnDark,
            size: AppDimensions.presenceMarkMedallionIconSize,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PresenceLabels.status(l10n, row.status),
                style: AppTypography.titleMedium.copyWith(color: tone.ink),
              ),
              Text(
                presenceStatusDetail(l10n, row, schedule),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final PresenceRowView row;
  final PresenceRowActions actions;
  final List<Widget> timeExtras;

  const _Footer({
    required this.row,
    required this.actions,
    required this.timeExtras,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = row.status;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (status.hasArrival) ...[
          PresenceTimeButton(
            label: l10n.presenceMarkArrival,
            time: row.arrival,
            onTap: () => actions.editArrival(),
          ),
          ...timeExtras,
        ],
        if (status.isIncident)
          PresenceJustifyButton(row: row, onTap: () => actions.justify()),
        PresenceRetryButton(row: row, onRetry: actions.retry),
        if (status.isMarked)
          PresenceSquareIconButton(
            icon: Icons.rotate_left,
            tooltip: l10n.presenceMarkClearTooltip,
            onPressed: actions.clear,
          ),
      ],
    );
  }
}
