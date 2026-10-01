import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la modale de justification : une justification, ou son
/// retrait ([justification] `null`).
class PresenceJustificationChoice<R extends Object> {
  final PresenceJustification<R>? justification;

  const PresenceJustificationChoice(this.justification);
}

/// Justifier un retard ou une absence : un motif parmi [reasons] (requis),
/// une précision. La pièce jointe est reportée en V1.1 : ni Numériser, ni
/// Importer. Chaque module passe sa liste de motifs et leurs libellés.
class PresenceJustificationDialog<R extends Object> extends StatefulWidget {
  final String name;
  final PresenceStatus status;
  final int lateMinutes;

  /// Le jour, en toutes lettres, pour le surtitre.
  final String dayLabel;
  final PresenceJustification<R>? initial;
  final List<R> reasons;
  final String Function(R reason) reasonLabel;

  const PresenceJustificationDialog({
    super.key,
    required this.name,
    required this.status,
    required this.lateMinutes,
    required this.dayLabel,
    required this.initial,
    required this.reasons,
    required this.reasonLabel,
  });

  @override
  State<PresenceJustificationDialog<R>> createState() =>
      _PresenceJustificationDialogState<R>();
}

class _PresenceJustificationDialogState<R extends Object>
    extends State<PresenceJustificationDialog<R>> {
  late R? _reason = widget.initial?.reason;
  late final TextEditingController _note = TextEditingController(
    text: widget.initial?.note ?? '',
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _eyebrow(AppLocalizations l10n) => [
    PresenceLabels.status(l10n, widget.status),
    if (widget.status == PresenceStatus.late)
      '+${l10n.presenceMarkMinutes(widget.lateMinutes)}',
    widget.dayLabel,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceTone.of(widget.status);
    final reason = _reason;
    return EteeloFormDialog(
      eyebrow: _eyebrow(l10n),
      title: l10n.presenceMarkJustifyTitle(widget.name),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.presenceMarkReasonLabel} *',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final value in widget.reasons)
                EteeloFilterChip(
                  label: widget.reasonLabel(value),
                  selected: value == reason,
                  color: tone.color,
                  soft: tone.soft,
                  ink: tone.ink,
                  onTap: () => setState(() => _reason = value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          EteeloTextInput(
            controller: _note,
            label: l10n.presenceMarkNoteLabel,
            placeholder: l10n.presenceMarkNotePlaceholder,
            keyboardType: EteeloTextInputType.multiline,
            minLines: 2,
            maxLines: 4,
            // Coupé à la frappe, en caractères entiers : jamais de
            // troncature silencieuse au milieu d'un emoji.
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                PresenceJustification.maxNoteLength,
              ),
            ],
          ),
        ],
      ),
      leading: widget.initial != null
          ? EteeloButton.ghost(
              label: l10n.presenceMarkRemoveJustification,
              icon: Icons.delete_outline,
              onPressed: () => Navigator.of(
                context,
              ).pop(PresenceJustificationChoice<R>(null)),
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
          onPressed: reason == null ? null : () => _save(reason),
          fullWidth: false,
        ),
      ],
    );
  }

  void _save(R reason) {
    final note = _note.text.trim();
    Navigator.of(context).pop(
      PresenceJustificationChoice<R>(
        PresenceJustification<R>(
          reason: reason,
          note: note.isEmpty ? null : note,
        ),
      ),
    );
  }
}
