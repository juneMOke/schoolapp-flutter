import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/pull_cycle_guard.dart';

/// Le garde de cycle **par ressource** (ADR-015 F6).
///
/// Il existe parce que ni « verrou global » ni « aucun verrou » ne convenaient :
/// le verrou global ferait qu'un écran monté pendant le cycle d'ouverture de
/// session resterait sur un cache froid, et l'absence de verrou laisserait deux
/// cycles keyset réécrire le même curseur en concurrence — les upserts sont
/// idempotents, les curseurs ne le sont pas.
///
/// Ce que ces tests figent, et qu'aucune signature ne dit : la sérialisation est
/// **par ressource**, elle **chaîne** au lieu de rejoindre (rejoindre mentirait
/// sur la fraîcheur : le cycle en vol a lu son curseur avant l'appel du nouvel
/// arrivant), et la chaîne est **bornée à deux**.
void main() {
  // ── Sérialisation ───────────────────────────────────────────────────────────

  // Chaîner, pas rejoindre : le second obtient son PROPRE cycle, qui démarre
  // après la fin du premier. Le rejoindre lui ferait annoncer une fraîcheur
  // qu'il n'a pas — le cycle en vol ne peut pas contenir ce qui a été écrit sur
  // un autre poste après son départ.
  test('deux cycles sur la MÊME ressource ne se chevauchent pas : le second '
      'démarre après la fin du premier', () async {
    final guard = PullCycleGuard();
    final porte = Completer<void>();
    final journal = <String>[];

    final premier = guard.run('finance_payments', () async {
      journal.add('debut-1');
      await porte.future;
      journal.add('fin-1');
    });
    final second = guard.run('finance_payments', () async {
      journal.add('debut-2');
    });

    // Le premier est tenu ouvert : rien du second ne doit avoir commencé.
    await pumpEventQueue();
    expect(journal, ['debut-1']);
    expect(identical(premier, second), isFalse);

    porte.complete();
    await Future.wait([premier, second]);

    expect(journal, ['debut-1', 'fin-1', 'debut-2']);
  });

  // Le garde est par ressource, jamais global : c'est toute la différence avec
  // le verrou `_pulling` du coordinateur. Sérialiser des ressources sans rapport
  // ferait attendre l'écran des classes derrière un cycle de paiements.
  test('deux cycles sur des ressources DIFFÉRENTES tournent en '
      'parallèle', () async {
    final guard = PullCycleGuard();
    final porte = Completer<void>();
    final journal = <String>[];

    final lent = guard.run('finance_payments', () async {
      journal.add('debut-paiements');
      await porte.future;
      journal.add('fin-paiements');
    });
    final rapide = guard.run('classrooms', () async {
      journal.add('debut-classes');
      journal.add('fin-classes');
    });

    // Les classes vont jusqu'au bout alors que les paiements sont encore en vol.
    await rapide;
    expect(journal, ['debut-paiements', 'debut-classes', 'fin-classes']);
    expect(guard.isBusy('finance_payments'), isTrue);
    expect(guard.isBusy('classrooms'), isFalse);

    porte.complete();
    await lent;
    expect(journal.last, 'fin-paiements');
  });

  // ── Coalescence ─────────────────────────────────────────────────────────────

  // La chaîne est bornée à DEUX : un qui tourne, un qui attend. Tant que le
  // cycle en attente n'est pas parti, il lira le curseur après tout le monde —
  // il satisfait donc tous les arrivants. Sans cette borne, dix écrans montés
  // ensemble produiraient dix cycles à la queue leu leu, dont neuf ne
  // rapporteraient qu'un 304 chacun.
  test('coalescence : trois appels concurrents sur la même ressource ⇒ le '
      'cycle ne s\'exécute que DEUX fois', () async {
    final guard = PullCycleGuard();
    final porte = Completer<void>();
    var cycles = 0;

    // Chaque cycle rend une valeur distincte : c'est ce qui prouve QUI a servi
    // qui. L'identité des futurs ne le prouverait plus — un appelant coalescé
    // reçoit désormais le RÉSULTAT du cycle en attente, transporté par un futur
    // qui lui est propre. Comparer les valeurs est d'ailleurs plus fort :
    // l'identité disait « même objet », la valeur dit « même cycle ».
    final premier = guard.run<String>('finance_payments', () async {
      cycles++;
      await porte.future;
      return 'cycle-1';
    });
    final deuxieme = guard.run<String>('finance_payments', () async {
      cycles++;
      return 'cycle-2';
    });
    final troisieme = guard.run<String>('finance_payments', () async {
      cycles++;
      return 'cycle-3';
    });

    porte.complete();
    final resultats = await Future.wait([premier, deuxieme, troisieme]);

    // Le troisième cycle n'a jamais tourné : le troisième appelant a reçu le
    // résultat du deuxième, qui n'avait pas encore démarré quand il est arrivé.
    expect(cycles, 2);
    expect(resultats, ['cycle-1', 'cycle-2', 'cycle-2']);
  });

  // La coalescence s'arrête au DÉPART du cycle en attente, pas à sa fin. Un
  // arrivant postérieur à ce départ doit obtenir son propre cycle : le cycle
  // parti a déjà lu son curseur, s'y coalescer le renverrait avec une fraîcheur
  // antérieure à son appel — exactement le mensonge que « chaîner » écarte.
  test('un arrivant postérieur au départ du cycle en attente obtient son '
      'propre cycle', () async {
    final guard = PullCycleGuard();
    final porteUn = Completer<void>();
    final porteDeux = Completer<void>();
    var cycles = 0;

    final premier = guard.run('classrooms', () async {
      cycles++;
      await porteUn.future;
    });
    final deuxieme = guard.run('classrooms', () async {
      cycles++;
      await porteDeux.future;
    });

    porteUn.complete();
    await pumpEventQueue();
    // Le deuxième est parti : plus personne ne doit s'y coalescer.
    expect(cycles, 2);

    final troisieme = guard.run('classrooms', () async {
      cycles++;
    });
    expect(identical(troisieme, deuxieme), isFalse);

    porteDeux.complete();
    await Future.wait([premier, deuxieme, troisieme]);

    expect(cycles, 3);
  });

  // ── Nettoyage ───────────────────────────────────────────────────────────────

  // Un cycle qui lève doit relâcher sa ressource. Sans le nettoyage en
  // `whenComplete`, une seule coupure réseau gèlerait ce flux jusqu'au
  // redémarrage de l'application — et rien ne le dirait.
  test('un cycle qui LÈVE ne bloque pas la ressource pour toujours', () async {
    final guard = PullCycleGuard();

    await expectLater(
      guard.run('classrooms', () async {
        throw StateError('réseau coupé');
      }),
      throwsStateError,
    );
    expect(guard.isBusy('classrooms'), isFalse);

    var reparti = false;
    await guard.run('classrooms', () async {
      reparti = true;
    });

    expect(reparti, isTrue);
  });

  test('isBusy : vrai pendant le cycle, faux après', () async {
    final guard = PullCycleGuard();
    final porte = Completer<void>();

    expect(guard.isBusy('attendance'), isFalse);

    final cycle = guard.run('attendance', () async {
      await porte.future;
    });

    expect(guard.isBusy('attendance'), isTrue);

    porte.complete();
    await cycle;

    expect(guard.isBusy('attendance'), isFalse);
  });

  test('isBusy : vrai aussi tant qu\'un cycle attend son tour', () async {
    final guard = PullCycleGuard();
    final porte = Completer<void>();

    final premier = guard.run('attendance', () async {
      await porte.future;
    });
    final second = guard.run('attendance', () async {});

    expect(guard.isBusy('attendance'), isTrue);

    porte.complete();
    await Future.wait([premier, second]);

    expect(guard.isBusy('attendance'), isFalse);
  });

  // B-1 — deux voies, parce que deux attentes. Le coordinateur veut SON issue
  // (`PullOutcome`) ; un écran qui tire hors coordinateur veut seulement que la
  // ressource soit à jour. Mélangés dans une seule voie générique, le second
  // servait son `void` au premier : `null as PullOutcome` lève, le `catch` du
  // coordinateur compte un échec, et le handler ne tourne jamais.
  group('deux voies : issue partagée d\'un côté, ignorée de l\'autre', () {
    test(
      'un cycle SANS issue ne se fait pas passer pour un cycle typé',
      () async {
        final guard = PullCycleGuard();
        final premier = Completer<void>();
        var typedRuns = 0;

        // 1. un cycle qui tourne (il tient la ressource) ;
        final enVol = guard.runIgnoringResult(
          'enrollments',
          () => premier.future,
        );
        // 2. un second SANS issue, donc programmé derrière — c'est lui qui,
        //    avant le correctif, s'offrait à la coalescence.
        final enAttente = guard.runIgnoringResult('enrollments', () async {});
        // 3. le coordinateur arrive et réclame son issue.
        final typed = guard.run<String>('enrollments', () async {
          typedRuns++;
          return 'issue-a-moi';
        });

        premier.complete();
        await enVol;
        await enAttente;

        expect(
          await typed,
          'issue-a-moi',
          reason:
              'un cycle sans issue ne peut pas satisfaire qui en attend une',
        );
        expect(typedRuns, 1, reason: 'il a donc tourné pour de bon');
      },
    );

    test(
      'CONTRE-ÉPREUVE : entre appelants typés, la coalescence tient',
      () async {
        // C'est le cas NORMAL — un écran qui se monte pendant un cycle complet —
        // et le correctif ne doit pas le supprimer : ce serait un aller-retour
        // réseau de plus par écran.
        final guard = PullCycleGuard();
        final premier = Completer<String>();
        var seconds = 0;

        final enVol = guard.run<String>('enrollments', () => premier.future);
        final enAttente = guard.run<String>('enrollments', () async {
          seconds++;
          return 'issue-partagee';
        });
        final arrivant = guard.run<String>('enrollments', () async {
          seconds++;
          return 'jamais';
        });

        premier.complete('premier');
        expect(await enVol, 'premier');
        expect(await enAttente, 'issue-partagee');
        expect(await arrivant, 'issue-partagee');
        expect(seconds, 1, reason: 'un seul cycle pour les deux arrivants');
      },
    );

    test('un appelant sans issue se coalesce sur un cycle typé', () async {
      // L'inverse est sûr : il ignore la valeur, il ne la transtype pas.
      final guard = PullCycleGuard();
      final premier = Completer<String>();
      var seconds = 0;

      final enVol = guard.run<String>('enrollments', () => premier.future);
      final enAttente = guard.run<String>('enrollments', () async {
        seconds++;
        return 'issue';
      });
      final sansIssue = guard.runIgnoringResult('enrollments', () async {
        seconds++;
      });

      premier.complete('premier');
      await enVol;
      await enAttente;
      await sansIssue;

      expect(seconds, 1, reason: 'aucun cycle superflu, aucun transtypage');
    });

    test('la sérialisation vaut ENTRE les deux voies', () async {
      // Ce qui ne doit surtout pas changer : deux cycles keyset concurrents
      // font régresser le curseur, quelle que soit la voie par laquelle ils
      // sont entrés.
      final guard = PullCycleGuard();
      final premier = Completer<void>();
      final ordre = <String>[];

      final sansIssue = guard.runIgnoringResult('enrollments', () async {
        await premier.future;
        ordre.add('sans-issue');
      });
      final typed = guard.run<int>('enrollments', () async {
        ordre.add('typé');
        return 1;
      });

      premier.complete();
      await sansIssue;
      await typed;

      expect(ordre, ['sans-issue', 'typé']);
    });
  });
}
