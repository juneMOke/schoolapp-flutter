import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

void main() {
  // EnrollmentEvent est sealed (part-of du bloc) : on enregistre un vrai
  // événement concret comme valeur de repli pour `any()`.
  setUpAll(
    () => registerFallbackValue(const EnrollmentSummariesRefreshRequested()),
  );

  group('EnrollmentDetailPolicy.seedsFromLocalRef', () {
    test('RE et PRE → true (seed lu depuis la cohorte / préinscriptions)', () {
      expect(const ReRegistrationDetailPolicy().seedsFromLocalRef, isTrue);
      expect(const PreRegistrationDetailPolicy().seedsFromLocalRef, isTrue);
    });

    test('NEW, reprise et consultation → false (pas de seed cohorte)', () {
      expect(
        const NewFirstRegistrationDetailPolicy().seedsFromLocalRef,
        isFalse,
      );
      expect(
        const FirstRegistrationDetailPolicy(
          status: 'IN_PROGRESS',
        ).seedsFromLocalRef,
        isFalse,
      );
      expect(const LocalConsultationDetailPolicy().seedsFromLocalRef, isFalse);
    });
  });

  group('requestLoad RE/PRE inerte (le seed vient du local)', () {
    test('RE → aucun événement online dispatché', () {
      final bloc = _MockEnrollmentBloc();
      const ReRegistrationDetailPolicy().requestLoad(
        bloc,
        const EnrollmentDetailIntent.reRegistration(
          enrollmentId: 'e1',
          studentId: 's1',
        ),
      );
      verifyNever(() => bloc.add(any()));
    });

    test('PRE → aucun événement online dispatché', () {
      final bloc = _MockEnrollmentBloc();
      const PreRegistrationDetailPolicy().requestLoad(
        bloc,
        const EnrollmentDetailIntent.preRegistration(enrollmentId: 'pre-1'),
      );
      verifyNever(() => bloc.add(any()));
    });
  });
}
