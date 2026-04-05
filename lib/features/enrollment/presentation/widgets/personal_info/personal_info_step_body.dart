import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/date_picker_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/gender_segmented_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_avatar.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PersonalInfoStepBody extends StatelessWidget {
  final StudentDetail studentDetail;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final TextEditingController birthPlaceController;
  final TextEditingController nationalityController;
  final Gender selectedGender;
  final DateTime? selectedDate;
  final ValueChanged<Gender?> onGenderChanged;
  final VoidCallback onPickDate;
  final void Function(BuildContext) onSave;
  final String Function(DateTime?) formatDate;
  final String enrollmentId;
  final bool showInlineSaveButton;
  final bool canSave;
  final String? firstNameError;
  final String? lastNameError;
  final String? surnameError;
  final String? birthPlaceError;
  final String? nationalityError;
  final String? dateOfBirthError;
  final ValueChanged<bool>? onSavingChanged;
  final VoidCallback onSaveSuccess;

  const PersonalInfoStepBody({
    super.key,
    required this.studentDetail,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.birthPlaceController,
    required this.nationalityController,
    required this.selectedGender,
    required this.selectedDate,
    required this.onGenderChanged,
    required this.onPickDate,
    required this.onSave,
    required this.formatDate,
    required this.enrollmentId,
    required this.showInlineSaveButton,
    required this.canSave,
    this.firstNameError,
    this.lastNameError,
    this.surnameError,
    this.birthPlaceError,
    this.nationalityError,
    this.dateOfBirthError,
    required this.onSavingChanged,
    required this.onSaveSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<StudentBloc, StudentState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        onSavingChanged?.call(state.status == StudentUpdateStatus.loading);

        if (state.status == StudentUpdateStatus.success) {
          context.read<EnrollmentBloc>().add(
            EnrollmentDetailRequested(enrollmentId: enrollmentId),
          );
          context.read<EnrollmentBloc>().add(
            const EnrollmentSummariesRefreshRequested(),
          );
          onSaveSuccess();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.personalInfoSaveSuccess),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
        } else if (state.status == StudentUpdateStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  l10n.personalInfoSaveError(state.errorMessage ?? ''),
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == StudentUpdateStatus.loading;

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
                  Row(
                    children: [
                      StudentAvatar(
                        firstName: studentDetail.firstName,
                        lastName: studentDetail.lastName,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${studentDetail.firstName} ${studentDetail.lastName}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.personalInfoSubtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: spacing,
                    runSpacing: 14,
                    children: [
                      EditableField(
                        width: fieldWidth,
                        label: l10n.firstName,
                        controller: firstNameController,
                        requiredField: true,
                        helpMessage: l10n.firstNameHelp,
                        errorText: firstNameError,
                      ),
                      EditableField(
                        width: fieldWidth,
                        label: l10n.lastName,
                        controller: lastNameController,
                        requiredField: true,
                        helpMessage: l10n.lastNameHelp,
                        errorText: lastNameError,
                      ),
                      EditableField(
                        width: fieldWidth,
                        label: l10n.surname,
                        controller: surnameController,
                        requiredField: true,
                        helpMessage: l10n.surnameHelp,
                        errorText: surnameError,
                      ),
                      DatePickerField(
                        width: fieldWidth,
                        label: l10n.dateOfBirth,
                        selectedDate: selectedDate,
                        displayValue: formatDate(selectedDate),
                        requiredField: true,
                        helpMessage: l10n.dateOfBirthHelp,
                        errorText: dateOfBirthError,
                        onTap: onPickDate,
                      ),
                      EditableField(
                        width: fieldWidth,
                        label: l10n.birthPlace,
                        controller: birthPlaceController,
                        requiredField: true,
                        helpMessage: l10n.birthPlaceHelp,
                        errorText: birthPlaceError,
                      ),
                      EditableField(
                        width: fieldWidth,
                        label: l10n.nationality,
                        controller: nationalityController,
                        requiredField: true,
                        helpMessage: l10n.nationalityHelp,
                        errorText: nationalityError,
                      ),
                      GenderSegmentedField(
                        width: fieldWidth,
                        label: l10n.gender,
                        selectedGender: selectedGender,
                        requiredField: true,
                        helpMessage: l10n.genderHelp,
                        onChanged: onGenderChanged,
                      ),
                    ],
                  ),
                  if (showInlineSaveButton) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: (isLoading || !canSave)
                            ? null
                            : () => onSave(context),
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isLoading
                              ? l10n.savingPersonalInfo
                              : l10n.savePersonalInfo,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: canSave
                              ? const Color(0xFF0EA5E9)
                              : null,
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
                  ],
                ],
              );

              if (constraints.maxHeight < 560) {
                return SingleChildScrollView(child: content);
              }
              return content;
            },
          ),
        );
      },
    );
  }
}
