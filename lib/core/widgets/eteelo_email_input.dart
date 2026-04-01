import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_input_decoration.dart';

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
      enabled: enabled,
      validator: validator,
      decoration: buildEteeloInputDecoration(
        labelText: label,
        prefixIcon: Icons.email_outlined,
      ),
    );
  }
}