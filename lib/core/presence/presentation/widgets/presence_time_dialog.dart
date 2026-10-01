import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_rules.dart';
import 'package:school_app_flutter/core/presence/presentation/clock_input_formatter.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_arrival_preview.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la modale d'heure : une heure, ou l'effacement du départ.
class PresenceTimeChoice {
  final ClockTime? time;

  const PresenceTimeChoice(this.time);
}

/// Un raccourci d'heure : un libellé et l'heure qu'il pose.
class PresenceTimeShortcut {
  final String label;
  final ClockTime time;

  const PresenceTimeShortcut(this.label, this.time);

  /// Les raccourcis d'une arrivée, communs à l'appel et au pointage :
  /// [now] (l'heure du geste, ou le début des cours pour un autre jour), le
  /// début des cours, puis +15 et +30 minutes.
  static List<PresenceTimeShortcut> arrivals(
    AppLocalizations l10n,
    PresenceSchedule schedule,
    ClockTime now,
  ) => [
    PresenceTimeShortcut(l10n.presenceMarkTimeNow, now),
    PresenceTimeShortcut(l10n.presenceMarkTimeStart, schedule.start),
    for (final minutes in const [15, 30])
      PresenceTimeShortcut(
        l10n.presenceMarkTimePlus(minutes),
        schedule.start.plus(minutes),
      ),
  ];
}

/// Saisie de l'heure d'arrivée ou de départ. Pour l'arrivée, [schedule]
/// donne l'aperçu du classement (présent ou en retard) avant d'enregistrer.
class PresenceTimeDialog extends StatefulWidget {
  final String title;
  final ClockTime? initial;
  final List<PresenceTimeShortcut> shortcuts;

  /// Réglages du classement : aperçu seulement pour l'arrivée.
  final PresenceSchedule? schedule;

  /// Propose « Effacer » (un départ existant).
  final bool canClear;

  const PresenceTimeDialog({
    super.key,
    required this.title,
    required this.shortcuts,
    this.initial,
    this.schedule,
    this.canClear = false,
  });

  @override
  State<PresenceTimeDialog> createState() => _PresenceTimeDialogState();
}

class _PresenceTimeDialogState extends State<PresenceTimeDialog> {
  late final TextEditingController _field = TextEditingController(
    text: widget.initial?.wire ?? '',
  );

  ClockTime? get _time => ClockTime.tryParse(_field.text);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _pick(ClockTime time) => setState(() => _field.text = time.wire);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = _time;
    final schedule = widget.schedule;
    return EteeloFormDialog(
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EteeloTextInput(
            controller: _field,
            label: l10n.presenceMarkTimeField,
            placeholder: widget.shortcuts.isEmpty
                ? null
                : widget.shortcuts.first.time.wire,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            inputFormatters: const [ClockInputFormatter()],
            errorText: _field.text.length == 5 && time == null
                ? l10n.presenceMarkTimeInvalid
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final shortcut in widget.shortcuts)
                EteeloButton.secondary(
                  label: shortcut.label,
                  onPressed: () => _pick(shortcut.time),
                  fullWidth: false,
                ),
            ],
          ),
          if (schedule != null && time != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PresenceArrivalPreview(
              result: PresenceRules(schedule).classify(time),
              schedule: schedule,
            ),
          ],
        ],
      ),
      leading: widget.canClear
          ? EteeloButton.ghost(
              label: l10n.presenceMarkTimeClear,
              icon: Icons.backspace_outlined,
              onPressed: () =>
                  Navigator.of(context).pop(const PresenceTimeChoice(null)),
              fullWidth: false,
            )
          : null,
      actions: [
        EteeloButton.ghost(
          label: l10n.presenceMarkCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.presenceMarkSave,
          icon: Icons.check,
          onPressed: time == null
              ? null
              : () => Navigator.of(context).pop(PresenceTimeChoice(time)),
          fullWidth: false,
        ),
      ],
    );
  }
}
