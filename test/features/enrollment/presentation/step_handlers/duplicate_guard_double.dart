import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_enrollment_duplicates_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/enrollment_duplicate_guard.dart';

class _MockEnrollmentOfflineRepository extends Mock
    implements EnrollmentOfflineRepository {}

/// Garde de doublon **inerte** : elle n'existe que pour satisfaire le câblage
/// des handlers, et n'est jamais sollicitée par les tests qui l'utilisent.
///
/// Le comportement de la sonde, lui, se vérifie dans
/// `enrollment_duplicate_guard_test.dart` — avec un usecase qu'on pilote.
EnrollmentDuplicateGuard inertDuplicateGuard() => EnrollmentDuplicateGuard(
  ProbeEnrollmentDuplicatesUseCase(_MockEnrollmentOfflineRepository()),
);
