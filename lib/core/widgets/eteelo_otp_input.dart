import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/widgets/eteelo_input_decoration.dart';

class EteeloOtpInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? Function(String?)? validator;
  final bool enabled;
  final Function(String)? onFieldSubmitted;

  const EteeloOtpInput({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
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
      decoration: buildEteeloInputDecoration(
        labelText: label,
        prefixIcon: Icons.pin_outlined,
        helperText: helperText,
        counterText: '',
      ),
      maxLength: 6,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}