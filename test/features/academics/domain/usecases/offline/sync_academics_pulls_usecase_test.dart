import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/offline/sync_academics_pulls_usecase.dart';

/// Toujours en ligne : la pré-garde de connectivité et le gate de crédentiels
/// sont passés dans le socle au lot F6 et sont testés là-bas
/// (`test/core/offline/pull_coordinator_test.dart`). Ici, ils ne doivent
/// qu'être franchis.
class _AlwaysOnline implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Handler qui note son passage dans un journal partagé — seule façon
/// d'observer l'ordre RÉEL d'invocation (`calls` dit combien, jamais quand).
class _FakeHandler implements PullHandler {
  _FakeHandler(this.resource, this._journal, this.outcome);

  @override
  final String resource;

  final List<String> _journal;
  final PullOutcome outcome;

  int calls = 0;

  @override
  List<Perm> get requiredPermissions => const [Perm.schoolRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    calls++;
    _journal.add(resource);
    return outcome;
  }
}

/// Coordinateur qui retient le sous-ensemble demandé — pour observer ce que le
/// use case DEMANDE, indépendamment de ce que le registre sait tirer.
class _RecordingCoordinator extends PullCoordinator {
  _RecordingCoordinator(PullCompletionBus bus)
    : super(connectivity: _AlwaysOnline(), completionBus: bus);

  final List<Set<String>> requested = [];

  @override
  Future<PullRunReport> pullSubset(Set<String> resources) {
    requested.add(resources);
    return super.pullSubset(resources);
  }
}

