import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_input.dart';

class SearchFormCompactLayout extends StatelessWidget {
  final Widget title;
  final double spacing;
  final double fieldWidth;
  final double availableWidth;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final TextEditingController dateOfBirthController;
  final String firstNameLabel;
  final String lastNameLabel;
  final String surnameLabel;
  final String dateOfBirthLabel;
  final ValueChanged<String> onFieldChanged;
  final VoidCallback onDateTap;
  final Widget actions;
  final Widget? statusDropdown;

  const SearchFormCompactLayout({
    super.key,
    required this.title,
    required this.spacing,
    required this.fieldWidth,
    required this.availableWidth,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.dateOfBirthController,
    required this.firstNameLabel,
    required this.lastNameLabel,
    required this.surnameLabel,
    required this.dateOfBirthLabel,
    required this.onFieldChanged,
    required this.onDateTap,
    required this.actions,
    this.statusDropdown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 8),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (statusDropdown != null)
              SizedBox(width: fieldWidth, child: statusDropdown!),
            SizedBox(
              width: fieldWidth,
              child: SearchFormInput(
                controller: firstNameController,
                label: firstNameLabel,
                prefixIcon: const Icon(Icons.person_outline, size: 16),
                onChanged: onFieldChanged,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: SearchFormInput(
                controller: lastNameController,
                label: lastNameLabel,
                prefixIcon: const Icon(Icons.badge_outlined, size: 16),
                onChanged: onFieldChanged,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: SearchFormInput(
                controller: surnameController,
                label: surnameLabel,
                prefixIcon: const Icon(Icons.account_circle_outlined, size: 16),
                onChanged: onFieldChanged,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: SearchFormInput(
                controller: dateOfBirthController,
                label: dateOfBirthLabel,
                prefixIcon: const Icon(Icons.cake_outlined, size: 16),
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                readOnly: true,
                onTap: onDateTap,
              ),
            ),
            SizedBox(
              width: availableWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: actions,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
