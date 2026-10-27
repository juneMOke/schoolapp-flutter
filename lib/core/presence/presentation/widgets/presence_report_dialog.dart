import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_card_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_row.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_unmarked_choice.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_unmarked_list.dart';
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

/// Valider la journée, en modale carte ([EteeloCardDialog]) : la date en
/// tête, les compteurs, la liste des non pointés, les avertissements, puis
/// Annuler / Valider.
///
/// Avec [unmarkedOptional], le sort des non pointés se choisit
/// explicitement ([PresenceUnmarkedChoice]) et « Valider » reste éteint tant
/// qu'il ne l'est pas ; sans, ils sont marqués présents d'office et la
/// modale le dit ([unmarkedLabel]).
class PresenceReportDialog extends StatefulWidget {
  /// « Mardi 27 octobre 2026 ».
  final String dayLabel;

  /// « Valider le rapport du jour ».
  final String title;
  final int present;
  final int late;
  final int absent;

  /// Ceux qu'on peut marquer présents d'office, dans l'ordre du registre.
  final List<PresenceRowView> unmarked;

  /// Retards et absences sans justification.
  final int unjustified;

  /// La phrase du marquage d'office ; lue seulement sans [unmarkedOptional].
  final String? unmarkedLabel;
  final bool unmarkedOptional;
  final String lockMessage;
  final String confirmLabel;

  const PresenceReportDialog({
    super.key,
    required this.dayLabel,
    required this.title,
    required this.present,
    required this.late,
    required this.absent,
    required this.unmarked,
    required this.unjustified,
    required this.lockMessage,
    required this.confirmLabel,
    this.unmarkedLabel,
    this.unmarkedOptional = true,
  });

  @override
  State<PresenceReportDialog> createState() => _PresenceReportDialogState();
}

class _PresenceReportDialogState extends State<PresenceReportDialog> {
  /// `null` tant que le sort des non pointés n'est pas choisi.
  bool? _markRemaining;

  bool get _hasUnmarked => widget.unmarked.isNotEmpty;

  bool get _marks => !widget.unmarkedOptional || (_markRemaining ?? false);

  bool get _canSubmit =>
      !_hasUnmarked || !widget.unmarkedOptional || _markRemaining != null;

  void _submit() => Navigator.of(
    context,
  ).pop(PresenceReportChoice(markRemaining: _marks && _hasUnmarked));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final submit = _canSubmit ? _submit : null;
    return EteeloCardDialog(
      eyebrow: widget.title,
      title: widget.dayLabel,
      onSubmit: submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PresenceCountRow(
            present: widget.present + (_marks ? widget.unmarked.length : 0),
            late: widget.late,
            absent: widget.absent,
          ),
          if (_hasUnmarked) ...[
            const SizedBox(height: AppSpacing.lg),
            PresenceUnmarkedList(
              people: widget.unmarked,
              onReview: () => Navigator.of(
                context,
              ).pop(const PresenceReportChoice.reviewUnmarked()),
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.unmarkedOptional)
              PresenceUnmarkedChoice(
                value: _markRemaining,
                onChanged: (value) => setState(() => _markRemaining = value),
              )
            else if (widget.unmarkedLabel case final label?)
              PresenceWarning(
                icon: Icons.how_to_reg_outlined,
                tone: PresenceStatus.none,
                message: label,
              ),
          ],
          if (widget.unjustified > 0) ...[
            const SizedBox(height: AppSpacing.md),
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
        EteeloButton.secondary(
          label: l10n.presenceMarkCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        EteeloButton.primary(
          label: widget.confirmLabel,
          icon: Icons.task_alt,
          onPressed: submit,
        ),
      ],
    );
  }
}
