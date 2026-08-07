import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';

void main() {
  group('EnrollmentDetailIntent', () {
    test('toLocation construit l’url detail avec query params', () {
      const intent = EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.newFirstRegistration,
        enrollmentId: 'enrollment-1',
      );

      expect(
        intent.toLocation(),
        '/enrollments/detail/enrollment-1?origin=newFirstRegistration',
      );
    });

    test(
      'fromRouteContext conserve le vrai enrollmentId pour newFirstRegistration',
      () {
        final intent = EnrollmentDetailIntent.fromRouteContext(
          enrollmentId: 'enrollment-1',
          queryParameters: const {'origin': 'newFirstRegistration'},
        );

        expect(intent.origin, EnrollmentDetailOrigin.newFirstRegistration);
        expect(intent.enrollmentId, 'enrollment-1');
      },
    );

    test('toLocation inclut le status pour firstRegistration', () {
      const intent = EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.firstRegistration,
        enrollmentId: 'enrollment-42',
        status: 'IN_PROGRESS',
      );

      expect(
        intent.toLocation(),
        '/enrollments/detail/enrollment-42?origin=firstRegistration&status=IN_PROGRESS',
      );
    });

    test('fromRouteContext parse le status pour firstRegistration', () {
      final intent = EnrollmentDetailIntent.fromRouteContext(
        enrollmentId: 'enrollment-42',
        queryParameters: const {
          'origin': 'firstRegistration',
          'status': 'COMPLETED',
        },
      );

      expect(intent.origin, EnrollmentDetailOrigin.firstRegistration);
      expect(intent.status, 'COMPLETED');
    });

    test('toLocation inclut enrollmentType pour localDraftResume (reprise '
        'd\'un brouillon RE — évite la corruption du type au re-save) ; pas '
        'de status (draftStatus est dérivé du type par la policy)', () {
      const intent = EnrollmentDetailIntent.localDraftResume(
        enrollmentId: 'draft-1',
        studentId: 'stu-1',
        enrollmentType: 'RE_ENROLLMENT',
      );

      expect(
        intent.toLocation(),
        '/enrollments/detail/draft-1?origin=localDraftResume&studentId=stu-1'
        '&enrollmentType=RE_ENROLLMENT',
      );
    });

    test('fromRouteContext parse enrollmentType pour localDraftResume', () {
      final intent = EnrollmentDetailIntent.fromRouteContext(
        enrollmentId: 'draft-1',
        queryParameters: const {
          'origin': 'localDraftResume',
          'enrollmentType': 'RE_ENROLLMENT',
        },
      );

      expect(intent.origin, EnrollmentDetailOrigin.localDraftResume);
      expect(intent.enrollmentType, 'RE_ENROLLMENT');
    });

    test('fromRouteContext ignore un status parasite dans l\'url pour '
        'localDraftResume (le constructeur nommé ne l\'accepte plus — '
        'draftStatus est dérivé du type, jamais lu depuis l\'url)', () {
      final intent = EnrollmentDetailIntent.fromRouteContext(
        enrollmentId: 'draft-1',
        queryParameters: const {
          'origin': 'localDraftResume',
          'enrollmentType': 'RE_ENROLLMENT',
          'status': 'PRE_REGISTERED',
        },
      );

      expect(intent.status, isNull);
    });

    test(
      'toLocation porte le preEnrollmentId via studentId pour preRegistration '
      '(candidat brut, enrollmentId encore vide)',
      () {
        const intent = EnrollmentDetailIntent.preRegistration(
          enrollmentId: '',
          studentId: 'pre-1',
        );

        expect(
          intent.toLocation(),
          '/enrollments/detail/?origin=preRegistration&studentId=pre-1',
        );
      },
    );

    test('fromRouteContext round-trip : le preEnrollmentId (studentId) survit '
        'même quand le segment de route est le placeholder littéral `new` — '
        'régression du bug de perte d\'id au round-trip GoRouter', () {
      final intent = EnrollmentDetailIntent.fromRouteContext(
        enrollmentId: 'new',
        queryParameters: const {
          'origin': 'preRegistration',
          'studentId': 'pre-1',
        },
      );

      expect(intent.origin, EnrollmentDetailOrigin.preRegistration);
      expect(intent.studentId, 'pre-1');
    });

    test(
      'fromRouteContext sans studentId (dossier déjà connu) → studentId null, '
      'rétro-compatible',
      () {
        final intent = EnrollmentDetailIntent.fromRouteContext(
          enrollmentId: 'e-existing',
          queryParameters: const {'origin': 'preRegistration'},
        );

        expect(intent.origin, EnrollmentDetailOrigin.preRegistration);
        expect(intent.enrollmentId, 'e-existing');
        expect(intent.studentId, isNull);
      },
    );
  });
}
