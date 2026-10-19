import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';
import 'package:school_app_flutter/features/student/domain/usecases/find_student_identity_use_case.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_identity_cubit.dart';

class _MockFind extends Mock implements FindStudentIdentityUseCase {}

void main() {
  late _MockFind find;
  const identity = StudentIdentity(
    studentId: 's1',
    firstName: 'Grâce',
    lastName: 'MBUYI',
  );

  setUp(() => find = _MockFind());

  void answer(Either<Failure, StudentIdentity?> result) => when(
    () => find(
      studentId: any(named: 'studentId'),
      academicYearId: any(named: 'academicYearId'),
    ),
  ).thenAnswer((_) async => result);

  blocTest<StudentIdentityCubit, StudentIdentityState>(
    'rend l’identité trouvée',
    setUp: () => answer(const Right(identity)),
    build: () => StudentIdentityCubit(find),
    act: (cubit) => cubit.resolve(studentId: 's1', academicYearId: 'y1'),
    expect: () => [
      const StudentIdentityState(resolved: true, identity: identity),
    ],
  );

  blocTest<StudentIdentityCubit, StudentIdentityState>(
    'une lecture en échec vaut « inconnu »',
    setUp: () => answer(const Left(StorageFailure())),
    build: () => StudentIdentityCubit(find),
    act: (cubit) => cubit.resolve(studentId: 's1', academicYearId: 'y1'),
    expect: () => [const StudentIdentityState(resolved: true)],
  );
}
