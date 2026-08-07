import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/di/offline_modules/documents_offline_di.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_session_guard.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/find_cached_document_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/list_cached_documents_use_case.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../features/offline_full_db.dart';

/// Le registrar enregistre un handler de pull ; il lui faut un coordinateur,
/// mais rien ici ne déclenche de cycle.
class _AlwaysOffline implements ConnectivityService {
  @override
  Future<bool> isOnline() async => false;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Ce que le câblage doit rendre, faute de quoi la garde ne s'exécuterait
/// jamais **en silence**.
///
/// Le seul point d'appel de production de [EditiqueCacheSessionGuard] est
/// `main.dart`, dans un `try`/`catch` muet : si le registrar oubliait de
/// l'enregistrer, `getIt<…>()` lèverait, l'exception serait avalée, et
/// l'effacement d'ouverture de session ne se produirait plus — sans crash, sans
/// log, sans le moindre test rouge. Les tests unitaires de la garde, eux,
/// resteraient verts : ils la construisent à la main.
///
/// D'où cette vérification : les trois consommateurs de la garde de profil
/// (RG-012-4) se résolvent réellement depuis le conteneur.
void main() {
  late Database db;
  late GetIt getIt;

  setUp(() async {
    db = await openFullOfflineDb();
    getIt = GetIt.asNewInstance();
    // Le registrar ne touche à rien de la plateforme : tout y est paresseux, et
    // ces quatre-là suffisent à le faire tourner.
    getIt.registerSingleton<Database>(db);
    getIt.registerSingleton<Map<String, dynamic>>(<String, dynamic>{});
    getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
    getIt.registerSingleton<CurrentUserContext>(CurrentUserContext());
    getIt.registerSingleton<AuthLocalDao>(AuthLocalDao(db));
    getIt.registerSingleton<Dio>(Dio());
    getIt.registerSingleton<PullCoordinator>(
      PullCoordinator(connectivity: _AlwaysOffline()),
    );
    getIt.registerSingleton<IdGenerator>(const IdGenerator(Uuid()));
    getIt.registerSingleton<SyncMetaDao>(SyncMetaDao(db));
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  test('la garde d ouverture de session se résout depuis le conteneur', () {
    registerDocumentsOffline(getIt);

    expect(getIt<EditiqueCacheSessionGuard>(), isNotNull);
  });

  // Ces deux-là alimentent l'UI : construites sans leur garde, elles
  // exposeraient l'index à un profil qui n'y a pas droit.
  test('les deux lectures d index se résolvent avec leur garde', () {
    registerDocumentsOffline(getIt);

    expect(getIt<ListCachedDocumentsUseCase>(), isNotNull);
    expect(getIt<FindCachedDocumentUseCase>(), isNotNull);
  });
}
