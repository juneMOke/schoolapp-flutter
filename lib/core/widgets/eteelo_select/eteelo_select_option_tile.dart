import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

/// Une ligne du panneau d'options.
///
/// Elle porte les trois repères qui manquaient au menu Material d'origine :
/// **où on est** (fond teinté + coche sur l'option courante), **où on pointe**
/// (survol souris et surbrillance clavier partagent le même fond, pour qu'un
/// utilisateur au clavier voie ce qu'un utilisateur à la souris verrait), et
/// **ce qui est hors d'atteinte** (option désactivée en gris, sans effet de
/// survol qui promettrait un clic).
class EteeloSelectOptionTile<T> extends StatelessWidget {
  final EteeloSelectItem<T> item;
  final bool isSelected;

  /// Ligne visée au clavier. Distincte de [isSelected] : on parcourt la liste
  /// sans rien changer tant qu'on n'a pas validé.
  final bool isHighlighted;
  final VoidCallback? onTap;

  /// Rendu fourni par l'appelant. Il remplace le libellé, son sous-titre —
  /// **et les marques de sélection** : un `itemBuilder` reçoit déjà
  /// `isSelected` et dessine souvent sa propre pastille cochée (filtre de
  /// statut). La ligne ne garde alors que sa zone tactile et sa surbrillance
  /// de survol, sinon la coche et le fond teinté feraient doublon.
  final Widget? content;

  const EteeloSelectOptionTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isHighlighted,
    required this.onTap,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled && onTap != null;
    // Voir [content] : l'appelant qui dessine sa ligne dessine aussi son état
    // sélectionné.
    final ownsSelectionChrome = content == null;
    final labelColor = !enabled
        ? AppColors.stateDisabled
        : AppColors.textPrimary;

    return Semantics(
      selected: isSelected,
      enabled: enabled,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.brSm,
          hoverColor: AppColors.stateHover,
          highlightColor: AppColors.statePressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.brSm,
              color: isSelected && ownsSelectionChrome
                  ? AppColors.bleuArdoiseSoft
                  : isHighlighted
                  ? AppColors.stateHover
                  : null,
            ),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: EteeloSelectConstants.optionMinHeight,
              ),
              padding: ownsSelectionChrome
                  ? const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    )
                  : const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: EteeloSelectConstants.optionIconSize,
                      color: enabled
                          ? (isSelected
                                ? AppColors.bleuArdoise
                                : AppColors.textSecondary)
                          : AppColors.stateDisabled,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child:
                        content ??
                        _buildLabel(enabled: enabled, labelColor: labelColor),
                  ),
                  if (isSelected && ownsSelectionChrome) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.check_rounded,
                      size: EteeloSelectConstants.checkSize,
                      color: AppColors.bleuArdoise,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel({required bool enabled, required Color labelColor}) {
    final subtitle = item.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: labelColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: enabled ? AppColors.textMuted : AppColors.stateDisabled,
            ),
          ),
      ],
    );
  }
}
