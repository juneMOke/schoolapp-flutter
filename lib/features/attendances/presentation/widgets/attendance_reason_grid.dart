import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_page_helpers.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix du motif en **grandes cibles**, pour le mode Focus.
///
/// C'est l'équivalent fonctionnel du pavé numérique de la saisie de notes, et
/// non sa copie : là-bas on frappe un nombre, ici on désigne un motif parmi
/// cinq. Ce que les deux partagent est le geste évité — rouvrir un menu à
/// chaque élève. Un dropdown coûte deux taps et une liste déroulante ; une
/// cible en coûte un.
///
/// La grille ne connaît que [kSelectableAbsenceReasons] — les congés de salarié
/// et le verdict `unjustified` n'y sont pas, exactement comme dans le dropdown
/// de la liste. Elle accepte en plus [AbsenceReason.unsupported] **si la ligne
/// la porte déjà**, pour que le motif d'un catalogue plus récent reste visible
/// au lieu de disparaître de l'écran.
class AttendanceReasonGrid extends StatelessWidget {
  final AbsenceReason? selected;
  final ValueChanged<AbsenceReason> onSelected;

  const AttendanceReasonGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Une icône par motif — le repère qui permet de viser sans relire.
  static IconData _iconFor(AbsenceReason reason) => switch (reason) {
    AbsenceReason.sickness => Icons.sick_outlined,
    AbsenceReason.familyEmergency => Icons.family_restroom_rounded,
    AbsenceReason.personal => Icons.person_outline_rounded,
    AbsenceReason.other => Icons.more_horiz_rounded,
    AbsenceReason.unknown => Icons.block_rounded,
    AbsenceReason.unsupported => Icons.help_outline_rounded,
    // Hors liste de saisie : jamais rendues par cette grille.
    _ => Icons.event_busy_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasons = <AbsenceReason>[
      ...kSelectableAbsenceReasons,
      if (selected == AbsenceReason.unsupported) AbsenceReason.unsupported,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Deux colonnes dès qu'il y a la place, une seule sinon : une cible
        // trop étroite pour son libellé n'est plus une grande cible.
        final columns = constraints.maxWidth >= 360 ? 2 : 1;
        final spacing = AppDimensions.spacingS;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final reason in reasons)
              SizedBox(
                width: width,
                child: _ReasonTarget(
                  label: AttendancePageHelpers.absenceReasonLabel(l10n, reason),
                  icon: _iconFor(reason),
                  isSelected: reason == selected,
                  onTap: () => onSelected(reason),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReasonTarget extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonTarget({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.bleuArdoise : AppColors.border;

    return Material(
      color: isSelected
          ? AppColors.bleuArdoise.withValues(alpha: 0.08)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Container(
          // Bien au-delà de la cible tactile minimale : le mode existe pour
          // qu'on vise sans regarder de près.
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(color: accent, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.bleuArdoise
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: isSelected
                        ? AppColors.bleuArdoise
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
