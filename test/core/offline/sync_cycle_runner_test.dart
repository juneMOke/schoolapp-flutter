import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/core/offline/session_reauthenticator.dart';
import 'package:school_app_flutter/core/offline/sync_cycle_runner.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockPullCoordinator extends Mock implements PullCoordinator {}

class _MockProbe extends Mock implements SessionCredentialsProbe {}

class _MockReauthenticator extends Mock implements SessionReauthenticator {}

class _Connectivity implements ConnectivityService {
  _Connectivity(this.online);
  bool online;

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Le corps de cycle sorti de `SyncStatusCubit` (B-8). Les 77 tests du cubit
/// l'exercent déjà de bout en bout ; ce qui est épinglé ici est la **frontière
/// neuve** : ce qu'un cycle rend à celui qui projette.
///
/// ⚠️ L'invariant central : les drapeaux nuls disent « rien observé », jamais
/// « sain ». Un cycle arrêté sur une garde, un rapport `skipped` ou `offline`
/// n'ont rien vu — les traduire en « tout va bien » effacerait une dégradation
/// bien réelle, c'est-à-dire exactement ce que ces drapeaux existent à porter.
void main() {
  late _MockSyncEngine engine;
  late _MockPullCoordinator coordinator;
  late _Connectivity connectivity;
  late int nowMs;
  late int announces;

  setUp(() {
    nowMs = 1000000;
    announces = 0;
    engine = _MockSyncEngine();
    when(() => engine.flush()).thenAnswer((_) async => const SyncFlushReport());
    coordinator = _MockPullCoordinator();
    connectivity = _Connectivity(true);
  });

  SyncCycleRunner runner({
    SessionCredentialsProbe? probe,
    SessionReauthenticator? reauth,
    PullCoordinator? pull,
  }) => SyncCycleRunner(
    syncEngine: engine,
    connectivity: connectivity,
    pullCoordinator: pull ?? coordinator,
    credentialsProbe: probe,
    reauthenticator: reauth,
    now: () => nowMs,
  );

  Future<SyncCycleOutcome> fullCycle(SyncCycleRunner r) => r.runFullCycle(
    evaluateRevocation: false,
    onSyncingStarted: () => announces++,
  );

  group('gardes de tête', () {
    test('sans jetons utilisables : ni flush, ni pull, ni annonce', () async {
      // Flusher quand même, c'est un 401 sur CHAQUE entrée et `attempts++`
      // jusqu'au poison terminal, sans qu'une seule écriture ne soit partie.
      final probe = _MockProbe();
      when(() => probe.canAuthenticate()).thenAnswer((_) async => false);

      final outcome = await fullCycle(runner(probe: probe));

      expect(outcome.pullDegraded, isNull);
      expect(announces, 0);
      verifyNever(() => engine.flush());
      verifyNever(() => coordinator.pullAll());
    });

    test(
      'mint impossible : rien n\'est tenté, la file reste intacte',
      () async {
        final reauth = _MockReauthenticator();
        when(() => reauth.ensureFreshAccess()).thenAnswer((_) async => false);

        await fullCycle(runner(reauth: reauth));

        expect(announces, 0);
        verifyNever(() => engine.flush());
      },
    );

    test(
      'une sonde qui LÈVE laisse passer plutôt que de geler la synchro',
      () async {
        final probe = _MockProbe();
        when(() => probe.canAuthenticate()).thenThrow(StateError('storage HS'));
        when(
          () => coordinator.pullAll(),
        ).thenAnswer((_) async => const PullRunReport(updated: 1));

        await fullCycle(runner(probe: probe));

        verify(() => engine.flush()).called(1);
      },
    );
  });

  group('ce qu\'un cycle rend à la projection', () {
    test('rapport exploitable : drapeaux rendus, cache rajeuni', () async {
      when(() => coordinator.pullAll()).thenAnswer(
        (_) async =>
            const PullRunReport(updated: 3, failed: 2, latestServerTimeMs: 777),
      );
      final r = runner();

      final outcome = await fullCycle(r);

      expect(outcome.pullDegraded, isTrue);
      expect(outcome.pullRetriable, isTrue, reason: 'un échec se réessaie');
      expect(outcome.latestServerTimeMs, 777);
      expect(
        r.isFullCycleDue(),
        isFalse,
        reason: 'le cache vient d\'être tiré',
      );
    });

    test(
      'rapport SAUTÉ : rien à projeter, et le cache ne rajeunit pas',
      () async {
        // Le piège que cette frontière existe à fermer : un cycle déjà en vol
        // n'a rien observé. Rendre `false` effacerait la dégradation du cycle
        // précédent, et rajeunir le cache figerait le référentiel un quart
        // d'heure de plus.
        when(
          () => coordinator.pullAll(),
        ).thenAnswer((_) async => const PullRunReport.skipped());
        final r = runner();

        final outcome = await fullCycle(r);

        expect(outcome.pullDegraded, isNull);
        expect(outcome.pullRetriable, isNull);

        // Passé le plancher de reprise, un cycle est de nouveau dû : le cache
        // n'a jamais été rajeuni. La contre-épreuve est juste en dessous —
        // après un rapport exploitable, ce même délai ne suffit pas.
        nowMs += SyncCycleRunner.kFailedCycleRetryMs;
        expect(r.isFullCycleDue(), isTrue);
      },
    );

    test(
      'CONTRE-ÉPREUVE : un rapport exploitable tient le quart d\'heure',
      () async {
        when(
          () => coordinator.pullAll(),
        ).thenAnswer((_) async => const PullRunReport(updated: 1));
        final r = runner();
        await fullCycle(r);

        nowMs += SyncCycleRunner.kFailedCycleRetryMs;

        expect(
          r.isFullCycleDue(),
          isFalse,
          reason: 'le plancher de reprise ne vise que les cycles stériles',
        );
      },
    );

    test('aucun coordinateur : rien à tirer, donc rien qui vieillit', () async {
      final r = runner(pull: null);

      final outcome = await fullCycle(r);

      expect(outcome.pullDegraded, isNull);
      expect(r.isFullCycleDue(), isFalse);
    });
  });

  group('push seul', () {
    test(
      'hors ligne : aucun flush — le mint imposerait un timeout par écriture',
      () async {
        connectivity.online = false;

        await runner().runPushOnly(onSyncingStarted: () => announces++);

        expect(announces, 0);
        verifyNever(() => engine.flush());
      },
    );

    test(
      'sans annonce demandée, le flush part quand même en silence',
      () async {
        await runner().runPushOnly();

        expect(announces, 0);
        verify(() => engine.flush()).called(1);
      },
    );
  });

  group('estampilles', () {
    test(
      'la tentative est datée AVANT les gardes, pas après le succès',
      () async {
        // Un cycle arrêté par un mint impossible est exactement celui qu'une
        // reprise d'application ne doit pas relancer en rafale.
        final reauth = _MockReauthenticator();
        when(() => reauth.ensureFreshAccess()).thenAnswer((_) async => false);
        final r = runner(reauth: reauth);

        await fullCycle(r);

        expect(r.lastCycleAttemptAtMs, nowMs);
      },
    );

    test('horloge qui recule : « on ne sait pas », donc on tire', () async {
      when(
        () => coordinator.pullAll(),
      ).thenAnswer((_) async => const PullRunReport(updated: 1));
      final r = runner();
      await fullCycle(r);
      expect(r.isFullCycleDue(), isFalse);

      // NTP qui corrige une dérive de RTC : l'estampille passe dans le futur.
      nowMs -= 60000;

      expect(
        r.isFullCycleDue(),
        isTrue,
        reason: 'un écart négatif ne doit pas figer le déclencheur à jamais',
      );
    });
  });
}
