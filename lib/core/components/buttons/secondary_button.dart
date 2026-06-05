import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';

/// Bouton d'action secondaire — Bleu Ardoise, forme stadium, bordure 1.5dp.
///
/// Utilise [OutlinedButton] Material (style configuré dans [AppTheme]).
@Deprecated('Use EteeloButton.secondary directly.')
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
    return EteeloButton.secondary(
      onPressed: onPressed,
      label: label,
      icon: icon,
      isLoading: isLoading,
      size: EteeloButtonSize.regular,
      fullWidth: fullWidth,
    );
  }
}
