import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_keys.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_heading.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_row_controls.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_status_segment.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_table.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de registre, dans une [PresenceTable] : le statut se lit à son
/// segment, jamais au fond de la ligne (la zébrure de la table reste lisible).
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

  /// Un écart entre deux cellules : les colonnes de la table se touchent.
  static Widget _cell(Widget child) => Padding(
    padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = this.hours;
    return PresenceKeys(
      row: row,
      actions: actions,
      child: EteeloColumnTableRow(
        widths: PresenceTable.widthsOf(hours: hours != null),
        cells: [
          _cell(PresencePersonHeading(row: row, trailing: badge)),
          _cell(
            PresenceStatusSegment(status: row.status, onChoose: actions.choose),
          ),
          _cell(
            !row.status.hasArrival
                ? const SizedBox.shrink()
                : times ??
                      PresenceTimeButton(
                        label: l10n.presenceMarkArrival,
                        time: row.arrival,
                        onTap: () => actions.editArrival(),
                      ),
          ),
          if (hours != null) _cell(hours),
          _cell(_LateCell(row: row, onJustify: () => actions.justify())),
          PresenceRetryButton(row: row, onRetry: actions.retry),
        ],
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
