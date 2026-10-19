import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// FAB étendu Terre Cuite — aucune ombre, forme stadium.
///
/// Positionnement : délégué au [Scaffold.floatingActionButton] de l'appelant.
/// Convention app : `EndFloatEdgeOffsetFabLocation`.
class EteeloFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Texte d'accessibilité. Par défaut = [label].
  final String? tooltip;

  /// Compte posé en pastille sur l'icône (le panier) — visible aussi quand,
  /// sur un téléphone, le libellé disparaît. Rien à zéro ni à `null`.
  final int? badgeCount;

  const EteeloFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount,
  });

  Widget _icon() {
    final glyph = Icon(icon, size: AppDimensions.fabIconSize);
    final count = badgeCount ?? 0;
    if (count == 0) return glyph;
    return Badge.count(
      count: count,
      backgroundColor: AppColors.orDoux,
      textColor: AppColors.bleuProfond,
      child: glyph,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final bg = isDisabled ? AppColors.stateDisabled : AppColors.fabBackground;
    final fg = isDisabled ? AppColors.textMuted : AppColors.blancCasse;
    final isCompact =
        MediaQuery.sizeOf(context).width < AppBreakpoints.fabExtendedMinWidth;
    final effectiveTooltip = tooltip ?? label;

    if (isCompact) {
      return FloatingActionButton(
        // heroTag null : évite tout conflit de Hero avec un FAB d'un autre
        // écran lors de la navigation (ex. ouverture du parcours de création).
        heroTag: null,
        onPressed: onPressed,
        tooltip: effectiveTooltip,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        backgroundColor: bg,
        foregroundColor: fg,
        shape: const CircleBorder(),
        child: _icon(),
      );
    }

    // Rend [AppDimensions.fabHeight] autoritatif sur la hauteur du FAB étendu :
    // on surcharge la contrainte du thème plutôt que de dépendre du défaut M3
    // (56) ou d'un SizedBox englobant sans effet réel.
    final extendedTheme = FloatingActionButtonTheme.of(context).copyWith(
      extendedSizeConstraints: const BoxConstraints.tightFor(
        height: AppDimensions.fabHeight,
      ),
    );

    return FloatingActionButtonTheme(
      data: extendedTheme,
      child: FloatingActionButton.extended(
        heroTag: null,
        onPressed: onPressed,
        tooltip: effectiveTooltip,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        backgroundColor: bg,
        foregroundColor: fg,
        shape: const StadiumBorder(),
        extendedPadding: const EdgeInsetsDirectional.only(
          start: AppDimensions.fabPaddingStart,
          end: AppDimensions.fabPaddingEnd,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(),
            const SizedBox(width: AppDimensions.fabLabelGap),
            Text(label, style: AppTypography.labelLarge),
          ],
        ),
      ),
    );
  }
}
