import 'package:flutter/material.dart';

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
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
