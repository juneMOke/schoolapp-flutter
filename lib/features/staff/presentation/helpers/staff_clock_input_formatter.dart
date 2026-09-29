import 'package:flutter/services.dart';

/// Saisie d'une heure `HH:MM` : chiffres seulement, deux-points posés d'office
/// après l'heure, quatre chiffres au plus.
class StaffClockInputFormatter extends TextInputFormatter {
  const StaffClockInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}:${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
