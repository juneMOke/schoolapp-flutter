import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspended_member.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/repositories/enrollment_suspension_repository.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/enrollment_suspension_status_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/open_suspensions_count_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspended_members_cubit.dart';

class _InertSuspensionRepository extends Mock
    implements EnrollmentSuspensionRepository {}

/// Le module de désactivation, inerte, pour les tests qui montent un écran
/// portant l'état de désactivation sans en parler : aucun élève n'est
/// désactivé. Rend de quoi le démonter.
Future<void> Function() registerInertSuspensionModule() {
  final repository = _InertSuspensionRepository();
  final changes = StreamController<Set<String>>.broadcast();
  when(() => repository.changes).thenAnswer((_) => changes.stream);
  when(
    () => repository.latestFor(any()),
  ).thenAnswer((_) async => const Right<Never, StudentSuspension?>(null));
  when(
    () => repository.suspendedMembers(any()),
  ).thenAnswer((_) async => const Right(<SuspendedMember>[]));
  when(
    () => repository.openByEnrollment(any()),
  ).thenAnswer((_) async => const Right(<String, StudentSuspension>{}));
  getIt.registerFactoryParam<SuspendedMembersCubit, String, void>(
    (yearId, _) => SuspendedMembersCubit(
      LoadSuspendedMembersUseCase(repository),
      academicYearId: yearId,
    ),
  );
  getIt.registerFactoryParam<OpenSuspensionsCountCubit, String, void>(
    (yearId, _) => OpenSuspensionsCountCubit(
      LoadOpenSuspensionsUseCase(repository),
      academicYearId: yearId,
    ),
  );
  getIt.registerFactoryParam<EnrollmentSuspensionStatusCubit, String, void>(
    (enrollmentId, _) => EnrollmentSuspensionStatusCubit(
      LoadEnrollmentSuspensionUseCase(repository),
      enrollmentId: enrollmentId,
    ),
  );
  return () async {
    await changes.close();
    for (final unregister in [
      () => getIt.unregister<EnrollmentSuspensionStatusCubit>(),
      () => getIt.unregister<SuspendedMembersCubit>(),
      () => getIt.unregister<OpenSuspensionsCountCubit>(),
    ]) {
      // Déjà parti si le test a remis GetIt à zéro avant.
      try {
        await unregister();
      } catch (_) {}
    }
  };
}
