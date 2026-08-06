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
      now: () => 1000,
    );
  });

  tearDown(() async => db.close());

  void sessionOf({required String role, String schoolId = 'school-1'}) {
    when(
      () => authLocalDao.getSessionUser(),
    ).thenAnswer((_) async => _user(role: role, schoolId: schoolId));
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

    // Rien ne doit rester derrière lui, pas même la trace de l'école effacée :
    // sans quoi le profil suivant croirait la tablette déjà à jour.
    test('ne laisse aucune école mémorisée', () async {
      await syncMeta.setCursor(
        kEditiqueCacheSchoolResource,
        cursor: 'school-1',
        syncedAt: 1,
      );
      sessionOf(role: 'PARENT');

      await guard.onSessionOpened();

      expect(await syncMeta.getCursor(kEditiqueCacheSchoolResource), isNull);
    });
  });

  // Vider l'index sans rembobiner le curseur n'efface pas un cache : le delta
  // est monotone, le cycle suivant demanderait « ce qui a changé depuis », le
  // serveur répondrait « rien », et le catalogue resterait vide jusqu'à ce que
  // l'établissement scelle une pièce neuve.
  group('rembobinage du delta', () {
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

    test('un profil sans droit rembobine le curseur', () async {
      await seedCursors();
      sessionOf(role: 'TEACHER');

      await guard.onSessionOpened();

      expect(
        await syncMeta.getCursor(editiqueDocumentsCursorKey('school-1')),
        isNull,
      );
    });

    // Toutes les écoles, pas seulement l'entrante : la purge efface aussi les
    // pièces de la sortante, et lui laisser son curseur ferait rater, à un
    // éventuel retour, tout ce qui existait avant.
    test('un changement d école rembobine les deux', () async {
      await seedCursors();
      await syncMeta.setCursor(
        kEditiqueCacheSchoolResource,
        cursor: 'school-1',
        syncedAt: 1,
      );
      sessionOf(role: 'SECRETARY', schoolId: 'school-2');

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

    // Le pendant indispensable : une reconnexion ordinaire ne doit RIEN
    // retélécharger. Un rembobinage inconditionnel serait aussi coûteux que
    // l'absence de rembobinage serait amputante.
    test('une reconnexion ordinaire ne rembobine rien', () async {
      await seedCursors();
      await syncMeta.setCursor(
        kEditiqueCacheSchoolResource,
        cursor: 'school-1',
        syncedAt: 1,
      );
      sessionOf(role: 'ACCOUNTANT');

      await guard.onSessionOpened();

      expect(
        await syncMeta.getCursor(editiqueDocumentsCursorKey('school-1')),
        'op-42',
      );
    });

    // La clé mémorisant l'école vit dans la même table et commence par un
    // préfixe voisin : l'effacement des curseurs ne doit pas l'emporter, sans
    // quoi chaque ouverture croirait à une réaffectation.
    test('la trace de l école n est pas emportée par le rembobinage', () async {
      await seedCursors();
      sessionOf(role: 'DIRECTOR', schoolId: 'school-9');

      await guard.onSessionOpened();

      expect(
        await syncMeta.getCursor(kEditiqueCacheSchoolResource),
        'school-9',
      );
    });
  });

  group('réaffectation de tablette', () {
    // RG-012-21 : les pièces de l'établissement précédent n'ont plus rien à
    // faire ici.
    test('un changement d école efface le cache', () async {
      await syncMeta.setCursor(
        kEditiqueCacheSchoolResource,
        cursor: 'school-1',
        syncedAt: 1,
      );
      sessionOf(role: 'SECRETARY', schoolId: 'school-2');

      expect(await guard.onSessionOpened(), isTrue);
      verify(() => cache.purgeAll()).called(1);
      expect(
        await syncMeta.getCursor(kEditiqueCacheSchoolResource),
        'school-2',
      );
    });

    // Une déconnexion ordinaire ne doit RIEN coûter : faire retélécharger au
    // guichet ce qu'il détenait la veille viderait le cache de son intérêt.
    test('une reconnexion dans la même école ne touche à rien', () async {
      await syncMeta.setCursor(
        kEditiqueCacheSchoolResource,
        cursor: 'school-1',
        syncedAt: 1,
      );
      sessionOf(role: 'ACCOUNTANT');

      expect(await guard.onSessionOpened(), isFalse);
      verifyNever(() => cache.purgeAll());
    });

    // Première session d'un profil autorisé : rien à effacer, mais l'école se
    // mémorise — sans elle, le prochain changement serait indétectable.
    test('une première session mémorise l école sans rien effacer', () async {
      sessionOf(role: 'DIRECTOR', schoolId: 'school-9');

      expect(await guard.onSessionOpened(), isFalse);
      verifyNever(() => cache.purgeAll());
      expect(
        await syncMeta.getCursor(kEditiqueCacheSchoolResource),
        'school-9',
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
