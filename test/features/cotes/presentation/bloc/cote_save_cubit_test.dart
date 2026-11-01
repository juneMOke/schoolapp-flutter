import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';

import 'fake_cotes_repository.dart';

void main() {
  late FakeCotesRepository repository;
  late int flushed;

  setUp(() {
    repository = FakeCotesRepository();
    flushed = 0;
  });

  CoteSaveCubit build() =>
      CoteSaveCubit(repository, onFlushed: () => flushed++, now: () => 42);

  test(
    'trois frappes en 500 ms : un envoi, 700 ms après la dernière',
    () async {
      final cubit = build();
      await cubit.attach('c1');
      const beat = Duration(milliseconds: 200);

      for (var i = 0; i < 3; i++) {
        cubit.noteChanged();
        await Future<void>.delayed(beat);
      }
      expect(repository.flushes, 0);
      expect(cubit.state, isA<CoteSaving>());

      await Future<void>.delayed(AppMotion.autosaveDebounce);

      expect(repository.flushes, 1);
      expect(cubit.state, const CoteSaved(42));
      await cubit.close();
    },
  );

  test('hors ligne : le nombre de cotes en attente', () async {
    final cubit = build();
    await cubit.attach('c1');
    repository
      ..flushOutcome = CoteFlushOutcome.offline
      ..pending = 3;

    cubit.noteChanged();
    await cubit.flushNow();

    expect(cubit.state, const CoteSaveOffline(3));
    await cubit.close();
  });

  test('bloqué : échec, et réessayer remet en tête de file', () async {
    final cubit = build();
    await cubit.attach('c1');
    repository.flushOutcome = CoteFlushOutcome.stuck;

    cubit.noteChanged();
    await cubit.flushNow();
    expect(cubit.state, const CoteSaveFailed());

    repository.flushOutcome = CoteFlushOutcome.done;
    await cubit.retry();

    expect(repository.retries, 1);
    expect(cubit.state, const CoteSaved(42));
    await cubit.close();
  });

  test('session expirée : à part d\'une panne', () async {
    final cubit = build();
    await cubit.attach('c1');
    repository.flushOutcome = CoteFlushOutcome.sessionExpired;

    cubit.noteChanged();
    await cubit.flushNow();

    expect(cubit.state, const CoteSaveFailed(sessionExpired: true));
    await cubit.close();
  });

  test('rouvrir une classe renvoie son reliquat', () async {
    repository.pending = 2;
    final cubit = build();
    repository.flushOutcome = CoteFlushOutcome.offline;

    await cubit.attach('c1');

    expect(repository.flushes, 1);
    expect(cubit.state, const CoteSaveOffline(2));
    await cubit.close();
  });

  test('sans reliquat, rien ne part à l\'ouverture', () async {
    final cubit = build();

    await cubit.attach('c1');

    expect(repository.flushes, 0);
    expect(cubit.state, const CoteSaveIdle());
    await cubit.close();
  });

  test('la file vidée par le réseau revenu passe à enregistré', () async {
    final cubit = build();
    await cubit.attach('c1');
    repository
      ..flushOutcome = CoteFlushOutcome.offline
      ..pending = 3;
    cubit.noteChanged();
    await cubit.flushNow();

    repository.pending = 0;
    repository.endFlush();
    await pumpEventQueue();

    expect(flushed, 1);
    expect(cubit.state, const CoteSaved(42));
    await cubit.close();
  });

  test('moteur occupé : l\'envoi est relancé à la fin du vidage', () async {
    final cubit = build();
    await cubit.attach('c1');
    repository.flushOutcome = CoteFlushOutcome.busy;
    cubit.noteChanged();
    await cubit.flushNow();
    expect(cubit.state, isA<CoteSaving>());
    expect(repository.flushes, 1);

    repository
      ..flushOutcome = CoteFlushOutcome.done
      ..pending = 0;
    repository.endFlush();
    await pumpEventQueue();

    expect(repository.flushes, 2);
    expect(cubit.state, const CoteSaved(42));
    await cubit.close();
  });

  test('une frappe après fermeture ne lève pas', () async {
    final cubit = build();
    await cubit.attach('c1');
    await cubit.close();

    expect(cubit.noteChanged, returnsNormally);
  });

  test('fermer vide ce qui attendait le silence', () async {
    final cubit = build();
    await cubit.attach('c1');
    cubit.noteChanged();

    await cubit.close();
    await pumpEventQueue();

    expect(repository.flushes, 1);
  });

  test('fermer se désabonne', () async {
    final cubit = build();
    await cubit.close();

    expect(repository.listeners, isEmpty);
  });
}
