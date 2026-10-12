import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/usecases/announcement_writer.dart';

import '../../communication_fixtures.dart';

class _MockRepository extends Mock implements AnnouncementRepository {}

void main() {
  late _MockRepository repo;
  late AnnouncementWriter writer;
  const content = AnnouncementContent(title: 'T', body: 'B');
  final at = DateTime.utc(2026, 10, 13, 6, 30);

  setUpAll(() => registerFallbackValue(const AnnouncementContent()));

  setUp(() {
    repo = _MockRepository();
    writer = AnnouncementWriter(repo);
  });

  test(
    'neuf : créé avec l\'id de la tablette, puis envoyé avec sa version',
    () async {
      when(
        () => repo.create(id: 'uuid', content: content, academicYearId: 'y-1'),
      ).thenAnswer((_) async => Right(announcement(id: 'uuid', version: 1)));
      when(() => repo.send('uuid', version: 1)).thenAnswer(
        (_) async => Right(
          announcement(id: 'uuid', status: AnnouncementStatus.sent, version: 2),
        ),
      );
      final result = await writer.send(
        id: 'uuid',
        content: content,
        academicYearId: 'y-1',
      );
      expect(result.getOrElse(() => throw 'x').status, AnnouncementStatus.sent);
      verifyNever(
        () => repo.update(any(), any(), version: any(named: 'version')),
      );
    },
  );

  test('brouillon inchangé : aucun appel', () async {
    final current = announcement(title: 'T', body: 'B');
    final result = await writer.saveDraft(
      id: current.id,
      content: content,
      current: current,
    );
    expect(result, Right(current));
    verifyZeroInteractions(repo);
  });

  test('brouillon modifié : PUT avec la version vue', () async {
    final current = announcement(version: 4);
    when(() => repo.update(current.id, content, version: 4)).thenAnswer(
      (_) async => Right(announcement(title: 'T', body: 'B', version: 5)),
    );
    await writer.saveDraft(id: current.id, content: content, current: current);
    verify(() => repo.update(current.id, content, version: 4)).called(1);
  });

  test(
    'programmé repassé en brouillon : unschedule, puis PUT sur la version rendue',
    () async {
      final current = announcement(
        status: AnnouncementStatus.scheduled,
        scheduledAt: at,
        version: 2,
      );
      when(
        () => repo.unschedule(current.id, version: 2),
      ).thenAnswer((_) async => Right(announcement(version: 3)));
      when(() => repo.update(current.id, content, version: 3)).thenAnswer(
        (_) async => Right(announcement(title: 'T', body: 'B', version: 4)),
      );
      await writer.saveDraft(
        id: current.id,
        content: content,
        current: current,
      );
      verifyInOrder([
        () => repo.unschedule(current.id, version: 2),
        () => repo.update(current.id, content, version: 3),
      ]);
    },
  );

  test(
    'programmé, même heure, contenu modifié : PUT seul, pas de reprogrammation',
    () async {
      final current = announcement(
        status: AnnouncementStatus.scheduled,
        scheduledAt: at,
        version: 2,
      );
      when(() => repo.update(current.id, content, version: 2)).thenAnswer(
        (_) async => Right(
          announcement(
            status: AnnouncementStatus.scheduled,
            scheduledAt: at,
            version: 3,
          ),
        ),
      );
      final result = await writer.schedule(
        id: current.id,
        content: content,
        scheduledAt: at,
        current: current,
      );
      expect(result.isRight(), isTrue);
      verifyNever(
        () => repo.schedule(
          any(),
          scheduledAt: any(named: 'scheduledAt'),
          version: any(named: 'version'),
        ),
      );
      verifyNever(() => repo.unschedule(any(), version: any(named: 'version')));
    },
  );

  test('programmé, autre heure : unschedule puis schedule', () async {
    final current = announcement(
      status: AnnouncementStatus.scheduled,
      scheduledAt: at,
      title: 'T',
      body: 'B',
      version: 2,
    );
    final later = at.add(const Duration(hours: 1));
    when(() => repo.unschedule(current.id, version: 2)).thenAnswer(
      (_) async => Right(announcement(title: 'T', body: 'B', version: 3)),
    );
    when(
      () => repo.schedule(current.id, scheduledAt: later, version: 3),
    ).thenAnswer(
      (_) async => Right(
        announcement(
          status: AnnouncementStatus.scheduled,
          scheduledAt: later,
          version: 4,
        ),
      ),
    );
    final result = await writer.schedule(
      id: current.id,
      content: content,
      scheduledAt: later,
      current: current,
    );
    expect(result.getOrElse(() => throw 'x').version, 4);
  });

  test(
    'échec non modifié : renvoyé tel quel ; modifié : brouillon, PUT, envoi',
    () async {
      final failed = announcement(
        status: AnnouncementStatus.failed,
        title: 'T',
        body: 'B',
        version: 6,
      );
      when(() => repo.send(failed.id, version: 6)).thenAnswer(
        (_) async => Right(announcement(status: AnnouncementStatus.sent)),
      );
      await writer.send(id: failed.id, content: content, current: failed);
      verifyNever(() => repo.unschedule(any(), version: any(named: 'version')));

      const edited = AnnouncementContent(title: 'T2', body: 'B');
      when(() => repo.unschedule(failed.id, version: 6)).thenAnswer(
        (_) async => Right(announcement(title: 'T', body: 'B', version: 7)),
      );
      when(() => repo.update(failed.id, edited, version: 7)).thenAnswer(
        (_) async => Right(announcement(title: 'T2', body: 'B', version: 8)),
      );
      when(() => repo.send(failed.id, version: 8)).thenAnswer(
        (_) async => Right(announcement(status: AnnouncementStatus.sent)),
      );
      await writer.send(id: failed.id, content: edited, current: failed);
      verifyInOrder([
        () => repo.unschedule(failed.id, version: 6),
        () => repo.update(failed.id, edited, version: 7),
        () => repo.send(failed.id, version: 8),
      ]);
    },
  );

  test('un échec en route s\'arrête là', () async {
    final current = announcement(
      status: AnnouncementStatus.scheduled,
      scheduledAt: at,
      version: 2,
    );
    when(
      () => repo.unschedule(current.id, version: 2),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    final result = await writer.saveDraft(
      id: current.id,
      content: content,
      current: current,
    );
    expect(result, const Left<Failure, Never>(NetworkFailure()));
    verifyNever(
      () => repo.update(any(), any(), version: any(named: 'version')),
    );
  });
}
