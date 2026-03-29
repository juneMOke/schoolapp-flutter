import 'package:flutter/material.dart';

class EteeloPasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool enabled;
  final Function(String)? onFieldSubmitted;

  const EteeloPasswordInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.enabled = true,
    this.onFieldSubmitted,
  });

  @override
  State<EteeloPasswordInput> createState() => _EteeloPasswordInputState();
}

class _EteeloPasswordInputState extends State<EteeloPasswordInput> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outlined),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: widget.validator,
      enabled: widget.enabled,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
