import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

/// Le champ fermé — l'unique déclencheur, quel que soit le panneau qui s'ouvre
/// derrière. Popover et feuille partagent le même repos, le même focus et le
/// même chevron : la forme du panneau dépend de l'écran, l'apparence du champ
/// ne doit pas en dépendre.
class EteeloSelectField extends StatelessWidget {
  final String? selectedLabel;
  final String placeholder;

  /// Rendu de la valeur fourni par l'appelant (`selectedItemBuilder`).
  final Widget? selectedContent;
  final bool isOpen;
  final bool hasFocus;

  /// Grisé « non disponible » (cascade en attente), à distinguer de la lecture
  /// seule qui garde la pleine couleur.
  final bool dimmed;
  final bool hasError;
  final EteeloSelectDensity density;
  final EteeloSelectPlaceholderTone placeholderTone;
  final VoidCallback? onTap;

  const EteeloSelectField({
    super.key,
    required this.selectedLabel,
    required this.placeholder,
    required this.isOpen,
    required this.hasFocus,
    required this.dimmed,
    required this.hasError,
    required this.density,
    required this.placeholderTone,
    required this.onTap,
    this.selectedContent,
  });

  bool get _isCompact => density == EteeloSelectDensity.compact;

  bool get _highlighted => hasFocus || isOpen;

  Color get _background => dimmed ? AppColors.surfaceAlt : AppColors.surface;

  Color get _borderColor {
    if (dimmed) return AppColors.stateDisabled;
    if (hasError) return AppColors.error;
    if (_highlighted) return AppColors.bleuArdoise;
    return AppColors.border;
  }

  double get _horizontalPadding {
    if (_isCompact) {
      return _highlighted
          ? EteeloSelectConstants.compactFocusHorizontalPadding
          : EteeloSelectConstants.compactRestHorizontalPadding;
    }
    return _highlighted
        ? EteeloSelectConstants.focusHorizontalPadding
        : EteeloSelectConstants.restHorizontalPadding;
  }

  @override
  Widget build(BuildContext context) {
    final isAlerting =
        selectedLabel == null &&
        placeholderTone == EteeloSelectPlaceholderTone.alert &&
        !dimmed;
    final valueColor = selectedLabel == null
        ? (isAlerting ? AppColors.terreCuite : AppColors.textMuted)
        : dimmed
        ? AppColors.stateDisabled
        : AppColors.textPrimary;

    return AnimatedContainer(
      duration: AppMotion.micro,
      curve: AppMotion.gentleOut,
      constraints: BoxConstraints(
        minHeight: _isCompact
            ? EteeloSelectConstants.fieldHeightCompact
            : EteeloSelectConstants.fieldHeight,
      ),
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: AppRadius.brSm,
        border: Border.all(
          color: _borderColor,
          width: _highlighted
              ? EteeloSelectConstants.focusBorderWidth
              : EteeloSelectConstants.restBorderWidth,
        ),
        boxShadow: _highlighted
            ? const [
                BoxShadow(
                  color: AppColors.stateFocus,
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      // Material propre au champ : sans lui, l'encre irait se peindre sur le
      // Material de la page, DERRIÈRE le fond opaque du conteneur — ni le
      // survol ni l'appui ne se verraient.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brSm,
          hoverColor: AppColors.stateHover,
          child: Row(
            children: [
              Expanded(
                child:
                    selectedContent ??
                    Text(
                      selectedLabel ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (_isCompact
                                  ? AppTypography.formValueSmall
                                  : AppTypography.bodyMedium)
                              .copyWith(
                                color: valueColor,
                                fontWeight: isAlerting ? FontWeight.w600 : null,
                              ),
                    ),
              ),
              SizedBox(width: _isCompact ? AppSpacing.xs : AppSpacing.sm),
              // Le chevron se retourne quand le panneau est ouvert : le champ
              // dit son propre état, même quand le panneau s'affiche ailleurs
              // (feuille modale en bas d'écran).
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: AppMotion.fast,
                curve: AppMotion.outCurve,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: EteeloSelectConstants.chevronSize,
                  color: dimmed ? AppColors.stateDisabled : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
