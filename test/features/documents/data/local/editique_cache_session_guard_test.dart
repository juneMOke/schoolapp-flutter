import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_models.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_session_guard.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/data/repositories/offline/editique_document_pull_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _MockCache extends Mock implements EditiqueDocumentCache {}

class _MockAuthLocalDao extends Mock implements AuthLocalDao {}

AuthLocalUserRecord _user({required String role, required String schoolId}) =>
    AuthLocalUserRecord(
      userId: 'u-1',
      email: 'agent@ecole.cd',
      firstName: 'Amina',
      lastName: 'Mbala',
      role: role,
      schoolId: schoolId,
      passwordVerifier: 'v',
      verifierSalt: 's',
      userVersion: 1,
      firstOnlineLoginAt: 0,
      lastServerSeenAt: 0,
    );

/// Ce qu'une ouverture de session décide du cache de pièces scellées.
void main() {
  late Database db;
  late SyncMetaDao syncMeta;
  late _MockCache cache;
  late _MockAuthLocalDao authLocalDao;
  late EditiqueCacheSessionGuard guard;

  setUp(() async {
    db = await openFullOfflineDb();
    syncMeta = SyncMetaDao(db);
    cache = _MockCache();
    authLocalDao = _MockAuthLocalDao();
    when(() => cache.purgeAll()).thenAnswer((_) async => 0);
    guard = EditiqueCacheSessionGuard(
      cache: cache,
      authLocalDao: authLocalDao,
      syncMetaDao: syncMeta,
    );
  });

  tearDown(() async => db.close());

  void sessionOf({required String role, String schoolId = 'school-1'}) {
    when(
      () => authLocalDao.getSessionUser(),
    ).thenAnswer((_) async => _user(role: role, schoolId: schoolId));
  }

  Future<void> seedCursors() async {
    await syncMeta.setCursor(
      editiqueDocumentsCursorKey('school-1'),
      cursor: 'op-42',
      syncedAt: 1,
    );
    await syncMeta.setCursor(
      editiqueDocumentsCursorKey('school-2'),
      cursor: 'op-7',
      syncedAt: 1,
    );
  }

  group('profil sans droit', () {
    // RG-012-4 : le cache réside sur les tablettes d'administration. Ce qu'elle
    // contenait ne doit pas rester à la portée de qui n'y a pas droit.
    test('efface tout ce que la tablette détenait', () async {
      sessionOf(role: 'TEACHER');

      expect(await guard.onSessionOpened(), isTrue);
      verify(() => cache.purgeAll()).called(1);
    });

    // Le cas que la liste blanche existe pour couvrir : au démarrage à froid, le
    // rôle retombe sur chaîne vide. Une garde écrite « tout sauf enseignant »
    // aurait laissé passer.
    test('un rôle vide compte comme un rôle sans droit', () async {
      sessionOf(role: '');

      expect(await guard.onSessionOpened(), isTrue);
      verify(() => cache.purgeAll()).called(1);
    });

    test('une session absente aussi', () async {
      when(() => authLocalDao.getSessionUser()).thenAnswer((_) async => null);

      expect(await guard.onSessionOpened(), isTrue);
      verify(() => cache.purgeAll()).called(1);
    });

    // Vider l'index sans rembobiner le curseur n'efface pas un cache : le delta
    // est monotone, le cycle suivant demanderait « ce qui a changé depuis », le
    // serveur répondrait « rien », et le catalogue resterait vide jusqu'à ce que
    // l'établissement scelle une pièce neuve.
    //
    // Toutes les écoles, pas seulement la courante : la purge a effacé leurs
    // pièces à toutes.
    test('rembobine le curseur de CHAQUE école', () async {
      await seedCursors();
      sessionOf(role: 'TEACHER');

      await guard.onSessionOpened();

      expect(
        await syncMeta.getCursor(editiqueDocumentsCursorKey('school-1')),
        isNull,
      );
      expect(
        await syncMeta.getCursor(editiqueDocumentsCursorKey('school-2')),
        isNull,
      );
    });
  });

  // Les écoles d'un poste coexistent (MULTI_ECOLE_PLAN.md §10.1) : un chef qui
  // bascule entre ses établissements ne doit pas retrouver, à chaque retour, un
  // cache vide à retélécharger.
  group('profil autorisé', () {
    test('une autre école que la précédente ne purge plus rien', () async {
      await seedCursors();
      sessionOf(role: 'DIRECTOR', schoolId: 'school-2');
      expect(await guard.onSessionOpened(), isFalse);

      sessionOf(role: 'DIRECTOR', schoolId: 'school-1');
      expect(await guard.onSessionOpened(), isFalse);

      verifyNever(() => cache.purgeAll());
      expect(
        await syncMeta.getCursor(editiqueDocumentsCursorKey('school-1')),
        'op-42',
      );
    });

    // Une déconnexion ordinaire ne doit RIEN coûter : faire retélécharger au
    // guichet ce qu'il détenait la veille viderait le cache de son intérêt.
    test('une reconnexion dans la même école ne touche à rien', () async {
      await seedCursors();
      sessionOf(role: 'ACCOUNTANT');

      expect(await guard.onSessionOpened(), isFalse);
      verifyNever(() => cache.purgeAll());
      expect(
        await syncMeta.getCursor(editiqueDocumentsCursorKey('school-1')),
        'op-42',
      );
    });
  });

  // Une hygiène de disque qui échoue ne doit pas empêcher un agent d'ouvrir sa
  // session.
  test('une base illisible ne fait pas échouer l ouverture', () async {
    when(() => authLocalDao.getSessionUser()).thenThrow(StateError('base'));

    expect(await guard.onSessionOpened(), isFalse);
  });

  group('liste blanche', () {
    test('les six profils internes ont droit au cache', () {
      for (final role in const [
        'SUPER_ADMIN',
        'DIRECTOR',
        'SECRETARY',
        'ACCOUNTANT',
        'ACADEMIC_ADMIN',
        'DISCIPLINE_SUPERVISOR',
      ]) {
        expect(EditiqueCacheEntitlement.isAllowed(role), isTrue, reason: role);
      }
    });

    test('les trois profils externes ne l ont pas', () {
      for (final role in const ['TEACHER', 'PARENT', 'STUDENT']) {
        expect(EditiqueCacheEntitlement.isAllowed(role), isFalse, reason: role);
      }
    });

    // Ce qu'une liste blanche refuse : tout ce qu'elle ne nomme pas, y compris
    // l'inconnu, l'absent et le vide.
    test('refuse ce qu elle ne nomme pas', () {
      for (final role in const [null, '', '   ', 'ROLE_INVENTE', 'ADMIN']) {
        expect(
          EditiqueCacheEntitlement.isAllowed(role),
          isFalse,
          reason: '$role',
        );
      }
    });

    // Rien ne garantit la casse côté client : `UserModel.fromJson` fait un cast
    // brut. Sans normalisation, un changement de sérialisation ouvrirait ou
    // fermerait la garde en silence.
    test('normalise la casse et les espaces', () {
      expect(EditiqueCacheEntitlement.isAllowed(' secretary '), isTrue);
      expect(EditiqueCacheEntitlement.isAllowed('Accountant'), isTrue);
    });
  });
}
