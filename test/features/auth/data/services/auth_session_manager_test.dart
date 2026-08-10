import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/storage/shared_document_cache.dart';
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
  List<String> permissions = const <String>[],
}) => AuthSession(
  accessToken: 'jwt',
  tokenType: 'Bearer',
  expiresIn: 3600,
  refreshToken: 'refresh',
  refreshExpiresAt: refreshExpiresAt,
  userVersion: userVersion,
  permissions: permissions,
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
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => null);
    when(() => tokenStorage.readParkedRefresh()).thenAnswer((_) async => null);
    when(
      () => tokenStorage.parkRefreshToken(
        uid: any(named: 'uid'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => tokenStorage.clearParkedRefresh()).thenAnswer((_) async {});
    when(() => tokenStorage.saveAuthSession(any())).thenAnswer((_) async {});
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

  group('consigne du refresh token (V1.1)', () {
    test('le logout consigne le refresh sous l\'uid du PROFIL token store '
        '(le vrai propriétaire du jeton)', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      when(
        () => tokenStorage.readAuthSession(),
      ).thenAnswer((_) async => _session(uid: 'u1'));
      when(
        () => tokenStorage.readRefreshToken(),
      ).thenAnswer((_) async => 'refresh-A');

      await manager.wipeSession(); // logout ordinaire

      verify(
        () =>
            tokenStorage.parkRefreshToken(uid: 'u1', refreshToken: 'refresh-A'),
      ).called(1);
      verify(() => tokenStorage.clearAuthSession()).called(1);
    });

    test('mismatch profil token store ≠ session DB → PAS de parcage (F1 : '
        'jamais transférer un crédentiel entre comptes)', () async {
      final manager = build();
      // Session DB = u1 ; jetons actifs = profil de uX (état de crash).
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      when(
        () => tokenStorage.readAuthSession(),
      ).thenAnswer((_) async => _session(uid: 'uX'));
      when(
        () => tokenStorage.readRefreshToken(),
      ).thenAnswer((_) async => 'refresh-X');

      await manager.wipeSession();

      verifyNever(
        () => tokenStorage.parkRefreshToken(
          uid: any(named: 'uid'),
          refreshToken: any(named: 'refreshToken'),
        ),
      );
    });

    test('borne offline du propriétaire expirée → PAS de parcage (F3 : un '
        'jeton mort n\'écrase pas une consigne valide)', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000),
        'MotDePasse123',
      );
      when(
        () => tokenStorage.readAuthSession(),
      ).thenAnswer((_) async => _session(uid: 'u1'));
      when(
        () => tokenStorage.readRefreshToken(),
      ).thenAnswer((_) async => 'refresh-mort');

      clock += 2000; // borne dépassée (chemin AuthRefreshExpired → wipe)
      await manager.wipeSession();

      verifyNever(
        () => tokenStorage.parkRefreshToken(
          uid: any(named: 'uid'),
          refreshToken: any(named: 'refreshToken'),
        ),
      );
    });

    test('révocation : consigne brûlée même si la session DB diverge du '
        'profil token store (F2)', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', userVersion: 1, refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      // Jetons actifs du compte uX ; sa consigne existe aussi.
      when(
        () => tokenStorage.readAuthSession(),
      ).thenAnswer((_) async => _session(uid: 'uX'));
      when(() => tokenStorage.readParkedRefresh()).thenAnswer(
        (_) async =>
            const ParkedRefreshToken(uid: 'uX', refreshToken: 'refresh-X'),
      );
      await manager.recordServerContact(
        observedUserVersion: 2,
        serverTimeMs: clock,
        observedUid: 'u1',
      );

      expect(await manager.evaluateRevocation(), isTrue);
      verify(() => tokenStorage.clearParkedRefresh()).called(1);
    });

    test('branche réuse : refresh actif absent + consigne du même compte → '
        'réinjection (F4 : gate et consigne ne peuvent pas échouer '
        'ensemble)', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      // État partiel post-crash : access présent, refresh ABSENT.
      final partial = AuthSession(
        accessToken: 'jwt-partiel',
        tokenType: 'Bearer',
        expiresIn: 3600,
        userVersion: 0,
        user: _session(uid: 'u1').user,
      );
      when(
        () => tokenStorage.readAuthSession(),
      ).thenAnswer((_) async => partial);
      when(() => tokenStorage.readParkedRefresh()).thenAnswer(
        (_) async =>
            const ParkedRefreshToken(uid: 'u1', refreshToken: 'refresh-A'),
      );

      final res = await manager.loginOffline(
        email: 'prof@ecole.cd',
        password: 'MotDePasse123',
      );

      expect(res.isRight(), isTrue);
      res.fold((_) {}, (snap) {
        expect(snap.session.refreshToken, 'refresh-A');
        expect(snap.session.accessToken, 'jwt-partiel');
      });
      verify(() => tokenStorage.clearParkedRefresh()).called(1);
    });

    test('login offline du même compte déconsigne : snapshot complet réécrit '
        '(profil + refresh) → resync silencieuse possible', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      await manager.wipeSession(); // logout
      when(() => tokenStorage.readParkedRefresh()).thenAnswer(
        (_) async =>
            const ParkedRefreshToken(uid: 'u1', refreshToken: 'refresh-A'),
      );

      final res = await manager.loginOffline(
        email: 'prof@ecole.cd',
        password: 'MotDePasse123',
      );

      expect(res.isRight(), isTrue);
      res.fold((_) {}, (snap) {
        expect(snap.session.refreshToken, 'refresh-A');
        expect(snap.session.accessToken, isEmpty);
        expect(snap.session.user.id, 'u1');
      });
      final saved =
          verify(
                () => tokenStorage.saveAuthSession(captureAny()),
              ).captured.single
              as AuthSession;
      expect(saved.refreshToken, 'refresh-A');
      expect(saved.user.id, 'u1'); // estampille authUid restaurée
      verify(() => tokenStorage.clearParkedRefresh()).called(1);
    });

    test('la consigne d\'un AUTRE compte n\'est pas déconsignée', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      await manager.wipeSession();
      when(() => tokenStorage.readParkedRefresh()).thenAnswer(
        (_) async =>
            const ParkedRefreshToken(uid: 'uB', refreshToken: 'refresh-B'),
      );

      final res = await manager.loginOffline(
        email: 'prof@ecole.cd',
        password: 'MotDePasse123',
      );

      expect(res.isRight(), isTrue);
      res.fold((_) {}, (snap) => expect(snap.session.refreshToken, isNull));
      verifyNever(() => tokenStorage.saveAuthSession(any()));
      // Elle attend son propriétaire : jamais détruite par le login d'un autre.
      verifyNever(() => tokenStorage.clearParkedRefresh());
    });

    test('la révocation (D-09) brûle la consigne du compte', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', userVersion: 1, refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      when(() => tokenStorage.readParkedRefresh()).thenAnswer(
        (_) async =>
            const ParkedRefreshToken(uid: 'u1', refreshToken: 'refresh-A'),
      );
      await manager.recordServerContact(
        observedUserVersion: 2,
        serverTimeMs: clock,
        observedUid: 'u1',
      );

      expect(await manager.evaluateRevocation(), isTrue);
      verify(() => tokenStorage.clearParkedRefresh()).called(1);
    });

    test(
      'identité croisée : les jetons actifs de B sont consignés sous SON uid',
      () async {
        final manager = build();
        await manager.persistOnlineLogin(
          _session(uid: 'uA', refreshExpiresAt: clock + 1000000),
          'MotDePasseA',
        );
        // Jetons résiduels de B dans le token store.
        when(() => tokenStorage.readAuthSession()).thenAnswer(
          (_) async => _session(uid: 'uB', refreshExpiresAt: clock + 1000000),
        );

        final res = await manager.loginOffline(
          email: 'prof@ecole.cd',
          password: 'MotDePasseA',
        );

        expect(res.isRight(), isTrue);
        verify(
          () =>
              tokenStorage.parkRefreshToken(uid: 'uB', refreshToken: 'refresh'),
        ).called(1);
        verify(() => tokenStorage.clearAuthSession()).called(1);
      },
    );

    test('un login online purge SA propre consigne (jetons frais)', () async {
      when(() => tokenStorage.readParkedRefresh()).thenAnswer(
        (_) async =>
            const ParkedRefreshToken(uid: 'u1', refreshToken: 'refresh-old'),
      );
      final manager = build();
      await manager.persistOnlineLogin(
        _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
        'MotDePasse123',
      );
      verify(() => tokenStorage.clearParkedRefresh()).called(1);
    });
  });

  group('canAuthenticate (sonde de la boucle de synchro, V1.1)', () {
    test('sans access ni refresh → false', () async {
      expect(await build().canAuthenticate(), isFalse);
    });

    test(
      'refresh actif présent → true (le refresh mintera un access)',
      () async {
        when(
          () => tokenStorage.readRefreshToken(),
        ).thenAnswer((_) async => 'refresh-A');
        expect(await build().canAuthenticate(), isTrue);
      },
    );

    test('access non vide → true', () async {
      when(
        () => tokenStorage.readAuthSession(),
      ).thenAnswer((_) async => _session(uid: 'u1'));
      expect(await build().canAuthenticate(), isTrue);
    });

    test('access EXPIRÉ sans refresh → false (revue F7)', () async {
      final expired = AuthSession(
        accessToken: 'jwt-vieux',
        tokenType: 'Bearer',
        expiresIn: 3600,
        accessExpiresAt: clock - 1000,
        userVersion: 0,
        user: _session(uid: 'u1').user,
      );
      when(
        () => tokenStorage.readAuthSession(),
      ).thenAnswer((_) async => expired);
      expect(await build().canAuthenticate(), isFalse);
    });

    test('refresh présent mais borne EXPIRÉE → false (revue F7)', () async {
      final stale = AuthSession(
        accessToken: '',
        tokenType: 'Bearer',
        expiresIn: 0,
        refreshToken: 'refresh-mort',
        refreshExpiresAt: clock - 1000,
        userVersion: 0,
        user: _session(uid: 'u1').user,
      );
      when(() => tokenStorage.readAuthSession()).thenAnswer((_) async => stale);
      expect(await build().canAuthenticate(), isFalse);
    });
  });

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

  // ADR-012 D-7 : les pièces partagées vivent EN CLAIR dans le cache de l'app,
  // hors de la base chiffrée. Elles doivent partir avec la session.
  test('le wipe purge les pièces partagées en clair', () async {
    final tmp = await Directory.systemTemp.createTemp('eteelo-wipe-share-');
    addTearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });
    final shareDir = Directory('${tmp.path}/share');
    await shareDir.create(recursive: true);
    final receipt = File('${shareDir.path}/ETL-RC-2526-000212.pdf');
    await receipt.writeAsString('%PDF');

    final manager = AuthSessionManager(
      tokenStorage: tokenStorage,
      authLocalDao: dao,
      verifier: const PasswordVerifierService(),
      sharedDocumentCache: SharedDocumentCache(
        temporaryDirectory: () async => tmp,
      ),
      now: () => clock,
    );

    await manager.wipeSession();

    expect(await receipt.exists(), isFalse);
  });

  // Fermer la session prime sur nettoyer un cache : un échec d'entrée-sortie ne
  // doit jamais empêcher une déconnexion ou une révocation d'aboutir.
  test('le wipe aboutit même si la purge du cache échoue', () async {
    final manager = AuthSessionManager(
      tokenStorage: tokenStorage,
      authLocalDao: dao,
      verifier: const PasswordVerifierService(),
      sharedDocumentCache: SharedDocumentCache(
        temporaryDirectory: () async =>
            throw const FileSystemException('cache indisponible'),
      ),
      now: () => clock,
    );

    await expectLater(manager.wipeSession(), completes);
  });

  // ── Permissions (ADR-014 §4) ───────────────────────────────────────────────
  // Elles ne descendent qu'au login et au refresh. La copie de session (secure
  // storage) meurt au logout ; c'est la copie durable par compte qui doit
  // permettre à un login OFFLINE de rouvrir la session avec des droits.
  group('permissions', () {
    test('persistOnlineLogin écrit la copie durable du compte', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(
          uid: 'u1',
          refreshExpiresAt: clock + 1000000,
          permissions: const ['attendance.read', 'classroom.read'],
        ),
        'MotDePasse123',
      );

      expect((await dao.getUser('u1'))?.permissions, <String>[
        'attendance.read',
        'classroom.read',
      ]);
    });

    test('applyRefresh met à jour la copie durable', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(
          uid: 'u1',
          refreshExpiresAt: clock + 1000,
          permissions: const ['attendance.read', 'finance.write'],
        ),
        'MotDePasse123',
      );
      when(() => tokenStorage.updateTokens(any())).thenAnswer((_) async {});

      await manager.applyRefresh(
        _session(
          uid: 'u1',
          refreshExpiresAt: clock + 555555,
          permissions: const ['attendance.read'],
        ),
      );

      expect((await dao.getUser('u1'))?.permissions, <String>[
        'attendance.read',
      ]);
    });

    test('applyRefresh propage un RETRAIT total de droits', () async {
      final manager = build();
      await manager.persistOnlineLogin(
        _session(
          uid: 'u1',
          refreshExpiresAt: clock + 1000,
          permissions: const ['attendance.read'],
        ),
        'MotDePasse123',
      );
      when(() => tokenStorage.updateTokens(any())).thenAnswer((_) async {});

      await manager.applyRefresh(
        _session(uid: 'u1', refreshExpiresAt: clock + 555555),
      );

      expect((await dao.getUser('u1'))?.permissions, isEmpty);
    });

    test(
      'loginOffline après logout rouvre la session AVEC les droits',
      () async {
        final manager = build();
        await manager.persistOnlineLogin(
          _session(
            uid: 'u1',
            refreshExpiresAt: clock + 1000000,
            permissions: const ['attendance.read', 'classroom.read'],
          ),
          'MotDePasse123',
        );
        await manager.wipeSession(); // logout : la copie de session est effacée
        when(() => tokenStorage.readParkedRefresh()).thenAnswer(
          (_) async =>
              const ParkedRefreshToken(uid: 'u1', refreshToken: 'refresh-A'),
        );

        final res = await manager.loginOffline(
          email: 'prof@ecole.cd',
          password: 'MotDePasse123',
        );

        res.fold((f) => fail('login offline refusé : $f'), (snap) {
          expect(snap.session.permissions, <String>[
            'attendance.read',
            'classroom.read',
          ]);
        });
      },
    );

    test(
      'loginOffline sur session réutilisée : la copie durable fait foi',
      () async {
        final manager = build();
        await manager.persistOnlineLogin(
          _session(
            uid: 'u1',
            refreshExpiresAt: clock + 1000000,
            permissions: const ['attendance.read'],
          ),
          'MotDePasse123',
        );
        // Jetons de CE compte encore actifs en storage, mais porteurs d'un
        // ensemble périmé : la copie durable (dernier contact serveur) gagne.
        when(() => tokenStorage.readAuthSession()).thenAnswer(
          (_) async => _session(
            uid: 'u1',
            permissions: const ['finance.write', 'attendance.read'],
          ),
        );

        final res = await manager.loginOffline(
          email: 'prof@ecole.cd',
          password: 'MotDePasse123',
        );

        res.fold((f) => fail('login offline refusé : $f'), (snap) {
          expect(snap.session.permissions, <String>['attendance.read']);
        });
      },
    );

    test(
      'compte migré (jamais revu online) → aucun droit hors ligne',
      () async {
        // Après la migration v24 la colonne est NULL : fail-closed jusqu'au
        // prochain contact serveur.
        final manager = build();
        await manager.persistOnlineLogin(
          _session(uid: 'u1', refreshExpiresAt: clock + 1000000),
          'MotDePasse123',
        );
        await db.update('auth_local_user', {'permissions': null});

        final res = await manager.loginOffline(
          email: 'prof@ecole.cd',
          password: 'MotDePasse123',
        );

        res.fold((f) => fail('login offline refusé : $f'), (snap) {
          expect(snap.session.permissions, isEmpty);
        });
      },
    );
  });
}
