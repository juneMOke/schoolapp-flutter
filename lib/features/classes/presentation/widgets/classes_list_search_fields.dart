import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_search_inputs.dart';

class ClassesListSearchFieldsGrid extends StatelessWidget {
  final List<ClassesListCycleOption> cycleOptions;
  final String? selectedCycleId;
  final List<ClassesListLevelOption> levelOptions;
  final String? selectedLevelKey;
  final List<BootstrapClassroom> classroomOptions;
  final String? selectedClassroomId;
  final bool classroomEnabled;
  final String classroomHelper;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final String cycleLabel;
  final String levelLabel;
  final String classroomLabel;
  final String firstNameLabel;
  final String lastNameLabel;
  final String surnameLabel;
  final ValueChanged<String?>? onCycleChanged;
  final ValueChanged<String?>? onLevelChanged;
  final ValueChanged<String?>? onClassroomChanged;
  final ValueChanged<String>? onFirstNameChanged;
  final ValueChanged<String>? onLastNameChanged;
  final ValueChanged<String>? onSurnameChanged;

  const ClassesListSearchFieldsGrid({
    super.key,
    required this.cycleOptions,
    required this.selectedCycleId,
    required this.levelOptions,
    required this.selectedLevelKey,
    required this.classroomOptions,
    required this.selectedClassroomId,
    required this.classroomEnabled,
    required this.classroomHelper,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.cycleLabel,
    required this.levelLabel,
    required this.classroomLabel,
    required this.firstNameLabel,
    required this.lastNameLabel,
    required this.surnameLabel,
    required this.onCycleChanged,
    required this.onLevelChanged,
    required this.onClassroomChanged,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.onSurnameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: SizedBox(
                width: AppDimensions.classesOrganisationCompactFieldWidth,
                child: ClassesListSearchDropdownField<String>(
                  value: selectedCycleId,
                  label: cycleLabel,
                  icon: Icons.account_tree_outlined,
                  items: cycleOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.label, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: cycleOptions.isEmpty ? null : onCycleChanged,
                ),
              ),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: SizedBox(
                width: AppDimensions.classesOrganisationCompactFieldWidth,
                child: ClassesListSearchDropdownField<String>(
                  value: selectedLevelKey,
                  label: levelLabel,
                  icon: Icons.school_outlined,
                  items: levelOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.key,
                          child: Text(option.label, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: levelOptions.isEmpty ? null : onLevelChanged,
                ),
              ),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(3),
              child: SizedBox(
                width: AppDimensions.classesOrganisationCompactSelectWidth,
                child: ClassesListSearchDropdownField<String>(
                  value: selectedClassroomId,
                  label: classroomLabel,
                  icon: Icons.meeting_room_outlined,
                  items: classroomOptions
                      .map(
                        (classroom) => DropdownMenuItem<String>(
                          value: classroom.id,
                          child: Text(
                            classroom.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: classroomEnabled ? onClassroomChanged : null,
                ),
              ),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(4),
              child: SizedBox(
                width: AppDimensions.classesOrganisationCompactFieldWidth,
                child: ClassesListSearchTextField(
                  controller: firstNameController,
                  label: firstNameLabel,
                  icon: Icons.person_outline_rounded,
                  onChanged: onFirstNameChanged,
                ),
              ),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(5),
              child: SizedBox(
                width: AppDimensions.classesOrganisationCompactFieldWidth,
                child: ClassesListSearchTextField(
                  controller: lastNameController,
                  label: lastNameLabel,
                  icon: Icons.badge_outlined,
                  onChanged: onLastNameChanged,
                ),
              ),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(6),
              child: SizedBox(
                width: AppDimensions.classesOrganisationCompactFieldWidth,
                child: ClassesListSearchTextField(
                  controller: surnameController,
                  label: surnameLabel,
                  icon: Icons.account_circle_outlined,
                  onChanged: onSurnameChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          classroomHelper,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
