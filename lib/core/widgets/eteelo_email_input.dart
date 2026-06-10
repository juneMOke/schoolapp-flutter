import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_input_decoration.dart';

class EteeloEmailInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  /// Message d'erreur piloté manuellement (validation onBlur + soumission) —
  /// alternative au [validator] auto de [Form], pour ne jamais valider à la
  /// frappe (cf. spec Connexion §06).
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const EteeloEmailInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      autofillHints: autofillHints,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      decoration: buildEteeloInputDecoration(
        labelText: label,
        prefixIcon: Icons.email_outlined,
        errorText: errorText,
      ),
    );
  }
}
