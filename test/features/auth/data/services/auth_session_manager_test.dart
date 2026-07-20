import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/data/services/password_verifier_service.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';

class MockTokenStorageService extends Mock implements TokenStorageService {}

AuthSession _session({
  required String uid,
  int userVersion = 0,
  int? refreshExpiresAt,
}) => AuthSession(
  accessToken: 'jwt',
  tokenType: 'Bearer',
  expiresIn: 3600,
  refreshToken: 'refresh',
  refreshExpiresAt: refreshExpiresAt,
  userVersion: userVersion,
  user: AuthenticatedUser(
    id: uid,
    email: 'prof@ecole.cd',
    firstName: 'Amina',
    lastName: 'Kalala',
    role: 'TEACHER',
    schoolId: 'sch-1',
  ),
);

Future<Database> _openDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  for (final table in buildOfflineSchema()) {
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(indexSql);
    }
  }
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(_session(uid: 'fallback')));

  late Database db;
  late AuthLocalDao dao;
  late MockTokenStorageService tokenStorage;
  var clock = 1000;

  setUp(() async {
    clock = 1000;
    db = await _openDb();
    dao = AuthLocalDao(db);
    tokenStorage = MockTokenStorageService();
    when(() => tokenStorage.clearAuthSession()).thenAnswer((_) async {});
    when(() => tokenStorage.readAuthSession()).thenAnswer((_) async => null);
  });

  tearDown(() => db.close());

  AuthSessionManager build() => AuthSessionManager(
    tokenStorage: tokenStorage,
    authLocalDao: dao,
    verifier: const PasswordVerifierService(),
    now: () => clock,
  );

  test('persistOnlineLogin puis loginOffline round-trip (D-01/D-02)', () async {
    final manager = build();
    await manager.persistOnlineLogin(
      _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
      'MotDePasse123',
    );

    // Bon mot de passe → snapshot NORMAL (fraîcheur J0).
    final ok = await manager.loginOffline(
      email: 'prof@ecole.cd',
      password: 'MotDePasse123',
    );
    expect(ok.isRight(), isTrue);
    ok.fold((_) {}, (snap) {
      expect(snap.isOffline, isTrue);
      expect(snap.mode, SessionMode.normal);
      expect(snap.session.user.id, 'u1');
    });

    // Mauvais mot de passe → refus.
    final bad = await manager.loginOffline(
      email: 'prof@ecole.cd',
      password: 'Mauvais',
    );
    expect(bad.isLeft(), isTrue);
  });

  test('loginOffline refuse un compte jamais vu (D-01)', () async {
    final manager = build();
    final res = await manager.loginOffline(
      email: 'inconnu@ecole.cd',
      password: 'x',
    );
    expect(res.isLeft(), isTrue);
  });

  test(
    'loginOffline insensible à la casse de l\'email (COLLATE NOCASE)',
    () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      final res = await manager.loginOffline(
        email: 'PROF@ECOLE.CD', // casse différente de 'prof@ecole.cd'
        password: 'MotDePasse123',
      );
      expect(res.isRight(), isTrue);
    },
  );

  test(
    'loginOffline autorisé après un logout, dans la fenêtre (amendement m4)',
    () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      await manager.wipeSession(); // logout ordinaire : la fenêtre survit
      expect(await dao.getSession(), isNull);

      final res = await manager.loginOffline(
        email: 'prof@ecole.cd',
        password: 'MotDePasse123',
      );
      expect(res.isRight(), isTrue);
      res.fold((_) {}, (snap) {
        expect(snap.isOffline, isTrue);
        expect(snap.session.user.id, 'u1');
      });
      // La session locale est rouverte pour ce compte.
      expect((await dao.getSession())?.userId, 'u1');
    },
  );

  test(
    'loginOffline refusé après logout si la fenêtre est dépassée (D-07/D-08)',
    () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000),
        'MotDePasse123',
      );
      await manager.wipeSession();

      clock += 2000; // au-delà de la borne refresh du dernier contact online
      final res = await manager.loginOffline(
        email: 'prof@ecole.cd',
        password: 'MotDePasse123',
      );
      expect(res.isLeft(), isTrue);
    },
  );

  test(
    'la révocation (D-09) brûle la fenêtre : loginOffline refusé ensuite',
    () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', userVersion: 1, refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      await manager.recordServerContact(
        observedUserVersion: 2,
        serverTimeMs: clock,
        observedUid: 'u1',
      );
      expect(await manager.evaluateRevocation(), isTrue);

      // Le compte reste « vu sur ce device » (D-01) mais sans fenêtre offline.
      expect((await dao.getUser('u1'))?.refreshExpiresAt, isNull);
      final res = await manager.loginOffline(
        email: 'prof@ecole.cd',
        password: 'MotDePasse123',
      );
      expect(res.isLeft(), isTrue);
    },
  );

  test(
    'loginOffline ne réutilise jamais les jetons d\'un autre compte (D-05)',
    () async {
      final manager = build();
      // A puis B se connectent online — la session/jetons résiduels sont à B.
      await manager.persistOnlineLogin(
        _session(uid: 'uA', refreshExpiresAt: clock + 1000000),
        'MotDePasseA',
      );
      final sessionB = AuthSession(
        accessToken: 'jwt-B',
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshToken: 'refresh-B',
        refreshExpiresAt: clock + 1000000,
        userVersion: 0,
        user: const AuthenticatedUser(
          id: 'uB',
          email: 'dir@ecole.cd',
          firstName: 'Blaise',
          lastName: 'Mwamba',
          role: 'DIRECTOR',
          schoolId: 'sch-1',
        ),
      );
      await manager.persistOnlineLogin(sessionB, 'MotDePasseB');
      when(
        () => tokenStorage.readAuthSession(),
      ).thenAnswer((_) async => sessionB);

      // A se reconnecte offline : snapshot sous SON identité, jetons de B purgés.
      final res = await manager.loginOffline(
        email: 'prof@ecole.cd',
        password: 'MotDePasseA',
      );
      expect(res.isRight(), isTrue);
      res.fold((_) {}, (snap) {
        expect(snap.session.user.id, 'uA');
        expect(snap.session.accessToken, isEmpty);
      });
      verify(() => tokenStorage.clearAuthSession()).called(1);
    },
  );

  test('applyRefresh ré-ancre la borne offline par utilisateur (m4)', () async {
    final manager = build();
    await manager.persistOnlineLogin(
      _session(uid: 'u1', refreshExpiresAt: clock + 1000),
      'MotDePasse123',
    );
    when(() => tokenStorage.updateTokens(any())).thenAnswer((_) async {});

    await manager.applyRefresh(
      _session(uid: 'u1', refreshExpiresAt: clock + 555555),
    );
    expect((await dao.getUser('u1'))?.refreshExpiresAt, clock + 555555);
  });

  test(
    'evaluateRevocation wipe sur userVersion divergent, épargne le user',
    () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', userVersion: 1, refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );

      // Le serveur annonce une nouvelle version (reset password) : révocation.
      await manager.recordServerContact(
        observedUserVersion: 2,
        serverTimeMs: clock,
        observedUid: 'u1',
      );
      final revoked = await manager.evaluateRevocation();
      expect(revoked, isTrue);

      // La session est wipée mais l'utilisateur (invariant D-01) reste.
      expect(await dao.getSession(), isNull);
      expect(await dao.getUser('u1'), isNotNull);
      verify(() => tokenStorage.clearAuthSession()).called(1);
    },
  );

  test('recordServerContact ignore une réponse partie sous le JWT d\'un autre '
      'compte (filtre d\'identité, revue adversariale)', () async {
    final manager = build();
    await manager.persistOnlineLogin(
      _session(uid: 'uB', userVersion: 2, refreshExpiresAt: clock + 1000000),
      'MotDePasseB',
    );
    final before = (await dao.getUser('uB'))!.lastServerSeenAt;

    clock += 5000;
    // Réponse tardive de l'utilisateur A (version 8 > baseline 2 de B) : ne
    // doit ni ré-ancrer la fraîcheur de B, ni déclencher sa révocation.
    await manager.recordServerContact(
      observedUserVersion: 8,
      serverTimeMs: clock,
      observedUid: 'uA',
    );
    expect((await dao.getUser('uB'))!.lastServerSeenAt, before);
    expect(await manager.evaluateRevocation(), isFalse);
    expect(await dao.getSession(), isNotNull);
  });

  test('applyRefresh ne ressuscite pas les jetons après un wipe '
      '(anti-résurrection, revue adversariale)', () async {
    final manager = build();
    await manager.persistOnlineLogin(
      _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
      'MotDePasse123',
    );
    await manager.wipeSession(revokeOfflineWindow: true); // révocation D-09

    // Le refresh était en vol pendant le wipe : sa réponse tardive ne doit
    // RIEN réécrire (sinon le révoqué redémarre `authenticated` avec le
    // guardian désarmé).
    await manager.applyRefresh(
      _session(uid: 'u1', refreshExpiresAt: clock + 2000000),
    );
    verifyNever(() => tokenStorage.updateTokens(any()));
    expect((await dao.getUser('u1'))?.refreshExpiresAt, isNull);
  });

  test('evaluateRevocation ne wipe pas si userVersion identique', () async {
    final manager = build();
    await manager.persistOnlineLogin(
      _session(uid: 'u1', userVersion: 3, refreshExpiresAt: clock + 1000000),
      'MotDePasse123',
    );
    await manager.recordServerContact(
      observedUserVersion: 3,
      serverTimeMs: clock,
      observedUid: 'u1',
    );
    expect(await manager.evaluateRevocation(), isFalse);
    expect(await dao.getSession(), isNotNull);
  });

  test(
    'CurrentUserContext alimenté au login online et vidé au wipe (D-05)',
    () async {
      final ctx = CurrentUserContext();
      final manager = AuthSessionManager(
        tokenStorage: tokenStorage,
        authLocalDao: dao,
        verifier: const PasswordVerifierService(),
        currentUser: ctx,
        now: () => clock,
      );

      expect(ctx.uid, isNull);
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      expect(ctx.uid, 'u1'); // estampillage prêt pour les écritures offline

      await manager.wipeSession();
      expect(ctx.uid, isNull); // plus d'auteur après wipe/logout
    },
  );

  test('primeCurrentUser restaure l\'uid au cold-start (fix revue)', () {
    final ctx = CurrentUserContext();
    final manager = AuthSessionManager(
      tokenStorage: tokenStorage,
      authLocalDao: dao,
      verifier: const PasswordVerifierService(),
      currentUser: ctx,
      now: () => clock,
    );
    manager.primeCurrentUser('u42');
    expect(ctx.uid, 'u42');
    manager.primeCurrentUser(''); // uid vide (session héritée) → pas d'auteur
    expect(ctx.uid, isNull);
  });

  test('freshness dégrade avec le temps sans contact serveur (D-08)', () async {
    final manager = build();
    await manager.persistOnlineLogin(
      _session(uid: 'u1', refreshExpiresAt: clock + 1000000000),
      'MotDePasse123',
    );

    // J+10 (> J7) sans contact serveur → WARNING.
    clock += const Duration(days: 10).inMilliseconds;
    final warn = await manager.evaluateFreshness();
    expect(warn!.mode, SessionMode.warning);

    // J+25 (> J21) → READ_ONLY.
    clock += const Duration(days: 15).inMilliseconds;
    final ro = await manager.evaluateFreshness();
    expect(ro!.mode, SessionMode.readOnly);
  });
}
