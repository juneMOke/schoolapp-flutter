import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/forms/wizard_fields_grid.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/gender_segmented_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/nationality_dropdown_field.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

class PersonalInfoStepBody extends StatelessWidget {
  final StudentDetail studentDetail;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final TextEditingController birthPlaceController;
  final String selectedNationality;
  final List<String> nationalityOptions;
  final Gender selectedGender;
  final DateTime? selectedDate;
  final ValueChanged<String?> onNationalityChanged;
  final ValueChanged<Gender?> onGenderChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final void Function(BuildContext) onSave;
  final String enrollmentId;
  final bool showInlineSaveButton;
  final bool canSave;
  final bool isEditable;
  final String? firstNameError;
  final String? lastNameError;
  final String? surnameError;
  final String? birthPlaceError;
  final String? nationalityError;
  final String? dateOfBirthError;

  const PersonalInfoStepBody({
    super.key,
    required this.studentDetail,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.birthPlaceController,
    required this.selectedNationality,
    required this.nationalityOptions,
    required this.selectedGender,
    required this.selectedDate,
    required this.onNationalityChanged,
    required this.onGenderChanged,
    required this.onDateChanged,
    required this.onSave,
    required this.enrollmentId,
    required this.showInlineSaveButton,
    required this.canSave,
    this.isEditable = true,
    this.firstNameError,
    this.lastNameError,
    this.surnameError,
    this.birthPlaceError,
    this.nationalityError,
    this.dateOfBirthError,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardFieldsGrid(
            fields: [
              WizardGridField(
                EteeloTextInput(
                  label: l10n.firstName,
                  controller: firstNameController,
                  required: true,
                  errorText: firstNameError,
                  readOnly: !isEditable,
                ),
              ),
              WizardGridField(
                EteeloTextInput(
                  label: l10n.lastName,
                  controller: lastNameController,
                  required: true,
                  errorText: lastNameError,
                  readOnly: !isEditable,
                ),
              ),
              WizardGridField(
                EteeloTextInput(
                  label: l10n.surname,
                  controller: surnameController,
                  required: true,
                  errorText: surnameError,
                  readOnly: !isEditable,
                ),
              ),
              WizardGridField(
                EteeloDateInput(
                  label: l10n.dateOfBirth,
                  placeholder: l10n.dateHint,
                  value: selectedDate,
                  required: true,
                  errorText: dateOfBirthError,
                  enabled: isEditable,
                  readOnly: !isEditable,
                  lastDate: DateTime.now(),
                  initialPickerDate: DateTime(DateTime.now().year - 10),
                  locale: const Locale('fr'),
                  helpText: l10n.selectDateOfBirthHelpText,
                  cancelText: l10n.cancel,
                  confirmText: l10n.confirm,
                  onChanged: onDateChanged,
                ),
              ),
              WizardGridField(
                EteeloTextInput(
                  label: l10n.birthPlace,
                  controller: birthPlaceController,
                  required: true,
                  errorText: birthPlaceError,
                  readOnly: !isEditable,
                ),
              ),
              WizardGridField(
                NationalityDropdownField(
                  label: l10n.nationality,
                  value: selectedNationality,
                  options: nationalityOptions,
                  onChanged: onNationalityChanged,
                  requiredField: true,
                  errorText: nationalityError,
                  enabled: isEditable,
                  readOnly: !isEditable,
                ),
              ),
              // Genre (contrôle segmenté M/F) — pleine largeur, comme
              // « Année validée » à l'étape 3.
              WizardGridField(
                GenderSegmentedField(
                  width: double.infinity,
                  label: l10n.gender,
                  selectedGender: selectedGender,
                  requiredField: true,
                  helpMessage: l10n.genderHelp,
                  onChanged: onGenderChanged,
                  enabled: isEditable,
                  readOnly: !isEditable,
                ),
                fullWidth: true,
              ),
            ],
          ),
          if (showInlineSaveButton) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: SessionWriteGate(
                child: FilledButton.icon(
                  onPressed: !canSave ? null : () => onSave(context),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.savePersonalInfo),
                  style: FilledButton.styleFrom(
                    backgroundColor: canSave ? const Color(0xFF0EA5E9) : null,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    elevation: canSave ? 6 : 0,
                    shadowColor: const Color(
                      0xFF0EA5E9,
                    ).withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
