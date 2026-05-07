import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';

class SearchFormInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Widget prefixIcon;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const SearchFormInput({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.words,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
      readOnly: readOnly,
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        suffixIcon: suffixIcon,
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        labelStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.sm,
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
