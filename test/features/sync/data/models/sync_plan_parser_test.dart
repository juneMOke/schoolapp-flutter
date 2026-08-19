import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
import 'package:school_app_flutter/features/sync/data/models/sync_plan_parser.dart';

/// Analyse POSITIVE d'un corps de réponse en plan (ADR-015 F2).
///
/// Le lot tient sur une phrase : **un corps qui n'a pas les quatre champs
/// requis n'est pas un plan, quel que soit son code HTTP**. Sans ça, un portail
/// captif qui répond 200 en HTML se lirait comme un plan valide.
void main() {
  /// Corps nominal, modifiable champ par champ pour chaque cas de rejet.
  Map<String, Object?> body({
    Object? planVersion = 1,
    Object? subject = 'uid-a',
    Object? onAbsence = 'ignore',
    Object? streams = const <Object?>[
      {
        'key': 'socle',
        'clientResource': ['ref_school', 'ref_academic_years'],
        'mode': 'BUNDLE',
        'scope': 'school',
        'reason': ['socle'],
        'dependsOn': <String>[],
      },
      {
        'key': 'finance.payments',
        'clientResource': ['finance_payments'],
        'mode': 'KEYSET',
        'scope': 'school',
        'reason': ['granted:finance.read'],
        'dependsOn': ['socle'],
      },
      {
        'key': 'schedule.sessions',
        'clientResource': ['schedule_sessions'],
        'mode': 'COHORT',
        'scope': 'principal',
        'reason': ['granted:schedule.read'],
        'dependsOn': ['socle'],
      },
    ],
  }) => <String, Object?>{
    'planVersion': planVersion,
    'subject': subject,
    'onAbsence': onAbsence,
    'streams': streams,
  };

  group('plan bien formé', () {
    test('un plan complet est analysé, champs et ORDRE des flux préservés', () {
      final result = parseSyncPlan(body());

      final plan = result.plan;
      expect(
        plan,
        isNotNull,
        reason: 'un corps conforme doit produire un plan',
      );
      expect(result.isMalformed, isFalse);
      expect(result.rejectedKeys, isEmpty);
      expect(result.allStreamsDropped, isFalse);

      expect(plan!.planVersion, 1);
      expect(plan.subject, 'uid-a');
      expect(plan.onAbsence, 'ignore');

      // L'ordre est porteur : le serveur trie topologiquement, un client naïf
      // itère et a raison. Le réordonner casserait `dependsOn`.
      expect(plan.keys, ['socle', 'finance.payments', 'schedule.sessions']);

      final socle = plan.streams.first;
      expect(socle.mode, SyncFlowMode.bundle);
      expect(socle.scope, SyncFlowScope.school);
      expect(socle.clientResource, ['ref_school', 'ref_academic_years']);
      expect(socle.reason, ['socle']);
      expect(socle.dependsOn, isEmpty);

      final paiements = plan.streams[1];
      expect(paiements.mode, SyncFlowMode.keyset);
      expect(paiements.dependsOn, ['socle']);

      final seances = plan.streams[2];
      expect(seances.mode, SyncFlowMode.cohort);
      expect(seances.scope, SyncFlowScope.principal);
    });

    test('les quatre modes du contrat sont tous reconnus', () {
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {'key': 'a', 'mode': 'BUNDLE', 'scope': 'school'},
            {'key': 'b', 'mode': 'KEYSET', 'scope': 'school'},
            {'key': 'c', 'mode': 'COHORT', 'scope': 'principal'},
            {'key': 'd', 'mode': 'FANOUT', 'scope': 'principal'},
          ],
        ),
      );

      expect(result.rejectedKeys, isEmpty);
      expect(result.plan!.streams.map((f) => f.mode), [
        SyncFlowMode.bundle,
        SyncFlowMode.keyset,
        SyncFlowMode.cohort,
        SyncFlowMode.fanout,
      ]);
      expect(result.plan!.streams.map((f) => f.scope), [
        SyncFlowScope.school,
        SyncFlowScope.school,
        SyncFlowScope.principal,
        SyncFlowScope.principal,
      ]);
    });
  });

  group('validation positive — ce qui n\'est pas un plan', () {
    test(
      'LE CAS CENTRAL : un corps HTML de portail captif n\'est pas un plan',
      () {
        // 200 OK, mais du HTML. Sans validation positive, ce corps se lirait
        // comme un plan — et sous F5 il gouvernerait la synchronisation.
        const html =
            '<!DOCTYPE html><html><head><title>Connexion Wi-Fi</title></head>'
            '<body><form action="/login">Authentifiez-vous</form></body></html>';

        final result = parseSyncPlan(html);

        expect(result.isMalformed, isTrue);
        expect(result.plan, isNull);
        expect(result.rejectedKeys, isEmpty);
      },
    );

    test('un corps null n\'est pas un plan', () {
      expect(parseSyncPlan(null).isMalformed, isTrue);
    });

    test('un corps qui est une List n\'est pas un plan', () {
      expect(parseSyncPlan(const <Object?>[]).isMalformed, isTrue);
    });

    test('un corps qui est un nombre n\'est pas un plan', () {
      expect(parseSyncPlan(42).isMalformed, isTrue);
    });

    test('une Map sans planVersion n\'est pas un plan', () {
      final sansVersion = body()..remove('planVersion');
      expect(parseSyncPlan(sansVersion).isMalformed, isTrue);
    });

    test('un planVersion en String n\'est pas un planVersion', () {
      // Sans le contrôle de type, la construction du plan lèverait au lieu de
      // se replier — et lever revient à confondre « pas un plan » avec « plan
      // refusé ».
      expect(parseSyncPlan(body(planVersion: '1')).isMalformed, isTrue);
    });

    test('un planVersion décimal n\'est pas un planVersion', () {
      expect(parseSyncPlan(body(planVersion: 1.5)).isMalformed, isTrue);
    });

    test('un subject vide ou blanc n\'est pas un subject', () {
      expect(parseSyncPlan(body(subject: '')).isMalformed, isTrue);
      expect(parseSyncPlan(body(subject: '   ')).isMalformed, isTrue);
      expect(parseSyncPlan(body(subject: null)).isMalformed, isTrue);
      expect(parseSyncPlan(body(subject: 123)).isMalformed, isTrue);
    });

    test('un onAbsence absent, vide ou non-String n\'est pas un plan', () {
      final sansOnAbsence = body()..remove('onAbsence');
      expect(parseSyncPlan(sansOnAbsence).isMalformed, isTrue);
      expect(parseSyncPlan(body(onAbsence: '')).isMalformed, isTrue);
      expect(parseSyncPlan(body(onAbsence: 7)).isMalformed, isTrue);
    });

    test('un streams ABSENT n\'est pas un plan vide, c\'est un non-plan', () {
      // La distinction porte tout le lot : replier `null` sur la liste vide
      // ferait d'un plan tronqué un « plan valide à zéro flux », soit sous F5
      // l'arrêt total de la synchronisation, en silence.
      final tronque = body()..remove('streams');
      expect(parseSyncPlan(tronque).isMalformed, isTrue);
    });

    test('un streams qui est une Map et non une List n\'est pas un plan', () {
      final result = parseSyncPlan(
        body(streams: const <String, Object?>{'socle': {}}),
      );
      expect(result.isMalformed, isTrue);
    });

    test('un streams à null n\'est pas un plan', () {
      expect(parseSyncPlan(body(streams: null)).isMalformed, isTrue);
    });
  });

  group('tolérance — ignorer sans erreur', () {
    test('un champ inconnu au niveau du PLAN est ignoré sans erreur', () {
      final avecExtra = body()
        ..['serverTime'] = '2026-08-16T10:00:00Z'
        ..['futureField'] = {'quelconque': true};

      final result = parseSyncPlan(avecExtra);

      expect(result.isMalformed, isFalse);
      expect(result.plan!.keys, [
        'socle',
        'finance.payments',
        'schedule.sessions',
      ]);
    });

    test('un champ inconnu au niveau d\'un FLUX est ignoré sans erreur', () {
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {
              'key': 'socle',
              'mode': 'BUNDLE',
              'scope': 'school',
              'httpPath': '/api/v1/whatever',
              'cursor': 'jamais-publie',
              'nested': {'a': 1},
            },
          ],
        ),
      );

      expect(result.isMalformed, isFalse);
      expect(result.rejectedKeys, isEmpty);
      expect(result.plan!.keys, ['socle']);
      expect(result.plan!.streams.single.mode, SyncFlowMode.bundle);
    });

    test(
      'clientResource / reason / dependsOn absents → listes VIDES, jamais null, '
      'et le plan reste valide',
      () {
        // Leur absence est un état légitime du contrat, contrairement à
        // `streams` : « aucune dépendance », « le serveur ne le dit pas encore ».
        final result = parseSyncPlan(
          body(
            streams: const <Object?>[
              {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
            ],
          ),
        );

        expect(result.isMalformed, isFalse);
        final flux = result.plan!.streams.single;
        expect(flux.clientResource, isEmpty);
        expect(flux.reason, isEmpty);
        expect(flux.dependsOn, isEmpty);
      },
    );

    test('un élément non-String dans clientResource est écarté sans invalider '
        'le flux', () {
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {
              'key': 'socle',
              'mode': 'BUNDLE',
              'scope': 'school',
              'clientResource': ['ref_school', 42, null, 'ref_school_levels'],
              'reason': ['socle', 99],
              'dependsOn': [<String>[], 'autre'],
            },
          ],
        ),
      );

      expect(result.isMalformed, isFalse);
      final flux = result.plan!.streams.single;
      expect(flux.clientResource, ['ref_school', 'ref_school_levels']);
      expect(flux.reason, ['socle']);
      expect(flux.dependsOn, ['autre']);
    });

    test(
      'clientResource qui n\'est pas une List → liste vide, plan valide',
      () {
        final result = parseSyncPlan(
          body(
            streams: const <Object?>[
              {
                'key': 'socle',
                'mode': 'BUNDLE',
                'scope': 'school',
                'clientResource': 'ref_school',
              },
            ],
          ),
        );

        expect(result.isMalformed, isFalse);
        expect(result.plan!.streams.single.clientResource, isEmpty);
      },
    );
  });

  group('flux écartés — jamais sans trace', () {
    test(
      'un mode inconnu écarte le flux, le NOMME, et laisse le reste valide',
      () {
        final result = parseSyncPlan(
          body(
            streams: const <Object?>[
              {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
              {'key': 'teleporteur', 'mode': 'TELEPORT', 'scope': 'school'},
              {'key': 'finance.payments', 'mode': 'KEYSET', 'scope': 'school'},
            ],
          ),
        );

        expect(result.isMalformed, isFalse);
        expect(result.rejectedKeys, {'teleporteur'});
        expect(result.plan!.keys, ['socle', 'finance.payments']);
      },
    );

    test(
      'un scope inconnu écarte le flux, le NOMME, et laisse le reste valide',
      () {
        final result = parseSyncPlan(
          body(
            streams: const <Object?>[
              {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
              {'key': 'galactique', 'mode': 'KEYSET', 'scope': 'universe'},
            ],
          ),
        );

        expect(result.isMalformed, isFalse);
        expect(result.rejectedKeys, {'galactique'});
        expect(result.plan!.keys, ['socle']);
      },
    );

    test('un mode ou un scope ABSENT écarte le flux et le nomme', () {
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {'key': 'sans-mode', 'scope': 'school'},
            {'key': 'sans-scope', 'mode': 'BUNDLE'},
            {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
          ],
        ),
      );

      expect(result.rejectedKeys, {'sans-mode', 'sans-scope'});
      expect(result.plan!.keys, ['socle']);
    });

    test('un plan dont TOUS les flux sont écartés reste un plan valide, ET se '
        'dénonce comme vidé PAR NOUS', () {
      // Il est vide, pas illisible — et cette différence-là est justement le
      // tri-état que le repository doit préserver. Mais il est vide DE NOTRE
      // FAIT, ce que `plan.streams` seul ne dit pas : sans ce drapeau, le
      // repository lisait « le serveur dit qu'il n'y a rien à tirer », arrêtait
      // tout le pull non-socle et mettait le corps en cache — la panne
      // survivait alors au redémarrage.
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {'key': 'teleporteur', 'mode': 'TELEPORT', 'scope': 'school'},
          ],
        ),
      );

      expect(result.isMalformed, isFalse);
      expect(result.plan!.streams, isEmpty);
      expect(result.rejectedKeys, {'teleporteur'});
      expect(result.allStreamsDropped, isTrue);
    });

    test('un seul flux retenu suffit à ne PAS lever le drapeau', () {
      // La ligne de partage est « ce client peut-il encore tirer quelque chose »,
      // pas « a-t-il tout compris ». Un flux écarté sur deux laisse un plan qui
      // gouverne ; le lire comme inconnu rendrait la main à
      // `requiredPermissions` alors que le serveur s'est fait comprendre.
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
            {'key': 'teleporteur', 'mode': 'TELEPORT', 'scope': 'school'},
          ],
        ),
      );

      expect(result.allStreamsDropped, isFalse);
      expect(result.rejectedKeys, {'teleporteur'});
    });

    test(
      'un streams VIDE ne lève pas le drapeau — le serveur, lui, a parlé',
      () {
        // Le cas que le drapeau ne doit surtout pas absorber : il n'y a rien à
        // comprendre, et « rien à tirer » est une information que le repository
        // garde telle quelle (état VIDE, jamais inconnu).
        final result = parseSyncPlan(body(streams: const <Object?>[]));

        expect(result.isMalformed, isFalse);
        expect(result.plan!.streams, isEmpty);
        expect(result.allStreamsDropped, isFalse);
      },
    );

    test('des entrées SAUTÉES sans trace lèvent le drapeau, faute de mieux', () {
      // Elles ne peuvent pas entrer dans `rejectedKeys` — sans `key`, il n'y a
      // rien à nommer — mais pour la tablette elles ont le même effet qu'un mode
      // inconnu : un flux annoncé qu'elle ne tirera pas. Déduire le drapeau de
      // `rejectedKeys` laisserait ce corps-là retomber sur « rien à tirer ».
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {'mode': 'BUNDLE', 'scope': 'school'},
            'même pas une Map',
          ],
        ),
      );

      expect(result.isMalformed, isFalse);
      expect(result.plan!.streams, isEmpty);
      expect(result.rejectedKeys, isEmpty);
      expect(result.allStreamsDropped, isTrue);
    });
  });

  group('entrées qui ne sont pas des flux — sautées SILENCIEUSEMENT', () {
    test('un flux sans key est sauté, et n\'est pas compté comme écarté', () {
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {'mode': 'BUNDLE', 'scope': 'school'},
            {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
          ],
        ),
      );

      expect(result.isMalformed, isFalse);
      expect(result.plan!.keys, ['socle']);
      // Écarté ≠ sauté : sans `key`, il n'y a rien à nommer dans la trace.
      expect(result.rejectedKeys, isEmpty);
    });

    test('une key vide, blanche ou non-String est sautée silencieusement', () {
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            {'key': '', 'mode': 'BUNDLE', 'scope': 'school'},
            {'key': '   ', 'mode': 'BUNDLE', 'scope': 'school'},
            {'key': 42, 'mode': 'BUNDLE', 'scope': 'school'},
            {'key': null, 'mode': 'BUNDLE', 'scope': 'school'},
            {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
          ],
        ),
      );

      expect(result.isMalformed, isFalse);
      expect(result.plan!.keys, ['socle']);
      expect(result.rejectedKeys, isEmpty);
    });

    test('un élément de streams qui n\'est pas une Map est sauté', () {
      final result = parseSyncPlan(
        body(
          streams: const <Object?>[
            'socle',
            42,
            null,
            <String>['socle'],
            {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
          ],
        ),
      );

      expect(result.isMalformed, isFalse);
      expect(result.plan!.keys, ['socle']);
      expect(result.rejectedKeys, isEmpty);
    });
  });
}
