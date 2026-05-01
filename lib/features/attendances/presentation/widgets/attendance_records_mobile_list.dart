import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_row_editors.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_style_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceRecordsMobileList extends StatelessWidget {
  final List<AttendanceEditableRow> rows;
  final Set<String> modifiedStudentIds;

  const AttendanceRecordsMobileList({
    super.key,
    required this.rows,
    required this.modifiedStudentIds,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.spacingS),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _AttendanceRecordCard(
          row: row,
          isModified: modifiedStudentIds.contains(row.studentId),
        );
      },
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  final AttendanceEditableRow row;
  final bool isModified;

  const _AttendanceRecordCard({required this.row, required this.isModified});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPresent = row.present;
    final isAbsent = !isPresent;
    final statusBackground = isPresent
        ? AppColors.financeDetailSuccessSoft
        : AppColors.financeDetailDangerSoft;
    final statusForeground = isPresent ? AppColors.success : AppColors.danger;
    final hasError = row.hasValidationError;
    final cardBackground = AttendanceStyleTokens.cardBackground(
      isPresent: isPresent,
      hasError: hasError,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.detailCompactMax;
        final cardPadding = isWide
            ? AttendanceStyleTokens.cardPaddingCompact
            : AttendanceStyleTokens.cardPaddingDefault;
        final headerToSwitchSpacing =
            isWide ? AppDimensions.spacingXS : AppDimensions.spacingS;
        final absenceTopSpacing = isWide ? AppDimensions.spacingXS : AppDimensions.spacingS;

        return Semantics(
          container: true,
          label: _buildDisplayName(),
          value: isPresent ? l10n.attendancePresentValue : l10n.attendanceAbsentValue,
          hint: hasError ? l10n.attendanceReasonRequiredError : null,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.outCurve,
            width: double.infinity,
            padding: cardPadding,
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
              border: Border.all(
                color: hasError ? AppColors.danger : AppColors.border,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.financeDetailShadow,
                  blurRadius: AppDimensions.classesOrganisationShadowBlur,
                  offset: Offset(0, AppDimensions.spacingXS),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _buildDisplayName(),
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: AttendanceStyleTokens.recordNameFontSize,
                          ),
                        ),
                        if (hasError) ...[
                          const SizedBox(height: AppDimensions.spacingXS),
                          Text(
                            l10n.attendanceReasonRequiredError,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: AttendanceStyleTokens.recordHelperFontSize,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Semantics(
                        readOnly: true,
                        label: l10n.attendancePresenceStatusLabel,
                        value: isPresent
                            ? l10n.attendancePresentValue
                            : l10n.attendanceAbsentValue,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                            border: Border.all(
                              color: statusForeground.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            isPresent
                                ? l10n.attendancePresentValue
                                : l10n.attendanceAbsentValue,
                            style: AppTextStyles.badge.copyWith(
                              color: statusForeground,
                              fontSize: AttendanceStyleTokens.badgeFontSize,
                            ),
                          ),
                        ),
                      ),
                      if (isModified) ...[
                        const SizedBox(height: AppDimensions.spacingXS),
                        Semantics(
                          readOnly: true,
                          label: l10n.attendanceRowModifiedLabel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingS,
                              vertical: AppDimensions.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.financeDetailAccentSoft,
                              borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                            ),
                            child: Text(
                              l10n.attendanceRowModifiedLabel,
                              style: AppTextStyles.badge.copyWith(
                                color: AppColors.financeDetailAccent,
                                fontSize: AttendanceStyleTokens.badgeFontSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: headerToSwitchSpacing),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.financeDetailMutedSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingXS,
                      ),
                      child: Text(
                        l10n.attendancePresenceStatusLabel,
                        style: AppTextStyles.tableHeader.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AttendancePresenceSwitch(
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
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                child: isAbsent
                    ? Padding(
                        padding: EdgeInsets.only(top: absenceTopSpacing),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
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
                              )
                            : Column(
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
                      )
                    : const SizedBox.shrink(),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildDisplayName() {
    return [
      row.studentLastName,
      row.studentMiddleName,
      row.studentFirstName,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(' ');
  }
}
