import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EteeloOtpInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool enabled;
  final Function(String)? onFieldSubmitted;

  const EteeloOtpInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.enabled = true,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.pin_outlined),
        counterText: '',
      ),
      maxLength: 6,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
