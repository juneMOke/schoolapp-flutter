import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_input_decoration.dart';

class EteeloEmailInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  const EteeloEmailInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      enabled: enabled,
      validator: validator,
      decoration: buildEteeloInputDecoration(
        labelText: label,
        prefixIcon: Icons.email_outlined,
      ),
    );
  }
}