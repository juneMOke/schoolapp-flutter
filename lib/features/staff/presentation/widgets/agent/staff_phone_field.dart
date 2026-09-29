import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';

/// Le téléphone de la fiche : [EteeloPhoneInput], dont le contrôleur porte la
/// valeur E.164 complète. Même règle que [StaffSyncedTextInput] : réécrit
/// seulement quand la valeur change ailleurs.
class StaffPhoneField extends StatefulWidget {
  final String value;
  final String label;
  final bool readOnly;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const StaffPhoneField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.readOnly = false,
    this.errorText,
  });

  @override
  State<StaffPhoneField> createState() => _StaffPhoneFieldState();
}

class _StaffPhoneFieldState extends State<StaffPhoneField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant StaffPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EteeloPhoneInput(
    controller: _controller,
    label: widget.label,
    required: !widget.readOnly,
    readOnly: widget.readOnly,
    errorText: widget.errorText,
    onChanged: widget.onChanged,
  );
}
