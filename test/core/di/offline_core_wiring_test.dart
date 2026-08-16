import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/di/offline_injection.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
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
/// Ce fichier monte donc le conteneur RÉEL et observe le comportement qui en
/// sort. Ce qu'aucun autre test ne fait.
class _MockAuthSessionManager extends Mock implements AuthSessionManager {}

class _AlwaysOnline implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

class _CountingHandler implements PullHandler {
  int calls = 0;

  @override
  String get resource => 'classrooms';

  @override
  List<Perm> get requiredPermissions => const [];

  @override
  bool get isBaseline => true;

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

  setUp(() async {
    getIt = GetIt.asNewInstance();
    db = await openFullOfflineDb();
    session = _MockAuthSessionManager();

    getIt.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
    getIt.registerLazySingleton<AuthSessionManager>(() => session);

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
}
