import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/note_saisie_visuals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bascule d'absence (spec §8) : deux boutons icône — absence justifiée (horloge
/// ambre) et non justifiée (interdit rouge). Re-cliquer désélectionne. Partagé
/// par les modes Tableau et Focus.
class AbsenceToggle extends StatelessWidget {
  /// Absence courante (`null` = aucune) ; l'une des deux valeurs d'absence.
  final StatutNote? selected;
  final ValueChanged<StatutNote> onToggle;
  final bool enabled;
  final double size;

  const AbsenceToggle({
    super.key,
    required this.selected,
    required this.onToggle,
    this.enabled = true,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AbsenceButton(
          statut: StatutNote.absentJustifie,
          selected: selected == StatutNote.absentJustifie,
          tooltip: l10n.evalAbsenceJustifieTooltip,
          enabled: enabled,
          size: size,
          onTap: () => onToggle(StatutNote.absentJustifie),
        ),
        const SizedBox(width: 5),
        _AbsenceButton(
          statut: StatutNote.absentNonJustifie,
          selected: selected == StatutNote.absentNonJustifie,
          tooltip: l10n.evalAbsenceNonJustifieTooltip,
          enabled: enabled,
          size: size,
          onTap: () => onToggle(StatutNote.absentNonJustifie),
        ),
      ],
    );
  }
}

class _AbsenceButton extends StatelessWidget {
  final StatutNote statut;
  final bool selected;
  final String tooltip;
  final bool enabled;
  final double size;
  final VoidCallback onTap;

  const _AbsenceButton({
    required this.statut,
    required this.selected,
    required this.tooltip,
    required this.enabled,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = noteStatutVisual(statut);
    final borderColor = selected ? visual.color : AppColors.border;
    final bgColor = selected ? visual.soft : AppColors.surfaceRaised;
    final iconColor = selected ? visual.color : AppColors.textMuted;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: bgColor,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: enabled ? onTap : null,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brSm,
                border: Border.all(color: borderColor),
              ),
              child: Icon(visual.icon, size: size * 0.47, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
