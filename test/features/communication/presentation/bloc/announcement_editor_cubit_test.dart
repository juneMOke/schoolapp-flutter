import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_refusal.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';
import 'package:school_app_flutter/features/communication/domain/usecases/announcement_writer.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';

import '../../communication_fixtures.dart';

class _MockRepository extends Mock implements AnnouncementRepository {}

ApiValidationFailure _refused(String code, {List<String>? fields}) =>
    ApiValidationFailure(
      code: ApiErrorCode.unknown,
      detailCode: code,
      details: fields == null ? null : {'fields': fields},
    );

void main() {
  late _MockRepository repo;
  final now = DateTime.utc(2026, 10, 12, 9);

  setUpAll(() => registerFallbackValue(const AnnouncementContent()));
  setUp(() => repo = _MockRepository());

  AnnouncementEditorCubit fresh() => AnnouncementEditorCubit.create(
    id: 'uuid',
    writer: AnnouncementWriter(repo),
    academicYearId: 'y-1',
    now: () => now,
  );

  void createAnswers(Announcement Function() a) => when(
    () => repo.create(
      id: any(named: 'id'),
      content: any(named: 'content'),
      academicYearId: any(named: 'academicYearId'),
    ),
  ).thenAnswer((_) async => Right(a()));

  test('programmé par défaut le lendemain, 07:30 à Kinshasa', () {
    expect(fresh().state.scheduledAt, DateTime.utc(2026, 10, 13, 6, 30));
  });

  test(
    'brouillon vide : refusé sans appel, les manques s\'affichent',
    () async {
      final cubit = fresh();
      await cubit.saveDraft();
      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.hasIssueOn(AnnouncementField.title), isTrue);
      verifyZeroInteractions(repo);
    },
  );

  test('envoyer sans titre : rien ne part', () async {
    final cubit = fresh()..setBody('B');
    await cubit.submit();
    expect(cubit.state.hasIssueOn(AnnouncementField.title), isTrue);
    expect(cubit.state.hasIssueOn(AnnouncementField.body), isFalse);
    verifyZeroInteractions(repo);
  });

  test('programmer dans le passé : refusé sous le champ', () async {
    final cubit = fresh()
      ..setTitle('T')
      ..setBody('B')
      ..setSendMode(AnnouncementSendMode.scheduled)
      ..setScheduledAt(now.subtract(const Duration(minutes: 5)));
    expect(cubit.validateForSubmit(), isFalse);
    expect(cubit.state.hasIssueOn(AnnouncementField.scheduledAt), isTrue);
  });

  test(
    'brouillon enregistré : l\'issue le dit, la copie serveur est gardée',
    () async {
      createAnswers(() => announcement(id: 'uuid', title: 'T', version: 1));
      final cubit = fresh()..setTitle('T');
      await cubit.saveDraft();
      expect(cubit.state.outcome, AnnouncementEditorOutcome.draftSaved);
      expect(cubit.state.announcement?.version, 1);
      verify(
        () => repo.create(
          id: 'uuid',
          content: const AnnouncementContent(title: 'T'),
          academicYearId: 'y-1',
        ),
      ).called(1);
    },
  );

  test('refus INCOMPLETE : sous les champs nommés, pas de bandeau', () async {
    createAnswers(() => announcement(id: 'uuid', title: 'T', body: 'B'));
    when(() => repo.send('uuid', version: any(named: 'version'))).thenAnswer(
      (_) async => Left(
        _refused('ANNOUNCEMENT_INCOMPLETE', fields: ['audience', 'channels']),
      ),
    );
    final cubit = fresh()
      ..setTitle('T')
      ..setBody('B');
    await cubit.submit();
    expect(cubit.state.serverFields, {
      AnnouncementField.audience,
      AnnouncementField.channels,
    });
    expect(cubit.state.failure, isNull);
    // Une frappe efface le verdict du serveur.
    cubit.setBody('B2');
    expect(cubit.state.serverFields, isEmpty);
  });

  test('WhatsApp désactivé : bandeau, et Réessayer rejoue l\'envoi', () async {
    createAnswers(() => announcement(id: 'uuid', title: 'T', body: 'B'));
    when(
      () => repo.send('uuid', version: any(named: 'version')),
    ).thenAnswer((_) async => Left(_refused('ANNOUNCEMENT_CHANNEL_DISABLED')));
    final cubit = fresh()
      ..setTitle('T')
      ..setBody('B');
    await cubit.submit();
    expect(cubit.state.refusal, AnnouncementRefusal.channelDisabled);
    expect(cubit.state.failedGesture, AnnouncementEditorBusy.sending);
    await cubit.retry();
    // Le brouillon créé au premier essai n'est pas recréé.
    verify(
      () => repo.create(
        id: any(named: 'id'),
        content: any(named: 'content'),
        academicYearId: any(named: 'academicYearId'),
      ),
    ).called(1);
    verify(() => repo.send('uuid', version: any(named: 'version'))).called(2);
  });

  test('version périmée : relu, saisie gardée, avis affiché', () async {
    final current = announcement(id: 'a', version: 2);
    when(
      () => repo.update('a', any(), version: 2),
    ).thenAnswer((_) async => Left(_refused('ANNOUNCEMENT_STALE')));
    when(
      () => repo.get('a'),
    ).thenAnswer((_) async => Right(announcement(id: 'a', version: 3)));
    final cubit = AnnouncementEditorCubit.edit(
      announcement: current,
      writer: AnnouncementWriter(repo),
      now: () => now,
    )..setTitle('Ma saisie');
    await cubit.saveDraft();
    expect(cubit.state.notice, AnnouncementEditorNotice.reloaded);
    expect(cubit.state.announcement?.version, 3);
    expect(cubit.state.content.title, 'Ma saisie');
    expect(cubit.state.isLocked, isFalse);
  });

  test('parti entre-temps : verrouillé', () async {
    final current = announcement(
      id: 'a',
      status: AnnouncementStatus.scheduled,
      scheduledAt: now.add(const Duration(hours: 1)),
    );
    when(
      () => repo.update('a', any(), version: any(named: 'version')),
    ).thenAnswer((_) async => Left(_refused('ANNOUNCEMENT_NOT_EDITABLE')));
    when(() => repo.get('a')).thenAnswer(
      (_) async =>
          Right(announcement(id: 'a', status: AnnouncementStatus.sent)),
    );
    final cubit = AnnouncementEditorCubit.edit(
      announcement: current,
      writer: AnnouncementWriter(repo),
      now: () => now,
    )..setTitle('X');
    await cubit.submit();
    expect(cubit.state.isLocked, isTrue);
    await cubit.saveDraft();
    verify(
      () => repo.update('a', any(), version: any(named: 'version')),
    ).called(1);
  });

  test('un programmé rouvert garde son heure et son mode', () {
    final at = now.add(const Duration(days: 2));
    final cubit = AnnouncementEditorCubit.edit(
      announcement: announcement(
        status: AnnouncementStatus.scheduled,
        scheduledAt: at,
        audience: const LevelsAudience(['l-1']),
      ),
      writer: AnnouncementWriter(repo),
      now: () => now,
    );
    expect(cubit.state.sendMode, AnnouncementSendMode.scheduled);
    expect(cubit.state.scheduledAt, at);
  });
}
