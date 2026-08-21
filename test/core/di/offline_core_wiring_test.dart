import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/di/offline_injection.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_holder.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_repository.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../features/offline_full_db.dart';

/// Le **câblage** du socle, pas son comportement.
///
/// Les gardes du `PullCoordinator` sont prouvées ailleurs, sur des instances
/// construites à la main dans les tests. C'est nécessaire et insuffisant : une
/// garde peut être parfaitement implémentée, parfaitement testée, et n'être
/// **jamais branchée** en production — ses paramètres sont optionnels, et une
/// sonde absente est silencieusement fail-open.
///
/// C'est exactement ce qui est arrivé au lot F6 : cinq use cases d'hydratation
/// ont rendu leur sonde de crédentiels au socle, le socle l'a acceptée, la DI ne
/// la lui a jamais donnée. Cinq gardes retirées, aucune rétablie, et la suite
/// entière restait verte — parce que tous les tests injectaient la sonde
/// eux-mêmes.
///
/// Le lot F5 rouvre exactement la même trappe : `SyncPlanHolder? planHolder` est
/// lui aussi optionnel, et son absence ne casse rien — le coordinateur voit un
/// plan « inconnu » en permanence, retombe sur `requiredPermissions`, et le lot
/// entier est **inerte** sans qu'aucun test de comportement ne bronche.
///
/// Ce fichier monte donc le conteneur RÉEL et observe le comportement qui en
/// sort. Ce qu'aucun autre test ne fait.
class _MockAuthSessionManager extends Mock implements AuthSessionManager {}

/// Le plan, **pilotable** depuis le test.
///
/// Rend « inconnu » par défaut, c'est-à-dire le mode dégradé où le filtre local
/// reprend la main : c'est ce qu'attendent les tests de câblage des gardes, qui
/// n'ont rien à dire sur le périmètre. Les tests du lot F5, eux, lui posent un
/// vrai plan.
///
/// [lecturesReseau] compte les relectures effectives : c'est la seule façon de
/// distinguer « le mémo a tenu » de « le porteur a retapé le réseau », et donc
/// de prouver F9 sans simuler un réseau.
class _PlanPilotable implements SyncPlanRepository {
  SyncPlanState state = const SyncPlanState.unknown(
    SyncPlanUnknownCause.absent,
  );
  int lecturesReseau = 0;

  @override
  Future<SyncPlanState> load() async => state;

  @override
  Future<SyncPlanState> loadCached() async => state;

  @override
  Future<SyncPlanState?> refreshFromNetwork() async {
    lecturesReseau++;
    return state;
  }
}

class _AlwaysOnline implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

class _CountingHandler implements PullHandler {
  _CountingHandler({
    this.resource = 'classrooms',
    this.isBaseline = true,
    this.requiredPermissions = const <Perm>[],
  });

  int calls = 0;

  @override
  final String resource;

  @override
  final List<Perm> requiredPermissions;

  @override
  final bool isBaseline;

  @override
  Future<PullOutcome> pull() async {
    calls++;
    return const PullOutcome.updated();
  }
}

