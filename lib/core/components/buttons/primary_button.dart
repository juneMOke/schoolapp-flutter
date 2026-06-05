import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';

/// Bouton d'action primaire — Terre Cuite, forme stadium, pleine largeur par défaut.
///
/// Utilise [FilledButton] Material (style configuré dans [AppTheme]).
@Deprecated('Use EteeloButton.primary or EteeloButton.danger directly.')
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
    final size = EteeloButtonSize.regular;
    if (isDanger) {
      return EteeloButton.danger(
        onPressed: onPressed,
        label: label,
        icon: icon,
        isLoading: isLoading,
        size: size,
        fullWidth: fullWidth,
      );
    }
    return EteeloButton.primary(
      onPressed: onPressed,
      label: label,
      icon: icon,
      isLoading: isLoading,
      size: size,
      fullWidth: fullWidth,
    );
  }
}
