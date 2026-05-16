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

class AttendanceRecordsMobileList extends StatelessWidget {
  final List<AttendanceEditableRow> rows;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  const AttendanceRecordsMobileList({
    super.key,
    required this.rows,
    this.physics = const ClampingScrollPhysics(),
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: rows.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.spacingXS),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _AttendanceRecordRow(row: row);
      },
    );
  }
}

class _AttendanceRecordRow extends StatelessWidget {
  final AttendanceEditableRow row;

  const _AttendanceRecordRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final isPresent = row.present;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.outCurve,
      padding: const EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: isPresent
            ? AppColors.surface
            : AppColors.financeDetailDangerSoft.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
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
                  size: AppDimensions.attendanceStudentAvatarSize,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildPrimaryName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if ((row.studentMiddleName ?? '').trim().isNotEmpty)
                        Text(
                          row.studentMiddleName!.trim(),
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
                    padding: const EdgeInsets.only(top: AppDimensions.spacingS),
                    child: Column(
                      children: [
                        AttendanceAbsenceReasonField(
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
                        const SizedBox(height: AppDimensions.spacingS),
                        AttendanceAbsenceNoteField(
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
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _buildPrimaryName() =>
      '${row.studentLastName} ${row.studentFirstName}'.trim();
}
