import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_row.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_unmarked_notice.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la modale de validation : valider, en marquant ou non les
/// personnes encore « à pointer » — ou revenir au registre pour les voir
/// ([reviewUnmarked]), sans rien valider.
class PresenceReportChoice {
  final bool markRemaining;
  final bool reviewUnmarked;

  const PresenceReportChoice({required this.markRemaining})
    : reviewUnmarked = false;

  /// Ne rien valider : revenir au registre filtré sur les non pointés.
  const PresenceReportChoice.reviewUnmarked()
    : markRemaining = false,
      reviewUnmarked = true;
}

/// Valider la journée : le résumé, les avertissements, et le sort des non
/// pointés.
///
/// Les non pointés sont nommés ([unmarkedNames]) en tête, avec un retour au
/// registre filtré sur eux. Avec [unmarkedOptional], une case — décochée par
/// défaut : marquer présent est un choix, jamais un réflexe — laisse choisir
/// de les marquer présents ; sans, ils le sont d'office et la modale le dit
/// ([unmarkedLabel] porte alors la phrase).
class PresenceReportDialog extends StatefulWidget {
  final String eyebrow;
  final String title;
  final int present;
  final int late;
  final int absent;

  /// Ceux qu'on peut marquer présents d'office.
  final int unmarked;

  /// Leurs noms, dans l'ordre du registre.
  final List<String> unmarkedNames;

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
    this.unmarkedNames = const [],
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
  bool _markRemaining = false;

  bool get _marks => _markRemaining || !widget.unmarkedOptional;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unmarked = widget.unmarked;
    final present = widget.present + (_marks ? unmarked : 0);
    void submit() => Navigator.of(
      context,
    ).pop(PresenceReportChoice(markRemaining: _marks && unmarked > 0));
    return EteeloFormDialog(
      onSubmit: submit,
      eyebrow: widget.eyebrow,
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PresenceCountRow(
            present: present,
            late: widget.late,
            absent: widget.absent,
          ),
          if (unmarked > 0) ...[
            const SizedBox(height: AppSpacing.md),
            if (widget.unmarkedNames.isNotEmpty) ...[
              PresenceUnmarkedNotice(
                names: widget.unmarkedNames,
                onReview: () => Navigator.of(
                  context,
                ).pop(const PresenceReportChoice.reviewUnmarked()),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
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
          onPressed: submit,
          fullWidth: false,
        ),
      ],
    );
  }
}
