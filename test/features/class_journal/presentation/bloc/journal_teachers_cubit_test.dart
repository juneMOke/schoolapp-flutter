import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_teacher.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_direction_repository.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_teachers_cubit.dart';

class _MockDirection extends Mock implements JournalDirectionRepository {}

void main() {
  late _MockDirection direction;

  setUp(() => direction = _MockDirection());

  test('charge les enseignants ; le choix survit à un rechargement', () async {
    when(() => direction.teachers()).thenAnswer(
      (_) async =>
          const Right([JournalTeacher(id: 't', displayName: 'Mokili')]),
    );
    final cubit = JournalTeachersCubit(direction);

    await cubit.load();
    cubit.select('t');
    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.teachers.single.id, 't');
    expect(cubit.state.selectedId, 't');
    await cubit.close();
  });

  test('un échec de lecture se garde pour l\'afficher', () async {
    when(
      () => direction.teachers(),
    ).thenAnswer((_) async => const Left(NetworkFailure('hors ligne')));
    final cubit = JournalTeachersCubit(direction);

    await cubit.load();

    expect(cubit.state.failure, isA<NetworkFailure>());
    await cubit.close();
  });
}
