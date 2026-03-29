import 'package:flutter/material.dart';

class EteeloEmailInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool enabled;

  const EteeloEmailInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.email_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      enabled: enabled,
    );
  }
}
