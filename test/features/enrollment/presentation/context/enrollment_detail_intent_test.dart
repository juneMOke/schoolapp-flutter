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
  });
}
