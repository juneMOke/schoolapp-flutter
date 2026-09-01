import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_search_actions.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceSearchFields extends StatelessWidget {
  final List<AttendanceCycleOption> cycleOptions;
  final String? selectedCycleId;
  final List<AttendanceLevelOption> levelOptions;
  final String? selectedLevelKey;
  final List<OfflineClassroom> classroomOptions;
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
      _AttendanceSelectField(
        width: AppDimensions.attendanceCycleFieldWidth,
        label: l10n.attendanceCycleLabel,
        value: selectedCycleId,
        items: cycleOptions
            .map(
              (option) => EteeloSelectItem<String>(
                value: option.id,
                label: option.label,
              ),
            )
            .toList(growable: false),
        onChanged: cycleOptions.isEmpty ? null : onCycleChanged,
      ),
      _AttendanceSelectField(
        width: AppDimensions.attendanceLevelFieldWidth,
        label: l10n.attendanceLevelLabel,
        value: selectedLevelKey,
        items: levelOptions
            .map(
              (option) => EteeloSelectItem<String>(
                value: option.key,
                label: option.label,
              ),
            )
            .toList(growable: false),
        onChanged: levelOptions.isEmpty ? null : onLevelChanged,
      ),
      _AttendanceSelectField(
        width: AppDimensions.attendanceClassFieldWidth,
        label: l10n.attendanceClassLabel,
        value: selectedClassroomId,
        items: classroomOptions
            .map(
              (classroom) => EteeloSelectItem<String>(
                value: classroom.id,
                label: classroom.name,
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
                  // Les trois selects portent leur libellé AU-DESSUS du champ
                  // (design-system) ; sans alignement bas, le bouton de date,
                  // qui n'en a pas, flotterait au milieu de leur hauteur.
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: fields,
                ),
        );
      },
    );
  }
}

class _AttendanceSelectField extends StatelessWidget {
  final double width;
  final String label;
  final String? value;
  final List<EteeloSelectItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const _AttendanceSelectField({
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
      child: EteeloSelectInput<String>(
        label: label,
        value: value,
        items: items,
        // Une liste vide (référentiel pas encore descendu) grise le champ :
        // c'est le repère « pas disponible » du design-system, pas un champ
        // ouvert sur rien.
        enabled: onChanged != null,
        // Les largeurs du filtre d'appel (170 dp) sont plus étroites que le
        // plancher par défaut du select : c'est la barre qui commande ici.
        minWidth: 0,
        onChanged: (selected) => onChanged?.call(selected),
      ),
    );
  }
}
