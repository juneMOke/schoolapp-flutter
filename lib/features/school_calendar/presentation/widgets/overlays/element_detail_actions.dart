import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/element_detail_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes du détail (maquette CalItemModal) : « Supprimer » discret en
/// rouge, « Modifier » secondaire, « Date vérifiée » principal ; un élément
/// national remplaçable : « Fermer » · « Remplacer… » ; sans droit : « Fermer ».
class ElementDetailActions extends StatelessWidget {
  final CalendarElement element;
  final bool canEdit;

  const ElementDetailActions({
    super.key,
    required this.element,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void choose(ElementDetailChoice c) => Navigator.of(context).pop(c);
    final close = EteeloButton.secondary(
      label: l10n.schoolCalendarClose,
      fullWidth: false,
      size: EteeloButtonSize.regular,
      onPressed: () => Navigator.of(context).pop(),
    );
    final List<Widget> children;
    if (canEdit && element.isNational && element.replaceable) {
      children = [
        close,
        EteeloButton.primary(
          label: l10n.schoolCalendarReplaceAction,
          icon: Icons.swap_horiz_rounded,
          fullWidth: false,
          size: EteeloButtonSize.regular,
          onPressed: () => choose(ElementDetailChoice.replace),
        ),
      ];
    } else if (canEdit && !element.isNational) {
      children = [
        element.isReplacement
            ? EteeloButton.ghost(
                label: l10n.schoolCalendarRestoreNational,
                icon: Icons.restore_rounded,
                fullWidth: false,
                size: EteeloButtonSize.regular,
                onPressed: () => choose(ElementDetailChoice.delete),
              )
            : _DangerGhostButton(
                label: l10n.schoolCalendarDelete,
                onPressed: () => choose(ElementDetailChoice.delete),
              ),
        EteeloButton.secondary(
          label: l10n.schoolCalendarEdit,
          icon: Icons.edit_outlined,
          fullWidth: false,
          size: EteeloButtonSize.regular,
          onPressed: () => choose(ElementDetailChoice.edit),
        ),
        if (element.toVerify)
          EteeloButton.primary(
            label: l10n.schoolCalendarDateVerified,
            icon: Icons.check_rounded,
            fullWidth: false,
            size: EteeloButtonSize.regular,
            onPressed: () => choose(ElementDetailChoice.verify),
          ),
      ];
    } else {
      children = [close];
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children,
    );
  }
}

/// « Supprimer » : un bouton texte rouge, sans fond — le geste destructeur ne
/// se présente pas comme l'action attendue (sa confirmation suit, O6).
class _DangerGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DangerGhostButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.error,
      minimumSize: const Size(0, AppDimensions.minTouchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      textStyle: AppTypography.labelLarge,
      shape: const StadiumBorder(),
    ),
    icon: const Icon(Icons.delete_outline_rounded, size: 18),
    label: Text(label),
  );
}
