import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/enrollment_suspension_status_cubit.dart';

class _MockLoad extends Mock implements LoadEnrollmentSuspensionUseCase {}

StudentSuspension _open() => StudentSuspension(
  id: 'p',
  enrollmentId: 'enr-1',
  studentId: 's',
  academicYearId: 'y',
  suspendedAt: DateTime(2026, 10, 2),
);

void main() {
  test('se relit quand son inscription change, pas pour une autre', () async {
    final load = _MockLoad();
    final changes = StreamController<Set<String>>.broadcast();
    when(() => load.changes).thenAnswer((_) => changes.stream);
    var current = const Right<Never, StudentSuspension?>(null);
    when(() => load('enr-1')).thenAnswer((_) async => current);

    final cubit = EnrollmentSuspensionStatusCubit(load, enrollmentId: 'enr-1');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isSuspended, isFalse);

    current = Right(_open());
    changes.add({'autre'});
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isSuspended, isFalse);

    changes.add({'enr-1'});
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isSuspended, isTrue);

    await cubit.close();
    await changes.close();
  });
}
