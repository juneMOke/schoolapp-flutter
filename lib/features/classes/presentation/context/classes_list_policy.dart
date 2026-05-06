import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_origin.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

abstract class ClassesListPolicy {
  const ClassesListPolicy();

  void onEnrollmentViewRequested(
    BuildContext context,
    EnrollmentSummary summary, {
    ClassesListSearchRequest? request,
  });

  void onClassroomMemberViewRequested(
    BuildContext context,
    ClassroomMember member, {
    ClassesListSearchRequest? request,
  });
}

class ClassesListPolicyResolver {
  const ClassesListPolicyResolver._();

  static ClassesListPolicy fromIntent(ClassesListIntent intent) {
    return switch (intent.origin) {
      ClassesListOrigin.classesList => const DefaultClassesListPolicy(),
      ClassesListOrigin.disciplinesList =>
        const DisciplinesClassesListPolicy(),
    };
  }
}

class DefaultClassesListPolicy extends ClassesListPolicy {
  const DefaultClassesListPolicy();

  @override
  void onEnrollmentViewRequested(
    BuildContext context,
    EnrollmentSummary summary, {
    ClassesListSearchRequest? request,
  }) {
    final intent = EnrollmentDetailIntent(
      origin: EnrollmentDetailOrigin.firstRegistration,
      enrollmentId: summary.enrollmentId,
      studentId: summary.student.id,
      status: summary.status,
    );

    context.push(intent.toLocation(), extra: intent);
  }

  @override
  void onClassroomMemberViewRequested(
    BuildContext context,
    ClassroomMember member, {
    ClassesListSearchRequest? request,
  }) {
    final l10n = AppLocalizations.of(context)!;
    AppSnackBar.showInfo(context, l10n.classesListStudentDetailSoon);
  }
}

class DisciplinesClassesListPolicy extends ClassesListPolicy {
  const DisciplinesClassesListPolicy();

  @override
  void onEnrollmentViewRequested(
    BuildContext context,
    EnrollmentSummary summary, {
    ClassesListSearchRequest? request,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final academicYearId = _resolveAcademicYearId(context);
    if (academicYearId == null) {
      AppSnackBar.showError(context, l10n.bootstrapContextUnavailableMessage);
      return;
    }

    final intent = DisciplinaryStudentDetailIntent(
      studentId: summary.student.id,
      studentFirstName: summary.student.firstName,
      studentLastName: summary.student.lastName,
      studentMiddleName: summary.student.surname,
      studentGender: _mapEnrollmentGender(summary.student.gender),
      academicYearId: academicYearId,
      levelName: _resolveLevelName(request),
      levelGroupName: _resolveLevelGroupName(request),
    );

    context.push(
      AppRoutesNames.disciplinaryStudentDetailPath(
        studentId: summary.student.id,
        academicYearId: academicYearId,
      ),
      extra: intent,
    );
  }

  @override
  void onClassroomMemberViewRequested(
    BuildContext context,
    ClassroomMember member, {
    ClassesListSearchRequest? request,
  }) {
    final intent = DisciplinaryStudentDetailIntent(
      studentId: member.studentId,
      studentFirstName: member.studentFirstName,
      studentLastName: member.studentLastName,
      studentMiddleName: member.studentMiddleName,
      studentGender: _mapClassroomMemberGender(member.studentGender),
      academicYearId: member.academicYearId,
      levelName: _resolveLevelName(request),
      levelGroupName: _resolveLevelGroupName(request),
    );

    context.push(
      AppRoutesNames.disciplinaryStudentDetailPath(
        studentId: member.studentId,
        academicYearId: member.academicYearId,
      ),
      extra: intent,
    );
  }

  String? _resolveAcademicYearId(BuildContext context) {
    final bootstrap = context.read<BootstrapBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
    if (academicYearId.trim().isEmpty) {
      return null;
    }
    return academicYearId;
  }

  String _mapEnrollmentGender(Gender gender) => switch (gender) {
    Gender.male => 'MALE',
    Gender.female => 'FEMALE',
  };

  String _mapClassroomMemberGender(ClassroomMemberGender gender) =>
      switch (gender) {
        ClassroomMemberGender.male => 'MALE',
        ClassroomMemberGender.female => 'FEMALE',
        ClassroomMemberGender.other => 'OTHER',
      };

  String _resolveLevelName(ClassesListSearchRequest? request) =>
      request?.selectedLevel.label.trim() ?? '';

  String _resolveLevelGroupName(ClassesListSearchRequest? request) =>
      request?.selectedLevel.schoolLevelGroupName.trim() ?? '';
}
