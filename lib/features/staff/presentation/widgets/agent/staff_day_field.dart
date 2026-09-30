import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';

/// Un jour de la fiche (`YYYY-MM-DD`, sans fuseau), saisi avec le sélecteur
/// de date du socle.
class StaffDayField extends StatelessWidget {
  final String label;
  final String? value;
  final bool readOnly;
  final bool required;
  final String? errorText;
  final DateTime? lastDate;
  final ValueChanged<String?> onChanged;

  const StaffDayField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
    this.required = false,
    this.errorText,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) => EteeloDateInput(
    label: label,
    value: _parse(value),
    readOnly: readOnly,
    required: required,
    errorText: errorText,
    firstDate: DateTime(1900),
    lastDate: lastDate ?? DateTime(2100),
    onChanged: (date) => onChanged(date == null ? null : format(date)),
  );

  static DateTime? _parse(String? day) {
    if (day == null) return null;
    return DateTime.tryParse(day);
  }

  /// `YYYY-MM-DD` du jour civil choisi — jamais d'instant, donc jamais de
  /// fuseau pour le décaler d'un jour.
  static String format(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
