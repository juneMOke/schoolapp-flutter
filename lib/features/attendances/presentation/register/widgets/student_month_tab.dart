import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_card_frame.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_incident_list.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_month_placeholder.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/student_month_header.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/student_month_kpis.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'onglet « Fiche mensuelle » : un élève, un mois, en lecture seule.
class StudentMonthTab extends StatelessWidget {
  final ClassPresenceState state;

  const StudentMonthTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ClassPresenceCubit>();
    final data = state.monthData;
    final sheet = state.studentMonth;
    final students = data?.students ?? const <ClassPresenceStudent>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            PresencePersonPicker<ClassPresenceStudent>(
              entries: [
                for (final s in students)
                  PresencePickerEntry(
                    value: s,
                    id: s.id,
                    firstName: s.firstName,
                    lastName: s.lastName,
                    fullName: s.fullName,
                  ),
              ],
              selectedId: sheet?.student.id,
              showsStudentPhotos: true,
              label: l10n.classPresenceTabStudent,
              placeholder: l10n.classPresenceStudentPickerPlaceholder,
              matches: (s, text) => SearchNormalizationHelper.containsAllWords([
                s.lastName,
                s.middleName,
                s.firstName,
              ], text),
              onSelected: (s) => cubit.openStudent(s.id),
            ),
            PresenceMonthNav(
              month: state.month,
              isCurrent: state.isCurrentMonth,
              onPrevious: state.canStepMonthBack
                  ? () => unawaited(cubit.stepMonth(-1))
                  : null,
              onNext: () => unawaited(cubit.stepMonth(1)),
              onCurrent: () => unawaited(cubit.goCurrentMonth()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (classMonthPlaceholder(context, state) case final placeholder?)
          placeholder
        else if (sheet!.isHoliday)
          PresenceHolidayState(
            month: state.month,
            onCurrent: () => unawaited(cubit.goCurrentMonth()),
          )
        else ...[
          StudentMonthHeader(sheet: sheet, classroom: state.classroom!),
          const SizedBox(height: AppSpacing.lg),
          StudentMonthKpis(stats: sheet.stats),
          const SizedBox(height: AppSpacing.lg),
          PresenceCardFrame(
            title: sheet.student.fullName,
            child: PresenceMonthCalendar(days: sheet.calendar),
          ),
          const SizedBox(height: AppSpacing.lg),
          PresenceCardFrame(
            title: l10n.presenceMarkIncidentsTitle,
            child: PresenceIncidentList<AbsenceReason>(
              incidents: sheet.incidents,
              reasonLabel: (reason) => reason.getDisplayName(l10n),
            ),
          ),
        ],
      ],
    );
  }
}
