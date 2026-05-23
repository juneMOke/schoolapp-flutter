import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Bouton d'action secondaire — Bleu Ardoise, forme stadium, bordure 1.5dp.
///
/// Utilise [OutlinedButton] Material (style configuré dans [AppTheme]).
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCallback = isLoading ? () {} : onPressed;

    final localStyle = OutlinedButton.styleFrom(
      disabledForegroundColor: AppColors.textMuted,
      minimumSize: fullWidth ? null : const Size(0, 56),
    );

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // Bleu Ardoise pour le secondary
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.bleuArdoise),
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

    return OutlinedButton(
      onPressed: effectiveCallback,
      style: localStyle,
      child: child,
    );
  }
}
