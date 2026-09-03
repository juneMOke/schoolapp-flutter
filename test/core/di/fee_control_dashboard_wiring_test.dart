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
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_charge_positions_by_level_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_codes_for_year_use_case.dart';
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

/// Le **câblage** des deux lectures neuves du tableau de bord (FCD-0), pas leur
/// comportement — celui-là est prouvé sur une base en mémoire, ailleurs.
///
/// C'est nécessaire et insuffisant : le bloc du tableau de bord les résout par
/// `getIt<…>()`. Un enregistrement oublié ne fait broncher ni l'analyseur ni
/// aucun test de comportement — il lève à l'ouverture de l'écran.
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
    getIt.registerSingleton<DeviceIdentityService>(
      const DeviceIdentityService(FlutterSecureStorage(), Uuid()),
    );

    registerOfflineModules(getIt);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  test('les deux lectures du tableau de bord se résolvent depuis le conteneur '
      'RÉEL', () {
    expect(() => getIt<GetFeeCodesForYearUseCase>(), returnsNormally);
    expect(() => getIt<GetFeeChargePositionsByLevelUseCase>(), returnsNormally);
  });

  /// La chaîne traverse le repository et le DAO jusqu'à la base. Mal branchée,
  /// elle rendrait un `StorageFailure` plutôt qu'une liste vide — et l'écran
  /// dirait « erreur » là où la vérité est « rien à facturer ».
  test('la chaîne va jusqu\'à la base : une année sans créance rend du VIDE, '
      'pas une erreur', () async {
    final codes = await getIt<GetFeeCodesForYearUseCase>()(
      academicYearId: 'ay-inconnue',
    );
    final positions = await getIt<GetFeeChargePositionsByLevelUseCase>()(
      academicYearId: 'ay-inconnue',
      feeCode: 'TUITION',
    );

    expect(codes.isRight(), isTrue, reason: 'lecture des natures');
    expect(codes.getOrElse(() => ['non vide']), isEmpty);
    expect(positions.isRight(), isTrue, reason: 'lecture des positions');
    expect(positions.getOrElse(() => throw StateError('gauche')), isEmpty);
  });
}
