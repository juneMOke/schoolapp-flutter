import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_audience_repository.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_student_search_cubit.dart';

import '../../communication_fixtures.dart';

class _MockRepository extends Mock implements AnnouncementAudienceRepository {}

/// Laisse partir le minuteur (nul) et les réponses en attente.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockRepository repo;

  setUpAll(() => registerFallbackValue(const SchoolAudience()));
  setUp(() => repo = _MockRepository());

  AnnouncementReachCubit cubit() =>
      AnnouncementReachCubit(repo, debounce: Duration.zero);

  test('une sélection vide ne part pas : « choisissez »', () {
    final c = cubit()..update(const ClassroomsAudience([]));
    expect(c.state.status, ReachStatus.invalid);
    verifyZeroInteractions(repo);
  });

  test(
    'des coches rapprochées ne font qu\'un appel, sur la dernière',
    () async {
      when(() => repo.reach(any())).thenAnswer((_) async => const Right(reach));
      final c = cubit()
        ..update(const LevelsAudience(['a']))
        ..update(const LevelsAudience(['a', 'b']));
      expect(c.state.status, ReachStatus.loading);
      await _settle();
      await _settle();
      verify(() => repo.reach(const LevelsAudience(['a', 'b']))).called(1);
      verifyNoMoreInteractions(repo);
      expect(c.state.status, ReachStatus.ready);
      expect(c.state.whatsappDisabled, isFalse);
    },
  );

  test(
    'une réponse dépassée par un changement plus récent est jetée',
    () async {
      final slow = Completer<Either<Failure, AnnouncementReach>>();
      when(
        () => repo.reach(const LevelsAudience(['a'])),
      ).thenAnswer((_) => slow.future);
      final c = cubit()..update(const LevelsAudience(['a']));
      await _settle();
      c.update(const ClassroomsAudience([]));
      slow.complete(const Right(reach));
      await _settle();
      expect(c.state.status, ReachStatus.invalid);
    },
  );

  test('WhatsApp non activé : dit par la portée', () async {
    when(() => repo.reach(any())).thenAnswer(
      (_) async => const Right(
        AnnouncementReach(
          students: 1,
          guardians: 1,
          messages: 1,
          reachableMessages: 1,
          guardiansWithoutPhone: 0,
          studentsUnreachable: 0,
          whatsappEnabled: false,
        ),
      ),
    );
    final c = cubit()..update(const SchoolAudience());
    await _settle();
    await _settle();
    expect(c.state.whatsappDisabled, isTrue);
  });

  test('recherche : moins de deux lettres, aucun appel', () async {
    final c = AudienceStudentSearchCubit(repo, debounce: Duration.zero)
      ..search('k');
    await _settle();
    expect(c.state.tooShort, isTrue);
    verifyZeroInteractions(repo);
  });

  test('une lecture en vol ne s\'impose pas à la nouvelle audience', () async {
    final slowA = Completer<Either<Failure, AnnouncementReach>>();
    when(
      () => repo.reach(const LevelsAudience(['a'])),
    ).thenAnswer((_) => slowA.future);
    when(
      () => repo.reach(const LevelsAudience(['b'])),
    ).thenAnswer((_) async => const Right(reach));
    final c = cubit()..update(const LevelsAudience(['a']));
    await _settle();
    c.update(const LevelsAudience(['b']));
    slowA.complete(const Right(reach));
    await _settle();
    await _settle();
    expect(c.state.audience, const LevelsAudience(['b']));
    expect(c.state.settledFor(const LevelsAudience(['b'])), reach);
    expect(c.state.settledFor(const LevelsAudience(['a'])), isNull);
  });
}