void main() {
  /// L'ordre d'enregistrement des six handlers dans
  /// `lib/core/di/offline_modules/academics_offline_di.dart`, recopié ici parce
  /// qu'un test unitaire ne peut pas monter la DI réelle (base, Dio, réseau).
  ///
  /// Ce n'est pas cette liste qui fait autorité : `test/core/di/
  /// offline_pull_registration_order_test.dart` monte la DI réelle et vérifie
  /// ses arêtes sur elle. Si les deux divergeaient, c'est là-bas qu'il faut
  /// regarder.
  const ordreDeLaDi = <String>[
    'academics_grades_referential',
    'schedule_time_slots',
    'schedule_sessions',
    'academics_cours',
    'academics_evaluations',
    'academics_notes',
  ];
  const applique = PullOutcome.updated(upserted: 1);

  late PullCompletionBus completionBus;
  late _RecordingCoordinator coordinator;
  late List<String> journal;
  late Map<String, _FakeHandler> handlers;
  late List<Set<String>> notified;
  late SyncAcademicsPullsUseCase useCase;

  /// Monte un registre portant [resources], chacune rendant [applique] sauf
  /// celles listées dans [issues].
  void mountRegistry(
    List<String> resources, {
    Map<String, PullOutcome> issues = const {},
  }) {
    for (final resource in resources) {
      final handler = _FakeHandler(
        resource,
        journal,
        issues[resource] ?? applique,
      );
      handlers[resource] = handler;
      coordinator.registerHandler(handler);
    }
  }

  setUp(() {
    completionBus = PullCompletionBus();
    coordinator = _RecordingCoordinator(completionBus);
    journal = <String>[];
    handlers = <String, _FakeHandler>{};
    notified = <Set<String>>[];
    completionBus.stream.listen(notified.add);
    useCase = SyncAcademicsPullsUseCase(coordinator);
  });

  tearDown(() async => completionBus.dispose());

  group('périmètre demandé', () {
    test('les six ressources des deux écrans, et elles seules', () async {
      mountRegistry(ordreDeLaDi);

      await useCase();

      expect(coordinator.requested, hasLength(1));
      expect(coordinator.requested.single, {
        'schedule_time_slots',
        'schedule_sessions',
        'academics_grades_referential',
        'academics_cours',
        'academics_evaluations',
        'academics_notes',
      });
    });

    test('aucune ressource étrangère n\'est tirée dans leur sillage', () async {
      mountRegistry([...ordreDeLaDi, 'finance_payments']);

      await useCase();

      expect(handlers['finance_payments']!.calls, 0);
      expect(journal, hasLength(6));
    });

    test('le rapport rend compte de CHAQUE ressource demandée', () async {
      mountRegistry(ordreDeLaDi);

      final rapport = await useCase();

      // Un écran veut savoir si SA ressource est passée, pas si le cycle global
      // s'est bien terminé.
      for (final resource in ordreDeLaDi) {
        expect(rapport.succeeded(resource), isTrue, reason: resource);
      }
      expect(rapport.isDegraded, isFalse);
    });

    test('une ressource demandée mais non enregistrée est ignorée en silence '
        '(un APK plus ancien que l\'écran)', () async {
      mountRegistry(const ['schedule_time_slots', 'schedule_sessions']);

      final rapport = await useCase();

      expect(journal, ['schedule_time_slots', 'schedule_sessions']);
      expect(rapport.failed, 0);
      expect(rapport.isDegraded, isFalse);
    });
  });

  group('réveil de l\'UI (PullCompletionBus)', () {
    test('chaque ressource appliquée est diffusée SÉPARÉMENT, et dans l\'ordre '
        'du REGISTRE', () async {
      mountRegistry(ordreDeLaDi);

      await useCase();
      await Future<void>.delayed(Duration.zero);

      // L'ORDRE EST PORTEUR, et cette liste le fige (ADR-015 K). Il a CHANGÉ au
      // lot F6 : le use case tenait sa propre séquence (créneaux → séances →
      // barème → cours → …), `pullSubset` prend celle du REGISTRE, où le barème
      // est enregistré en TÊTE des six. L'ensemble que passe le use case n'a,
      // lui, aucun ordre : le permuter ne changerait rien ici.
      //
      // L'arête qui compte est tenue par les deux séquences —
      // `academics_grades_referential` reste AVANT `academics_cours`, parce que
      // le détail d'un cours et la composition des évaluations lisent le barème.
      expect(notified, [
        {'academics_grades_referential'},
        {'schedule_time_slots'},
        {'schedule_sessions'},
        {'academics_cours'},
        {'academics_evaluations'},
        {'academics_notes'},
      ]);
    });

    test('la diffusion a lieu UNE fois par ressource : le use case ne double '
        'plus celle du coordinateur', () async {
      mountRegistry(ordreDeLaDi);

      await useCase();
      await Future<void>.delayed(Duration.zero);

      // Aplati, parce que c'est la RESSOURCE qui doit être unique : le use case
      // diffusait lui aussi, et rien n'aurait fait rougir un écran relu deux
      // fois par pull si on ne comptait que les messages.
      final diffusees = notified.expand((sujets) => sujets).toList();
      expect(diffusees, hasLength(6));
      expect(
        diffusees.toSet(),
        hasLength(6),
        reason: 'ressource diffusée deux fois : $diffusees',
      );
    });

    test('un cycle 304 (rien appliqué) ne réveille personne', () async {
      mountRegistry(
        ordreDeLaDi,
        issues: const {'schedule_sessions': PullOutcome.notModified()},
      );

      await useCase();
      await Future<void>.delayed(Duration.zero);

      expect(notified, isNot(contains({'schedule_sessions'})));
      expect(notified, hasLength(5));
    });

    test(
      'un pull en échec ne réveille personne et n\'empêche pas les autres',
      () async {
        mountRegistry(
          ordreDeLaDi,
          issues: const {'schedule_sessions': PullOutcome.error('réseau')},
        );

        final rapport = await useCase();
        await Future<void>.delayed(Duration.zero);

        expect(notified, isNot(contains({'schedule_sessions'})));
        expect(notified, hasLength(5));
        expect(rapport.succeeded('schedule_sessions'), isFalse);
        expect(rapport.succeeded('academics_notes'), isTrue);
      },
    );
  });
}
