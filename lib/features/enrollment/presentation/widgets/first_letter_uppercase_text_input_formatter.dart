import 'package:flutter/services.dart';

/// Forces the first letter of each word to uppercase while preserving user input.
class FirstLetterUppercaseTextInputFormatter extends TextInputFormatter {
  const FirstLetterUppercaseTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final transformed = _capitalizeWords(text);
    if (transformed == text) {
      return newValue;
    }

    final selection = newValue.selection;
    final baseOffset = selection.baseOffset.clamp(0, transformed.length);
    final extentOffset = selection.extentOffset.clamp(0, transformed.length);

    return newValue.copyWith(
      text: transformed,
      selection: TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
      ),
      composing: TextRange.empty,
    );
  }

  String _capitalizeWords(String value) {
    final buffer = StringBuffer();
    var shouldCapitalize = true;

    for (var i = 0; i < value.length; i++) {
      final character = value[i];
      if (shouldCapitalize && _isAlphabetic(character)) {
        buffer.write(character.toUpperCase());
      } else {
        buffer.write(character);
      }
      shouldCapitalize = _isWordDelimiter(character);
    }

    return buffer.toString();
  }

  bool _isWordDelimiter(String character) {
    return character.trim().isEmpty || character == '-' || character == "'";
  }

  bool _isAlphabetic(String character) {
    return character.toLowerCase() != character.toUpperCase();
  }
}
