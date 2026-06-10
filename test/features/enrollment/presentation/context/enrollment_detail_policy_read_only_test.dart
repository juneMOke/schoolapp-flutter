import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';

void main() {
  group('EnrollmentDetailPolicy.isReadOnlyConsultation', () {
    test('FirstRegistration IN_PROGRESS → éditable (pas de bandeau)', () {
      const policy = FirstRegistrationDetailPolicy(status: 'IN_PROGRESS');
      expect(policy.isReadOnlyConsultation, isFalse);
    });

    test(
      'FirstRegistration finalisé (COMPLETED) → consultation lecture seule',
      () {
        const policy = FirstRegistrationDetailPolicy(status: 'COMPLETED');
        expect(policy.isReadOnlyConsultation, isTrue);
      },
    );

    test('FirstRegistration status null → consultation lecture seule', () {
      const policy = FirstRegistrationDetailPolicy();
      expect(policy.isReadOnlyConsultation, isTrue);
    });

    test(
      'Création (NewFirstRegistration) → PAS lecture seule malgré Frais verrouillé',
      () {
        // Piège : l'étape Frais est isEditable:false même en création. Le signal
        // doit rester false ici (sinon le bandeau s'afficherait à la création).
        const policy = NewFirstRegistrationDetailPolicy();
        expect(policy.isReadOnlyConsultation, isFalse);
      },
    );

    test('PreRegistration → éditable', () {
      const policy = PreRegistrationDetailPolicy();
      expect(policy.isReadOnlyConsultation, isFalse);
    });

    test('ReRegistration → éditable', () {
      const policy = ReRegistrationDetailPolicy();
      expect(policy.isReadOnlyConsultation, isFalse);
    });
  });
}
