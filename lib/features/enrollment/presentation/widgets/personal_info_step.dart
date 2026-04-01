import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/date_picker_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/gender_segmented_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_avatar.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PersonalInfoStep extends StatefulWidget {
  final StudentDetail studentDetail;

  const PersonalInfoStep({super.key, required this.studentDetail});

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _nationalityController;

  late Gender _selectedGender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final student = widget.studentDetail;
    _firstNameController = TextEditingController(text: student.firstName);
    _lastNameController  = TextEditingController(text: student.lastName);
    _surnameController   = TextEditingController(text: student.surname);
    _birthPlaceController  = TextEditingController(text: student.birthPlace);
    _nationalityController = TextEditingController(text: student.nationality);
    _selectedGender = student.gender;

    try {
      final parts = student.dateOfBirth.split('-');
      if (parts.length == 3) {
        _selectedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {
      _selectedDate = null;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _birthPlaceController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 10),
      firstDate: DateTime(1990),
      lastDate: now,
      locale: const Locale('fr'),
      helpText: l10n.selectDateOfBirthHelpText,
      cancelText: l10n.cancel,
      confirmText: l10n.confirm,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final student = widget.studentDetail;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 16.0;
          final columns = constraints.maxWidth >= 980
              ? 3
              : constraints.maxWidth >= 640
              ? 2
              : 1;
          final fieldWidth =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ───────────────────────────────────────────────
              Row(
                children: [
                  StudentAvatar(
                    firstName: student.firstName,
                    lastName: student.lastName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${student.firstName} ${student.lastName}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
              Text(
                          l10n.personalInfoSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // ── Champs ────────────────────────────────────────────────
              Wrap(
                spacing: spacing,
                runSpacing: 14,
                children: [
                  EditableField(
                    width: fieldWidth,
                    label: l10n.firstName,
                    controller: _firstNameController,
                    requiredField: true,
                    helpMessage: l10n.firstNameHelp,
                  ),
                  EditableField(
                    width: fieldWidth,
                    label: l10n.lastName,
                    controller: _lastNameController,
                    requiredField: true,
                    helpMessage: l10n.lastNameHelp,
                  ),
                  EditableField(
                    width: fieldWidth,
                    label: l10n.surname,
                    controller: _surnameController,
                    requiredField: true,
                    helpMessage: l10n.surnameHelp,
                  ),
                  DatePickerField(
                    width: fieldWidth,
                    label: l10n.dateOfBirth,
                    selectedDate: _selectedDate,
                    displayValue: _formatDate(_selectedDate),
                    requiredField: true,
                    helpMessage: l10n.dateOfBirthHelp,
                    onTap: () => _pickDate(context),
                  ),
                  EditableField(
                    width: fieldWidth,
                    label: l10n.birthPlace,
                    controller: _birthPlaceController,
                    requiredField: true,
                    helpMessage: l10n.birthPlaceHelp,
                  ),
                  EditableField(
                    width: fieldWidth,
                    label: l10n.nationality,
                    controller: _nationalityController,
                    requiredField: true,
                    helpMessage: l10n.nationalityHelp,
                  ),
                  GenderSegmentedField(
                    width: fieldWidth,
                    label: l10n.gender,
                    selectedGender: _selectedGender,
                    requiredField: true,
                    helpMessage: l10n.genderHelp,
                    onChanged: (gender) {
                      if (gender != null) {
                        setState(() => _selectedGender = gender);
                      }
                    },
                  ),
                ],
              ),
            ],
          );

          if (constraints.maxHeight < 560) {
            return SingleChildScrollView(child: content);
          }
          return content;
        },
      ),
    );
  }
}