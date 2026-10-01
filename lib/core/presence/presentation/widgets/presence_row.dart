import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_heading.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_row_controls.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_status_segment.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les colonnes d'une ligne de registre, partagées par l'en-tête et les
/// lignes pour qu'elles s'alignent au pixel. [hours] n'existe qu'au Pointage
/// (vacataires à l'heure).
class PresenceRowLayout extends StatelessWidget {
  final Widget person;
  final Widget status;
  final Widget times;
  final Widget? hours;
  final Widget late;
  final Widget action;

  const PresenceRowLayout({
    super.key,
    required this.person,
    required this.status,
    required this.times,
    required this.late,
    required this.action,
    this.hours,
  });

  @override
  Widget build(BuildContext context) {
    final hours = this.hours;
    return Row(
      children: [
        Expanded(flex: 6, child: person),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: AppDimensions.presenceMarkColStatus, child: status),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: AppDimensions.presenceMarkColTimes, child: times),
        if (hours != null) ...[
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: AppDimensions.presenceMarkColHours, child: hours),
        ],
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 5, child: late),
        SizedBox(width: AppDimensions.presenceMarkColAction, child: action),
      ],
    );
  }
}

/// Une ligne de registre : filet gauche et voile dans la teinte du statut.
///
/// [times] remplace la seule arrivée (le Pointage y met arrivée et départ) ;
/// [hours] ajoute la colonne des heures prestées.
class PresenceRow extends StatelessWidget {
  final PresenceRowView row;
  final PresenceRowActions actions;
  final Widget? times;
  final Widget? hours;
  final Widget? badge;

  const PresenceRow({
    super.key,
    required this.row,
    required this.actions,
    this.times,
    this.hours,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceTone.of(row.status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        border: Border(
          left: BorderSide(
            color: tone.color,
            width: AppDimensions.presenceMarkAccentWidth,
          ),
        ),
        gradient: LinearGradient(
          colors: [tone.soft, AppColors.surfaceRaised],
          stops: const [0, AppDimensions.presenceMarkRowTintStop],
        ),
      ),
      child: PresenceRowLayout(
        person: PresencePersonHeading(row: row, trailing: badge),
        status: PresenceStatusSegment(
          status: row.status,
          onChoose: actions.choose,
        ),
        times: !row.status.hasArrival
            ? const SizedBox.shrink()
            : times ??
                  PresenceTimeButton(
                    label: l10n.presenceMarkArrival,
                    time: row.arrival,
                    onTap: () => actions.editArrival(),
                  ),
        hours: hours,
        late: _LateCell(row: row, onJustify: () => actions.justify()),
        action: PresenceRetryButton(row: row, onRetry: actions.retry),
      ),
    );
  }
}

class _LateCell extends StatelessWidget {
  final PresenceRowView row;
  final VoidCallback onJustify;

  const _LateCell({required this.row, required this.onJustify});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceTone.of(row.status);
    final text = switch (row.status) {
      PresenceStatus.none => l10n.presenceMarkNotMarked,
      PresenceStatus.present => l10n.presenceMarkOnTimeShort,
      PresenceStatus.late => '+${l10n.presenceMarkMinutes(row.lateMinutes)}',
      PresenceStatus.absent => null,
    };
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (text != null)
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(color: tone.ink),
          ),
        if (row.status.isIncident)
          PresenceJustifyButton(row: row, onTap: onJustify),
      ],
    );
  }
}
