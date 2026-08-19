import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_heartbeat.dart';

void main() {
  group('SyncHeartbeat — armement', () {
    test('armé seulement quand session ouverte ET premier plan', () {
      final beat = SyncHeartbeat(
        interval: const Duration(seconds: 45),
        onTick: () async {},
      );
      expect(beat.isActive, isFalse);

      beat.sessionOpened();
      expect(beat.isActive, isTrue);

      beat.leaveForeground();
      expect(beat.isActive, isFalse);

      beat.enterForeground();
      expect(beat.isActive, isTrue);

      beat.sessionClosed();
      expect(beat.isActive, isFalse);

      // Revenir au premier plan sans session ne rallume rien.
      beat.enterForeground();
      expect(beat.isActive, isFalse);

      beat.dispose();
    });

    test('démarré en arrière-plan, il ne s\'arme pas à l\'ouverture', () {
      // Le cas d'une application lancée hors écran : le défaut « premier plan »
      // serait un mensonge que rien ne viendrait corriger, le binding ne
      // notifiant que des transitions.
      final beat = SyncHeartbeat(
        interval: const Duration(seconds: 45),
        onTick: () async {},
        foreground: false,
      );

      beat.sessionOpened();

      expect(beat.isActive, isFalse);
      beat.dispose();
    });

    test('dispose() désarme définitivement', () {
      final beat = SyncHeartbeat(
        interval: const Duration(seconds: 45),
        onTick: () async {},
      )..sessionOpened();

      beat.dispose();
      expect(beat.isActive, isFalse);

      // Un signal qui arrive après ne le ressuscite pas.
      beat.enterForeground();
      beat.sessionOpened();
      expect(beat.isActive, isFalse);
    });
  });

  group('SyncHeartbeat — cadence', () {
    test('le timer appelle réellement le tic', () async {
      var ticks = 0;
      final beat = SyncHeartbeat(
        interval: const Duration(milliseconds: 20),
        onTick: () async => ticks++,
      )..sessionOpened();

      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(ticks, greaterThan(1));
      beat.dispose();
    });

    test(
      'un signal répété est inerte — ni famine, ni timers en double',
      () async {
        // Deux pannes opposées, un seul garde-fou. Recréer le timer à chaque
        // signal remettrait son compte à rebours à zéro : un signal plus fréquent
        // que la période et le tic ne partirait JAMAIS, drapeau d'armement au
        // vert. Ne PAS annuler l'ancien en le remplaçant les accumulerait : le
        // tic partirait autant de fois qu'il y a eu de signaux.
        //
        // D'où les deux bornes : la basse attrape la famine, la haute la fuite.
        var ticks = 0;
        final beat = SyncHeartbeat(
          interval: const Duration(milliseconds: 40),
          onTick: () async => ticks++,
        )..sessionOpened();

        for (var i = 0; i < 32; i++) {
          beat.enterForeground(); // déjà au premier plan : doit être inerte
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        // ~320 ms à 40 ms de période ≈ 8 tics ; large marge pour la gigue de
        // l'horloge réelle, mais sans commune mesure avec les centaines
        // qu'apporteraient trente-deux timers empilés.
        expect(ticks, inInclusiveRange(3, 14));
        beat.dispose();
      },
    );

    test('arrêté, le timer ne tire plus', () async {
      var ticks = 0;
      final beat = SyncHeartbeat(
        interval: const Duration(milliseconds: 20),
        onTick: () async => ticks++,
      )..sessionOpened();
      beat.leaveForeground();

      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(ticks, 0);
      beat.dispose();
    });
  });

  group('SyncHeartbeat — robustesse du tic', () {
    test('deux tics ne se superposent pas', () async {
      // Un cycle complet sur la connexion d'une école dépasse couramment la
      // période : sans verrou, deux tics flusheraient la même file.
      final gate = Completer<void>();
      var entered = 0;
      final beat = SyncHeartbeat(
        interval: const Duration(seconds: 45),
        onTick: () async {
          entered++;
          await gate.future;
        },
      );

      unawaited(beat.tick());
      await pumpEventQueue();
      expect(beat.isTicking, isTrue);

      await beat.tick(); // rendu immédiatement
      expect(entered, 1);

      gate.complete();
      await pumpEventQueue();
      expect(beat.isTicking, isFalse);

      // Le verrou se relâche : le tic suivant passe.
      await beat.tick();
      expect(entered, 2);

      beat.dispose();
    });

    test(
      'un tic qui lève ne remonte rien et ne bloque pas le suivant',
      () async {
        // Personne n'attrape ce qu'un `Timer` laisse échapper.
        var calls = 0;
        final beat = SyncHeartbeat(
          interval: const Duration(seconds: 45),
          onTick: () async {
            calls++;
            throw StateError('base fermée');
          },
        );

        await expectLater(beat.tick(), completes);
        expect(beat.isTicking, isFalse);

        await beat.tick();
        expect(calls, 2);

        beat.dispose();
      },
    );

    test('après dispose(), le tic ne part plus', () async {
      var calls = 0;
      final beat = SyncHeartbeat(
        interval: const Duration(seconds: 45),
        onTick: () async => calls++,
      )..dispose();

      await beat.tick();

      expect(calls, 0);
    });
  });
}
