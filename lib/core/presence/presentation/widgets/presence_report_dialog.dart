import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_tile.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la modale de validation : valider, en marquant ou non les
/// personnes encore « à pointer ».
class PresenceReportChoice {
  final bool markRemaining;

  const PresenceReportChoice({required this.markRemaining});
}

/// Valider la journée : le résumé, les avertissements, et le sort des non
/// pointés.
///
/// Avec [unmarkedOptional], une case (cochée par défaut) laisse choisir de les
/// marquer présents ; sans, ils le sont d'office et la modale le dit
/// ([unmarkedLabel] porte alors la phrase).
class PresenceReportDialog extends StatefulWidget {
  final String eyebrow;
  final String title;
  final int present;
  final int late;
  final int absent;

  /// Ceux qu'on peut marquer présents d'office.
  final int unmarked;

  /// Retards et absences sans justification.
  final int unjustified;
  final String unmarkedLabel;
  final bool unmarkedOptional;
  final String lockMessage;
  final String confirmLabel;

  const PresenceReportDialog({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.present,
    required this.late,
    required this.absent,
    required this.unmarked,
    required this.unjustified,
    required this.unmarkedLabel,
    required this.lockMessage,
    required this.confirmLabel,
    this.unmarkedOptional = true,
  });

  @override
  State<PresenceReportDialog> createState() => _PresenceReportDialogState();
}

class _PresenceReportDialogState extends State<PresenceReportDialog> {
  bool _markRemaining = true;

  bool get _marks => _markRemaining || !widget.unmarkedOptional;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unmarked = widget.unmarked;
    final present = widget.present + (_marks ? unmarked : 0);
    Widget tile(PresenceStatus status, int value) => Expanded(
      child: PresenceCountTile(
        tone: status,
        label: PresenceLabels.filter(l10n, status),
        value: '$value',
      ),
    );
    return EteeloFormDialog(
      eyebrow: widget.eyebrow,
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              tile(PresenceStatus.present, present),
              const SizedBox(width: AppSpacing.sm),
              tile(PresenceStatus.late, widget.late),
              const SizedBox(width: AppSpacing.sm),
              tile(PresenceStatus.absent, widget.absent),
            ],
          ),
          if (unmarked > 0) ...[
            const SizedBox(height: AppSpacing.md),
            if (widget.unmarkedOptional)
              CheckboxListTile(
                value: _markRemaining,
                onChanged: (value) =>
                    setState(() => _markRemaining = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(widget.unmarkedLabel),
                subtitle: _markRemaining
                    ? null
                    : Text(l10n.presenceMarkReportUnmarkedReminder),
              )
            else
              PresenceWarning(
                icon: Icons.how_to_reg_outlined,
                tone: PresenceStatus.none,
                message: widget.unmarkedLabel,
              ),
          ],
          if (widget.unjustified > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            PresenceWarning(
              icon: Icons.warning_amber_rounded,
              message: l10n.presenceMarkReportUnjustified(widget.unjustified),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.none,
            message: widget.lockMessage,
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.presenceMarkCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: widget.confirmLabel,
          icon: Icons.task_alt,
          onPressed: () => Navigator.of(
            context,
          ).pop(PresenceReportChoice(markRemaining: _marks && unmarked > 0)),
          fullWidth: false,
        ),
      ],
    );
  }
}
