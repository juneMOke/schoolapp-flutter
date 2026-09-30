import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Un [EteeloTextInput] dont la valeur vit dans l'état du cubit : il garde son
/// contrôleur, et ne le réécrit que si la valeur change **ailleurs**
/// (annulation, rechargement) — jamais pendant la frappe, sinon le curseur
/// sauterait en fin de champ.
class StaffSyncedTextInput extends StatefulWidget {
  final String value;
  final String label;
  final String? placeholder;
  final bool required;
  final bool readOnly;
  final String? errorText;
  final EteeloTextInputType keyboardType;
  final EteeloTextCapitalization capitalization;
  final ValueChanged<String> onChanged;

  const StaffSyncedTextInput({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.placeholder,
    this.required = false,
    this.readOnly = false,
    this.errorText,
    this.keyboardType = EteeloTextInputType.text,
    this.capitalization = EteeloTextCapitalization.auto,
  });

  @override
  State<StaffSyncedTextInput> createState() => _StaffSyncedTextInputState();
}

class _StaffSyncedTextInputState extends State<StaffSyncedTextInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant StaffSyncedTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EteeloTextInput(
    controller: _controller,
    label: widget.label,
    placeholder: widget.placeholder,
    required: widget.required,
    readOnly: widget.readOnly,
    errorText: widget.errorText,
    keyboardType: widget.keyboardType,
    capitalization: widget.capitalization,
    onChanged: widget.onChanged,
  );
}
