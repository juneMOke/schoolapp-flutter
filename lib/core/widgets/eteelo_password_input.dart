import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_input_decoration.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EteeloPasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool enabled;
  final Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  /// Message d'erreur piloté manuellement (validation onBlur + soumission) —
  /// cf. [EteeloEmailInput.errorText] et spec Connexion §06.
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const EteeloPasswordInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.enabled = true,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.errorText,
    this.onChanged,
  });

  @override
  State<EteeloPasswordInput> createState() => _EteeloPasswordInputState();
}

class _EteeloPasswordInputState extends State<EteeloPasswordInput> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscurePassword,
      textInputAction: widget.textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: buildEteeloInputDecoration(
        labelText: widget.label,
        prefixIcon: Icons.lock_outlined,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: AppTheme.textSecondaryColor,
          ),
          tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }
}
