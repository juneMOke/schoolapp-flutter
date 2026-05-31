import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// FAB étendu Terre Cuite — aucune ombre, forme stadium.
///
/// Positionnement : délégué au [Scaffold.floatingActionButton] de l'appelant.
/// Convention app : [FloatingActionButtonLocation.endFloat].
class EteeloFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Texte d'accessibilité. Par défaut = [label].
  final String? tooltip;

  const EteeloFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return FloatingActionButton.extended(
      onPressed: onPressed,
      tooltip: tooltip ?? label,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      disabledElevation: 0,
      backgroundColor: isDisabled
          ? AppColors.stateDisabled
          : AppColors.terreCuite,
      foregroundColor: isDisabled ? AppColors.textMuted : AppColors.blancCasse,
      shape: const StadiumBorder(),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.labelLarge),
        ],
      ),
    );
  }
}
