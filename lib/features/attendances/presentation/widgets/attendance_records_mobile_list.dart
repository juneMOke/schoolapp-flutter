import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_row_editors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceRecordsMobileList extends StatelessWidget {
  final List<AttendanceEditableRow> rows;
  final String classroomName;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  const AttendanceRecordsMobileList({
    super.key,
    required this.rows,
    required this.classroomName,
    this.physics = const ClampingScrollPhysics(),
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: rows.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border.withValues(alpha: 0.6),
      ),
      itemBuilder: (context, index) {
        return _AttendanceCallRow(
          row: rows[index],
          classroomName: classroomName,
        );
      },
    );
  }
}

class _AttendanceCallRow extends StatelessWidget {
  final AttendanceEditableRow row;
  final String classroomName;

  const _AttendanceCallRow({required this.row, required this.classroomName});

  Color get _statusBarColor {
    if (row.present) return AppColors.success;
    if (row.absenceReason != null) return AppColors.warning;
    return AppColors.danger;
  }

  Color get _rowBackground {
    if (row.present) return Colors.transparent;
    return const Color.fromRGBO(192, 57, 43, 0.02);
  }

  String _buildFullName() {
    final middle = (row.studentMiddleName ?? '').trim();
    if (middle.isEmpty) return row.studentLastName;
    return '${row.studentLastName} $middle';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.outCurve,
      decoration: BoxDecoration(
        color: _rowBackground,
        border: Border(left: BorderSide(color: _statusBarColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: AppDimensions.minTouchTarget,
              child: Row(
                children: [
                  StudentAvatar(
                    firstName: row.studentFirstName,
                    lastName: row.studentLastName,
                    studentId: row.studentId,
                    size: 34,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _buildFullName(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${row.studentFirstName} · $classroomName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  if (row.hasValidationError) ...[
                    _MotifRequisChip(),
                    const SizedBox(width: AppDimensions.spacingS),
                  ],
                  AttendancePresenceSwitch(
                    value: row.present,
                    onChanged: (value) {
                      context.read<AttendanceBloc>().add(
                        AttendancePresenceToggled(
                          studentId: row.studentId,
                          present: value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.outCurve,
              child: row.present
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(
                        top: AppDimensions.spacingS,
                        left: _AbsencePanel.indent,
                      ),
                      child: _AbsencePanel(row: row),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotifRequisChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 12,
            color: AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            l10n.attendanceMotifRequisLabel,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbsencePanel extends StatelessWidget {
  static const double indent = 42;
  static const double reasonFieldWidth = 220;

  final AttendanceEditableRow row;

  const _AbsencePanel({required this.row});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: reasonFieldWidth,
          child: AttendanceAbsenceReasonField(
            value: row.absenceReason,
            enabled: true,
            showValidationError: row.hasValidationError,
            autofocus: row.absenceReason == null,
            onChanged: (reason) {
              context.read<AttendanceBloc>().add(
                AttendanceAbsenceReasonChanged(
                  studentId: row.studentId,
                  absenceReason: reason,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: AttendanceAbsenceNoteField(
            value: row.absenceReasonNote,
            enabled: true,
            onChanged: (note) {
              context.read<AttendanceBloc>().add(
                AttendanceAbsenceNoteChanged(
                  studentId: row.studentId,
                  note: note,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
