import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';

void main() {
  group('EnrollmentDetailPolicyResolver - first registration', () {
    test('status COMPLETED => read-only for editable steps', () {
      const intent = EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.firstRegistration,
        enrollmentId: 'e1',
        status: 'COMPLETED',
      );
      final policy = EnrollmentDetailPolicyResolver.fromIntent(intent);

      expect(
        policy.isStepEditable(EnrollmentWizardStep.personalInfo),
        isFalse,
      );
      expect(policy.isStepEditable(EnrollmentWizardStep.address), isFalse);
      expect(policy.isStepEditable(EnrollmentWizardStep.summary), isFalse);
    });

    test('status IN_PROGRESS => editable except summary', () {
      const intent = EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.firstRegistration,
        enrollmentId: 'e1',
        status: 'IN_PROGRESS',
      );
      final policy = EnrollmentDetailPolicyResolver.fromIntent(intent);

      expect(policy.isStepEditable(EnrollmentWizardStep.personalInfo), isTrue);
      expect(policy.isStepEditable(EnrollmentWizardStep.address), isTrue);
      expect(policy.isStepEditable(EnrollmentWizardStep.summary), isFalse);
    });
  });
}
