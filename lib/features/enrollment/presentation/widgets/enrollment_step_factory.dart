import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/previous_academic_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/summary_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/target_academic_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_metadata.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';

class EnrollmentStepFactory {
  final EnrollmentDetail enrollmentDetail;
  final EnrollmentDetailIntent detailIntent;
  final EnrollmentDetailPolicy detailPolicy;
  final VoidCallback onRefreshRequested;
  final ValueChanged<int> onSummaryEditRequested;
  final GlobalKey<PersonalInfoStepState> personalInfoKey;
  final GlobalKey<AddressStepState> addressKey;
  final GlobalKey<PreviousAcademicInfoStepState> academicInfoKey;
  final GlobalKey<TargetAcademicInfoStepState> academicTargetInfoKey;
  final GlobalKey<StudentChargesStepState> studentChargesKey;
  final GlobalKey<GuardianInfoStepState> guardianInfoKey;

  const EnrollmentStepFactory({
    required this.enrollmentDetail,
    required this.detailIntent,
    required this.detailPolicy,
    required this.onRefreshRequested,
    required this.onSummaryEditRequested,
    required this.personalInfoKey,
    required this.addressKey,
    required this.academicInfoKey,
    required this.academicTargetInfoKey,
    required this.studentChargesKey,
    required this.guardianInfoKey,
  });

  List<Widget> build() {
    final effectiveStudentId = resolveStudentId();
    final effectiveLevelId = resolveLevelId();

    return <Widget>[
      PersonalInfoStep(
        key: personalInfoKey,
        studentDetail: enrollmentDetail.studentDetail,
        enrollmentId: enrollmentDetail.enrollmentDetail.id,
        detailIntent: detailIntent,
        detailPolicy: detailPolicy,
        showInlineSaveButton: false,
        flowStepIndex: EnrollmentWizardStep.personalInfo.index,
        onRefreshRequested: onRefreshRequested,
        isEditable: detailPolicy.isStepEditable(EnrollmentWizardStep.personalInfo),
      ),
      AddressStep(
        key: addressKey,
        studentDetail: enrollmentDetail.studentDetail,
        enrollmentId: enrollmentDetail.enrollmentDetail.id,
        showInlineSaveButton: false,
        flowStepIndex: EnrollmentWizardStep.address.index,
        onRefreshRequested: onRefreshRequested,
        isEditable: detailPolicy.isStepEditable(EnrollmentWizardStep.address),
      ),
      PreviousAcademicInfoStep(
        key: academicInfoKey,
        enrollmentDetail: enrollmentDetail.enrollmentDetail,
        enrollmentId: enrollmentDetail.enrollmentDetail.id,
        showInlineSaveButton: false,
        flowStepIndex: EnrollmentWizardStep.previousAcademic.index,
        onRefreshRequested: onRefreshRequested,
        isEditable: detailPolicy.isStepEditable(EnrollmentWizardStep.previousAcademic),
      ),
      TargetAcademicInfoStep(
        key: academicTargetInfoKey,
        studentDetail: enrollmentDetail.studentDetail,
        studentId: effectiveStudentId,
        enrollmentId: enrollmentDetail.enrollmentDetail.id,
        showInlineSaveButton: false,
        flowStepIndex: EnrollmentWizardStep.targetAcademic.index,
        onRefreshRequested: onRefreshRequested,
        isEditable: detailPolicy.isStepEditable(EnrollmentWizardStep.targetAcademic),
      ),
      StudentChargesStep(
        key: studentChargesKey,
        studentId: effectiveStudentId,
        levelId: effectiveLevelId,
        enrollmentStatus: enrollmentDetail.enrollmentDetail.status,
        showInlineSaveButton: false,
        flowStepIndex: EnrollmentWizardStep.studentCharges.index,
        isEditable: detailPolicy.isStepEditable(EnrollmentWizardStep.studentCharges),
      ),
      GuardianInfoStep(
        key: guardianInfoKey,
        parentDetails: enrollmentDetail.parentDetails,
        studentId: effectiveStudentId,
        flowStepIndex: EnrollmentWizardStep.guardian.index,
        enrollmentId: enrollmentDetail.enrollmentDetail.id,
        showInlineSaveButton: false,
        onRefreshRequested: onRefreshRequested,
        isEditable: detailPolicy.isStepEditable(EnrollmentWizardStep.guardian),
      ),
      SummaryStep(
        enrollmentDetail: enrollmentDetail,
        onEditRequested: onSummaryEditRequested,
      ),
    ];
  }

  String resolveStudentId() {
    final detailStudentId = enrollmentDetail.studentDetail.id.trim();
    if (detailStudentId.isNotEmpty) {
      return detailStudentId;
    }

    return detailIntent.studentId?.trim() ?? '';
  }

  String resolveLevelId() {
    final enrollmentLevelId = enrollmentDetail.enrollmentDetail.schoolLevelId.trim();
    if (enrollmentLevelId.isNotEmpty) {
      return enrollmentLevelId;
    }

    return enrollmentDetail.studentDetail.schoolLevel.id.trim();
  }
}
