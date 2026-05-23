import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

class FacturationSearchFormCompactLayout extends StatelessWidget {
  final Widget title;
  final Widget description;
  final double spacing;
  final double fieldWidth;
  final double availableWidth;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final String firstNameLabel;
  final String lastNameLabel;
  final String surnameLabel;
  final bool isLoading;
  final Widget levelDropdown;
  final Widget actions;

  const FacturationSearchFormCompactLayout({
    super.key,
    required this.title,
    required this.description,
    required this.spacing,
    required this.fieldWidth,
    required this.availableWidth,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.firstNameLabel,
    required this.lastNameLabel,
    required this.surnameLabel,
    required this.isLoading,
    required this.levelDropdown,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 8),
        description,
        const SizedBox(height: 12),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: fieldWidth,
              child: _FacturationSearchField(
                controller: firstNameController,
                label: firstNameLabel,
                onChanged: (_) {},
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _FacturationSearchField(
                controller: lastNameController,
                label: lastNameLabel,
                onChanged: (_) {},
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _FacturationSearchField(
                controller: surnameController,
                label: surnameLabel,
                onChanged: (_) {},
              ),
            ),
            SizedBox(width: fieldWidth, child: levelDropdown),
            SizedBox(
              width: availableWidth,
              child: Align(alignment: Alignment.centerRight, child: actions),
            ),
          ],
        ),
      ],
    );
  }
}

class _FacturationSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const _FacturationSearchField({
    required this.controller,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: _buildInputDecoration(label: label),
    );
  }
}

InputDecoration _buildInputDecoration({required String label}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12),
    isDense: true,
    filled: true,
    fillColor: AppColors.surfaceAlt,
    border: const OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  );
}
