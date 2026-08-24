import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/di/offline_injection.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_state.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../features/offline_full_db.dart';

class _MockAuthSessionManager extends Mock implements AuthSessionManager {}

class _AlwaysOffline implements ConnectivityService {
  @override
  Future<bool> isOnline() async => false;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Le **câblage** de la popin « Choisir un payeur », pas son comportement.
///
/// Le comportement est prouvé ailleurs, sur des instances construites à la
/// main. C'est nécessaire et insuffisant : la popin, elle, résout son bloc par
/// `getIt<PayerSearchBloc>()`. Un enregistrement oublié ne fait broncher ni
/// l'analyseur ni aucun test de comportement — il lève au premier tap sur
/// « Choisir un payeur », au guichet.
void main() {
  late Database db;
  late GetIt getIt;

  setUp(() async {
    db = await openFullOfflineDb();
    getIt = GetIt.asNewInstance();

    getIt.registerSingleton<Database>(db);
    getIt.registerSingleton<Map<String, dynamic>>(<String, dynamic>{});
    getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
    getIt.registerSingleton<Dio>(Dio());
    getIt.registerSingleton<CurrentUserContext>(CurrentUserContext());
    getIt.registerSingleton<IdGenerator>(const IdGenerator(Uuid()));
    getIt.registerSingleton<SyncMetaDao>(SyncMetaDao(db));
    getIt.registerSingleton<AuthLocalDao>(AuthLocalDao(db));
    getIt.registerSingleton<ConnectivityService>(_AlwaysOffline());
    getIt.registerSingleton<SyncEngine>(
      SyncEngine(outbox: OutboxDao(db), connectivity: _AlwaysOffline()),
    );
    getIt.registerSingleton<PullCoordinator>(
      PullCoordinator(connectivity: _AlwaysOffline()),
    );
    getIt.registerSingleton<AuthSessionManager>(_MockAuthSessionManager());
    // Stampé sur chaque encaissement (traçabilité RG-012-16) : le repository
    // Facturation le réclame, la popin en dépend donc transitivement.
    getIt.registerSingleton<DeviceIdentityService>(
      const DeviceIdentityService(FlutterSecureStorage(), Uuid()),
    );

    registerOfflineModules(getIt);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  test('le bloc de la popin se résout depuis le conteneur RÉEL', () {
    expect(() => getIt<PayerSearchBloc>(), returnsNormally);
  });

  /// `registerFactory`, jamais singleton (règle non négociable #2) : la popin
  /// ferme son bloc en partant, et deux ouvertures successives ne doivent pas
  /// se partager un bloc déjà fermé.
  test('chaque ouverture reçoit un bloc NEUF', () {
    final premier = getIt<PayerSearchBloc>();
    final second = getIt<PayerSearchBloc>();

    expect(identical(premier, second), isFalse);

    premier.close();
    second.close();
  });

  /// Le bloc traverse ses deux use cases jusqu'à la base réelle. Une chaîne
  /// mal branchée sortirait une erreur de stockage plutôt qu'une liste.
  ///
  /// ⚠️ On attend l'ÉMISSION, jamais un délai : le nombre de micro-tâches d'une
  /// lecture SQL n'est pas un contrat, et un test qui parie dessus devient
  /// intermittent. L'abonnement est posé AVANT le déclencheur, sinon la
  /// première émission passe avant qu'on écoute.
  test(
    'la chaîne va jusqu\'à la base : un élève inconnu ne fait pas d\'erreur',
    () async {
      final bloc = getIt<PayerSearchBloc>();
      addTearDown(bloc.close);

      final attendu = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          isA<PayerSearchLoading>(),
          // Personne n'a payé, aucun tuteur : l'état initial, pas une erreur —
          // « rien à proposer » n'est pas « la base est illisible ».
          isA<PayerSearchInitial>(),
        ]),
      );
      bloc.add(const PayerSuggestionsRequested('eleve-inconnu'));

      await attendu;
    },
  );
}
