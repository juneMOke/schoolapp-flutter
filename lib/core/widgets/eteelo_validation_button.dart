import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';

@Deprecated('Use EteeloButton.primary(size: EteeloButtonSize.regular) instead.')
class EteeloValidationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const EteeloValidationButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return EteeloButton.primary(
      onPressed: onPressed,
      label: label,
      isLoading: isLoading,
      size: EteeloButtonSize.regular,
    );
  }
}
