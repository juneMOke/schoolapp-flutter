import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_search_actions.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceSearchFields extends StatelessWidget {
  final List<AttendanceCycleOption> cycleOptions;
  final String? selectedCycleId;
  final List<AttendanceLevelOption> levelOptions;
  final String? selectedLevelKey;
  final List<BootstrapClassroom> classroomOptions;
  final String? selectedClassroomId;
  final DateTime selectedDate;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<String?> onLevelChanged;
  final ValueChanged<String?> onClassroomChanged;
  final Future<void> Function() onPickDate;

  const AttendanceSearchFields({
    super.key,
    required this.cycleOptions,
    required this.selectedCycleId,
    required this.levelOptions,
    required this.selectedLevelKey,
    required this.classroomOptions,
    required this.selectedClassroomId,
    required this.selectedDate,
    required this.onCycleChanged,
    required this.onLevelChanged,
    required this.onClassroomChanged,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = [
      _AttendanceDropdownField(
        width: AppDimensions.attendanceCycleFieldWidth,
        label: l10n.attendanceCycleLabel,
        value: selectedCycleId,
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
      _AttendanceDropdownField(
        width: AppDimensions.attendanceLevelFieldWidth,
        label: l10n.attendanceLevelLabel,
        value: selectedLevelKey,
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
      _AttendanceDropdownField(
        width: AppDimensions.attendanceClassFieldWidth,
        label: l10n.attendanceClassLabel,
        value: selectedClassroomId,
        items: classroomOptions
            .map(
              (classroom) => DropdownMenuItem<String>(
                value: classroom.id,
                child: Text(classroom.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(growable: false),
        onChanged: classroomOptions.isEmpty ? null : onClassroomChanged,
      ),
      AttendanceDateButton(
        date: selectedDate,
        onPickDate: onPickDate,
        width: AppDimensions.attendanceDateFieldWidth,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final canRenderSingleLine =
            constraints.maxWidth >=
            (AppDimensions.attendanceCycleFieldWidth +
                AppDimensions.attendanceLevelFieldWidth +
                AppDimensions.attendanceClassFieldWidth +
                AppDimensions.attendanceDateFieldWidth +
                (AppDimensions.spacingS * 3));

        return AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.outCurve,
          child: canRenderSingleLine
              ? Row(
                  children: [
                    fields[0],
                    const SizedBox(width: AppDimensions.spacingS),
                    fields[1],
                    const SizedBox(width: AppDimensions.spacingS),
                    fields[2],
                    const SizedBox(width: AppDimensions.spacingS),
                    fields[3],
                  ],
                )
              : Wrap(
                  spacing: AppDimensions.spacingS,
                  runSpacing: AppDimensions.spacingS,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: fields,
                ),
        );
      },
    );
  }
}

class _AttendanceDropdownField extends StatelessWidget {
  final double width;
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const _AttendanceDropdownField({
    required this.width,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: _fieldDecoration(label),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.background,
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
        borderSide: const BorderSide(
          color: AppColors.classesFocusRing,
          width: 1.6,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingS,
      ),
    );
  }
}
