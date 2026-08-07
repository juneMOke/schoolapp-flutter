import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_transfer_pull_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_transfer_pull_repository.dart';

class MockRepo extends Mock implements ClassroomTransferPullRepository {}

void main() {
  late MockRepo repo;
  late ClassroomTransferPullHandler handler;

  setUp(() {
    repo = MockRepo();
    handler = ClassroomTransferPullHandler(repo);
  });

  test('resource == classroom_transfers', () {
    expect(handler.resource, ClassroomTransferPullRepositoryImpl.resource);
  });

  test('updated → PullResult.updated', () async {
    when(() => repo.syncTransfers()).thenAnswer(
      (_) async => const Right(
        ClassroomTransferPullOutcome(
          upserted: 3,
          notModified: false,
          bootstrapComplete: true,
          syncedAt: 1,
        ),
      ),
    );
    final outcome = await handler.pull();
    expect(outcome.result, PullResult.updated);
    expect(outcome.upserted, 3);
  });

  test('notModified → PullResult.notModified', () async {
    when(() => repo.syncTransfers()).thenAnswer(
      (_) async =>
          const Right(ClassroomTransferPullOutcome.notModifiedAt(1, 'cur')),
    );
    expect((await handler.pull()).result, PullResult.notModified);
  });

  test('Left → PullResult.error', () async {
    when(
      () => repo.syncTransfers(),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));
    expect((await handler.pull()).result, PullResult.error);
  });
}
