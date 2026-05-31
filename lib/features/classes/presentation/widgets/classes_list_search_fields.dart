import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.formMediumMin;
        const spacing = AppDimensions.spacingS;

        final dropdownFields = [
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: ClassesListSearchDropdownField<String>(
              value: selectedCycleId,
              label: cycleLabel,
              icon: Icons.account_tree_outlined,
              items: cycleOptions
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o.id,
                      child: Text(o.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: cycleOptions.isEmpty ? null : onCycleChanged,
            ),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: ClassesListSearchDropdownField<String>(
              value: selectedLevelKey,
              label: levelLabel,
              icon: Icons.school_outlined,
              items: levelOptions
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o.key,
                      child: Text(o.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: levelOptions.isEmpty ? null : onLevelChanged,
            ),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: ClassesListSearchDropdownField<String>(
              value: selectedClassroomId,
              label: classroomLabel,
              icon: Icons.meeting_room_outlined,
              items: classroomOptions
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: classroomEnabled ? onClassroomChanged : null,
            ),
          ),
        ];

        final textFields = [
          FocusTraversalOrder(
            order: const NumericFocusOrder(4),
            child: ClassesListSearchTextField(
              controller: firstNameController,
              label: firstNameLabel,
              icon: Icons.person_outline_rounded,
              onChanged: onFirstNameChanged,
            ),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(5),
            child: ClassesListSearchTextField(
              controller: lastNameController,
              label: lastNameLabel,
              icon: Icons.badge_outlined,
              onChanged: onLastNameChanged,
            ),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(6),
            child: ClassesListSearchTextField(
              controller: surnameController,
              label: surnameLabel,
              icon: Icons.account_circle_outlined,
              onChanged: onSurnameChanged,
            ),
          ),
        ];

        if (isWide) {
          return Column(
            children: [
              _buildRow(dropdownFields, spacing),
              const SizedBox(height: spacing),
              _buildRow(textFields, spacing),
            ],
          );
        }

        // Compact : wrap automatique, largeur min par champ
        final fieldWidth = ((constraints.maxWidth - spacing) / 2)
            .clamp(170.0, 360.0)
            .toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            ...dropdownFields.map((f) => SizedBox(width: fieldWidth, child: f)),
            ...textFields.map((f) => SizedBox(width: fieldWidth, child: f)),
          ],
        );
      },
    );
  }

  Widget _buildRow(List<Widget> children, double spacing) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}
