import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';

class ClassesListSearchFeedbackBanner extends StatelessWidget {
  final String message;
  final Color foreground;
  final Color background;
  final IconData icon;

  const ClassesListSearchFeedbackBanner({
    super.key,
    required this.message,
    required this.foreground,
    required this.background,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppDimensions.detailMiniIconSize, color: foreground),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class ClassesListSearchDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const ClassesListSearchDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: classesListSearchInputDecoration(label: label, icon: icon),
      items: items,
      onChanged: onChanged,
    );
  }
}

class ClassesListSearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  const ClassesListSearchTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: classesListSearchInputDecoration(label: label, icon: icon),
    );
  }
}

InputDecoration classesListSearchInputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12),
    filled: true,
    fillColor: AppColors.surfaceAlt,
    prefixIcon: Icon(icon),
    prefixIconConstraints: const BoxConstraints(minWidth: 34),
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm.x),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm.x),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm.x),
      borderSide: const BorderSide(color: AppColors.bleuArdoise, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  );
}