void main() {
  late GetIt getIt;
  late Database db;
  late _MockAuthSessionManager session;
  late _PlanPilotable plan;

  /// Un plan valide qui ne porte QUE ces clés.
  ///
  /// `clientResource` est laissé vide à dessein : le routage passe par
  /// `planKeyOf`, jamais par ce champ — analysé en mode tolérant, il serait vide
  /// aussi sur un serveur qui l'omettrait, et s'en servir mettrait les
  /// dix-neuf handlers hors plan sans la moindre erreur.
  SyncPlan planPortant(List<String> cles) => SyncPlan(
    planVersion: 1,
    subject: 'uid-a',
    onAbsence: 'ignore',
    streams: [
      for (final cle in cles)
        SyncPlanFlow(
          key: cle,
          clientResource: const <String>[],
          mode: SyncFlowMode.keyset,
          scope: SyncFlowScope.school,
          reason: const <String>[],
          dependsOn: const <String>[],
        ),
    ],
  );

  setUp(() async {
    getIt = GetIt.asNewInstance();
    db = await openFullOfflineDb();
    session = _MockAuthSessionManager();
    plan = _PlanPilotable();

    getIt.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
    getIt.registerLazySingleton<AuthSessionManager>(() => session);
    getIt.registerLazySingleton<SyncPlanRepository>(() => plan);

    await registerOfflineCore(getIt, database: db);
    // Le socle enregistre son propre `ConnectivityService`, adossé au canal de
    // plateforme. On le remplace APRÈS coup : le coordinateur le résout
    // paresseusement, donc il verra bien celui-ci.
    getIt.unregister<ConnectivityService>();
    getIt.registerLazySingleton<ConnectivityService>(() => _AlwaysOnline());
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  test(
    'le gate crédentiels est RÉELLEMENT branché sur le PullCoordinator : sans '
    'jetons utilisables, aucune ressource ne part',
    () async {
      when(() => session.canAuthenticate()).thenAnswer((_) async => false);
      final handler = _CountingHandler();
      getIt<PullCoordinator>().registerHandler(handler);

      final report = await getIt<PullCoordinator>().pullAll();

      // Le handler est `isBaseline` : rien d'autre que le gate crédentiels ne
      // peut l'arrêter. S'il tire quand même, c'est que la sonde n'est pas
      // câblée — le paramètre est optionnel et le socle est alors fail-open.
      expect(
        handler.calls,
        0,
        reason:
            'la sonde de crédentiels n\'est pas passée au PullCoordinator '
            'dans offline_injection.dart',
      );
      expect(report.skipped, isTrue);
    },
  );

  test(
    'contre-épreuve : avec des jetons utilisables, le cycle part normalement',
    () async {
      when(() => session.canAuthenticate()).thenAnswer((_) async => true);
      final handler = _CountingHandler();
      getIt<PullCoordinator>().registerHandler(handler);

      final report = await getIt<PullCoordinator>().pullAll();

      expect(handler.calls, 1);
      expect(report.updated, 1);
    },
  );

  test('le même gate vaut sur pullSubset — le chemin des écrans, celui qui a '
      'perdu sa sonde au repli', () async {
    when(() => session.canAuthenticate()).thenAnswer((_) async => false);
    final handler = _CountingHandler();
    getIt<PullCoordinator>().registerHandler(handler);

    final report = await getIt<PullCoordinator>().pullSubset({
      handler.resource,
    });

    expect(handler.calls, 0);
    expect(report.skipped, isTrue);
  });

  group('le plan de synchro est l\'autorité de périmètre (ADR-015 F5)', () {
    /// Les deux handlers de la démonstration : l'un est au plan, l'autre non, et
    /// la session détient les DEUX permissions. Sous le seul filtre local, les
    /// deux partiraient — seul le plan peut en écarter un.
    late _CountingHandler auPlan;
    late _CountingHandler horsPlan;

    setUp(() {
      when(() => session.canAuthenticate()).thenAnswer((_) async => true);
      auPlan = _CountingHandler(
        resource: 'classrooms',
        isBaseline: false,
        requiredPermissions: const [Perm.classroomRead],
      );
      horsPlan = _CountingHandler(
        resource: 'attendance',
        isBaseline: false,
        requiredPermissions: const [Perm.attendanceRead],
      );
      getIt<PullCoordinator>()
        ..registerHandler(auPlan)
        ..registerHandler(horsPlan);
      getIt<CurrentPermissions>().set([
        Perm.classroomRead.wire,
        Perm.attendanceRead.wire,
      ]);
    });

    test('le SyncPlanHolder est RÉELLEMENT branché sur le PullCoordinator : un '
        'flux absent du plan ne part pas, MÊME quand la session en détient la '
        'permission', () async {
      plan.state = SyncPlanState.known(
        planPortant([SyncPlanKeys.classroomClassrooms]),
      );

      final report = await getIt<PullCoordinator>().pullAll();

      expect(auPlan.calls, 1, reason: 'le flux planifié doit être tiré');
      expect(
        horsPlan.calls,
        0,
        reason:
            'le planHolder n\'est pas passé au PullCoordinator dans '
            'offline_injection.dart : sans lui le plan est « inconnu » en '
            'permanence et les DEUX handlers partent',
      );
      expect(
        report.outOfPlan,
        1,
        reason:
            'un flux hors plan se compte sous son nom, jamais en `forbidden`',
      );
      // Substitution, jamais union : sous un plan connu, le filtre local ne
      // s'applique plus du tout — il n'a donc rien à compter.
      expect(report.forbidden, 0);
      // Le plan ne porte qu'une clé, et son handler est enregistré : aucun
      // flux planifié ne reste sans preneur.
      expect(report.plannedNotPulled, 0);
      expect(report.plannedNotPulledKeys, isEmpty);
      // Un périmètre correct n'est PAS une dégradation.
      expect(report.isDegraded, isFalse);
    });

    test(
      'contre-épreuve : plan inconnu → mode dégradé, le filtre local reprend la '
      'main et les DEUX flux partent',
      () async {
        // C'est le comportement d'avant le lot, et c'est aussi ce qu'on verrait
        // si le porteur n'était pas câblé : sans cette contre-épreuve, le test
        // ci-dessus pourrait passer pour une autre raison.
        plan.state = const SyncPlanState.unknown(
          SyncPlanUnknownCause.notDeployed,
        );

        final report = await getIt<PullCoordinator>().pullAll();

        expect(auPlan.calls, 1);
        expect(horsPlan.calls, 1);
        expect(report.outOfPlan, 0);
        expect(report.forbidden, 0);
      },
    );

    test('le SyncPlanHolder est résolvable depuis le conteneur, et il l\'est '
        'depuis registerOfflineCore — pas depuis le registrar de branche', () {
      // `registerOfflineModules()` n'a PAS été appelé dans ce setUp : si le
      // porteur y avait été enregistré, cette résolution lèverait. C'est
      // exactement ce qui a cassé au premier essai d'implémentation.
      expect(() => getIt<SyncPlanHolder>(), returnsNormally);
      expect(
        getIt<SyncPlanHolder>(),
        same(getIt<SyncPlanHolder>()),
        reason: 'un porteur par résolution perdrait mémo et péremption',
      );
    });

    test('F9 câblé : le mémo tient tant que rien ne bouge, et un changement de '
        'permissions fait RELIRE le plan au cycle suivant', () async {
      plan.state = SyncPlanState.known(
        planPortant([SyncPlanKeys.classroomClassrooms]),
      );

      await getIt<PullCoordinator>().pullAll();
      expect(auPlan.calls, 1);
      expect(horsPlan.calls, 0);
      expect(plan.lecturesReseau, 1);

      // Le serveur élargit le plan — un droit vient d'être accordé côté back.
      // Tant que la session ne le sait pas, le mémo tient : c'est ce qui évite
      // un GET /sync/plan par montage d'écran.
      plan.state = SyncPlanState.known(
        planPortant([
          SyncPlanKeys.classroomClassrooms,
          SyncPlanKeys.attendanceRecords,
        ]),
      );
      await getIt<PullCoordinator>().pullAll();

      expect(
        plan.lecturesReseau,
        1,
        reason: 'sans signal, le plan ne doit pas être relu',
      );
      expect(horsPlan.calls, 0);

      // Le refresh livre l'ensemble élargi. Sans F9, F5 serait une
      // RÉGRESSION : un droit élargi n'aurait plus d'effet avant le prochain
      // login, alors qu'il est immédiat aujourd'hui.
      getIt<CurrentPermissions>().set([
        Perm.classroomRead.wire,
        Perm.attendanceRead.wire,
        Perm.attendanceStatsRead.wire,
      ]);
      final report = await getIt<PullCoordinator>().pullAll();

      expect(
        plan.lecturesReseau,
        2,
        reason:
            'le SyncPlanHolder n\'est pas abonné à CurrentPermissions dans '
            'offline_injection.dart',
      );
      expect(horsPlan.calls, 1, reason: 'le flux élargi doit descendre');
      expect(report.outOfPlan, 0);
    });

    test(
      'un plan VIDE coupe le pull et le dit : le rapport est dégradé, pas vert',
      () async {
        // Le contrat promet qu'un plan n'est jamais vide — il porte au minimum
        // le socle. C'est donc un serveur qui se contredit, et sans ce drapeau
        // ce serait la panne la plus totale et la plus silencieuse du
        // dispositif : plus rien ne descend, pastille verte.
        plan.state = SyncPlanState.empty(planPortant(const []));

        final report = await getIt<PullCoordinator>().pullAll();

        expect(auPlan.calls, 0);
        expect(horsPlan.calls, 0);
        expect(report.planEmpty, isTrue);
        expect(report.isDegraded, isTrue);
        expect(
          report.outOfPlan,
          0,
          reason: 'rien n\'est « hors plan » quand le plan ne porte rien',
        );
      },
    );
  });
}
