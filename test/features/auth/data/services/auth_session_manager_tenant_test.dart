import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_session.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/data/services/password_verifier_service.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockTokenStorage extends Mock implements TokenStorageService {}

/// Journal des attachements, avec l'école que le contexte portait À CE
/// MOMENT-LÀ : c'est l'ordre qui compte, pas seulement le fait.
class _RecordingTenants implements TenantSwitch {
  _RecordingTenants(this.ctx);

  final CurrentUserContext ctx;
  final List<String> log = [];
  Object? attachFailure;
  Object? detachFailure;

  @override
  Future<void> attach(String schoolId) async {
    log.add('attach $schoolId (contexte: ${ctx.schoolId})');
    if (attachFailure != null) throw attachFailure!;
  }

  @override
  Future<void> detach() async {
    log.add('detach (contexte: ${ctx.schoolId})');
    if (detachFailure != null) throw detachFailure!;
  }
}

AuthSession _session() => const AuthSession(
  accessToken: 'jwt',
  tokenType: 'Bearer',
  expiresIn: 3600,
  refreshToken: 'refresh',
  refreshExpiresAt: 10000000,
  userVersion: 0,
  user: AuthenticatedUser(
    id: 'u1',
    email: 'caisse@ecole.cd',
    firstName: 'Amina',
    lastName: 'Kalala',
    role: 'ACCOUNTANT',
    schoolId: 'sch-1',
  ),
);

/// L'école de la session suit le contexte courant (MULTI_ECOLE_PLAN.md §10.2) :
/// attachée AVANT qu'il soit posé, détachée APRÈS qu'il a été vidé.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late AuthLocalDao dao;
  late _MockTokenStorage tokens;
  late CurrentUserContext ctx;
  late _RecordingTenants tenants;
  late AuthSessionManager manager;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    for (final table in buildOfflineSchema()) {
      await db.execute(table.createTableSql);
    }
    dao = AuthLocalDao(db);
    tokens = _MockTokenStorage();
    when(() => tokens.clearAuthSession()).thenAnswer((_) async {});
    when(() => tokens.readAuthSession()).thenAnswer((_) async => null);
    when(() => tokens.readRefreshToken()).thenAnswer((_) async => null);
    when(() => tokens.readParkedRefresh()).thenAnswer((_) async => null);
    when(() => tokens.clearParkedRefresh()).thenAnswer((_) async {});
    ctx = CurrentUserContext();
    tenants = _RecordingTenants(ctx);
    manager = AuthSessionManager(
      tokenStorage: tokens,
      authLocalDao: dao,
      verifier: const PasswordVerifierService(),
      currentUser: ctx,
      tenants: tenants,
      now: () => 1000,
    );
  });

  tearDown(() => db.close());

  test(
    'login en ligne : l école s attache AVANT que le contexte la porte',
    () async {
      await manager.persistOnlineLogin(_session(), 'MotDePasse123');

      expect(tenants.log, ['attach sch-1 (contexte: null)']);
      expect(ctx.schoolId, 'sch-1');
    },
  );

  test('login hors ligne : même ordre', () async {
    await manager.persistOnlineLogin(_session(), 'MotDePasse123');
    await manager.wipeSession();
    tenants.log.clear();

    final result = await manager.loginOffline(
      email: 'caisse@ecole.cd',
      password: 'MotDePasse123',
    );

    expect(result.isRight(), isTrue);
    expect(tenants.log, ['attach sch-1 (contexte: null)']);
    expect(ctx.schoolId, 'sch-1');
  });

  test('login hors ligne dont l école ne s ouvre pas : aucune session locale '
      'ne reste derrière', () async {
    await manager.persistOnlineLogin(_session(), 'MotDePasse123');
    await manager.wipeSession();
    tenants.attachFailure = StateError('fichier illisible');

    await expectLater(
      manager.loginOffline(email: 'caisse@ecole.cd', password: 'MotDePasse123'),
      throwsStateError,
    );

    expect(await dao.getSession(), isNull);
    expect(ctx.schoolId, isNull);
  });

  test('le tic de fraîcheur rattache l école de la session', () async {
    await manager.persistOnlineLogin(_session(), 'MotDePasse123');
    tenants.log.clear();

    await manager.evaluateFreshness();

    expect(tenants.log, ['attach sch-1 (contexte: sch-1)']);
  });

  test('fermer la session détache APRÈS avoir vidé le contexte', () async {
    await manager.persistOnlineLogin(_session(), 'MotDePasse123');

    await manager.wipeSession();

    expect(tenants.log.last, 'detach (contexte: null)');
  });

  test('un détachement qui échoue ne fait pas échouer la fermeture', () async {
    await manager.persistOnlineLogin(_session(), 'MotDePasse123');
    tenants.detachFailure = StateError('détachement');

    await manager.wipeSession();

    expect(ctx.schoolId, isNull);
    expect(await dao.getSession(), isNull);
  });

  test('attachSchool délègue, et laisse passer l échec', () async {
    await manager.attachSchool('sch-9');
    expect(tenants.log, ['attach sch-9 (contexte: null)']);

    tenants.attachFailure = StateError('fichier illisible');
    await expectLater(manager.attachSchool('sch-9'), throwsStateError);
  });
}
