import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Bouton d'action primaire — Terre Cuite, forme stadium, pleine largeur par défaut.
///
/// Utilise [FilledButton] Material (style configuré dans [AppTheme]).
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final bool isDanger;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    // Pendant le chargement, on passe un no-op pour conserver l'apparence active.
    final effectiveCallback = isLoading ? () {} : onPressed;

    final localStyle = FilledButton.styleFrom(
      // Couleur danger — override du thème global Terre Cuite
      backgroundColor: isDanger ? AppColors.error : null,
      foregroundColor: isDanger ? AppColors.blancCasse : null,
      // Couleurs disabled explicites (thème global ne les spécifie pas)
      disabledBackgroundColor: AppColors.stateDisabled,
      disabledForegroundColor: AppColors.textMuted,
      // fullWidth: false → on réduit le minimum pour wrapper le contenu
      minimumSize: fullWidth ? null : const Size(0, 56),
    );

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.blancCasse),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    return FilledButton(
      onPressed: effectiveCallback,
      style: localStyle,
      child: child,
    );
  }
}
