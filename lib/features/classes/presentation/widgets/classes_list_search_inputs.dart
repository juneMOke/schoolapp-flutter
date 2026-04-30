import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

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
      decoration: classesListSearchInputDecoration(label: label, icon: icon),
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
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
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
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
    filled: true,
    fillColor: AppColors.background,
    prefixIcon: Icon(icon, color: AppColors.textSecondary),
    floatingLabelStyle: const TextStyle(color: AppColors.classesFocusRing),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      borderSide: const BorderSide(color: AppColors.classesFocusRing, width: 1.6),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingS,
      vertical: AppDimensions.spacingM,
    ),
  );
}
