import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/pre_enrollments_school_guard.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';

import '../../offline_full_db.dart';

/// La seconde moitié du défaut de scope école : `ref_pre_enrollments` n'a pas
/// de colonne `school_id`, donc scoper le curseur ne suffit pas — les candidats
/// de l'établissement précédent restent lisibles par le suivant.
///
/// ⚠️ L'invariant que chaque test ci-dessous protège : une purge SANS
/// rembobinage rendrait ces préinscriptions définitivement inatteignables
/// (cette table est la seule source d'amorçage d'un brouillon PRE, il n'y a
/// plus aucun repli GET serveur, et le curseur keyset est en avance sur elles).
void main() {
  late Database db;
  late SyncMetaDao syncMeta;
  late EnrollmentSeedDao seedDao;
  late CurrentUserContext currentUser;

  PreEnrollmentsSchoolGuard guardFor(String? schoolId) {
    currentUser.set('u1', schoolId: schoolId);
    return PreEnrollmentsSchoolGuard(
      seedDao: seedDao,
      syncMetaDao: syncMeta,
      currentUser: currentUser,
      now: () => 5000,
    );
  }

  Future<void> seedPreEnrollment(String id) =>
      db.insert('ref_pre_enrollments', {
        'id': id,
        'first_name': 'Awa',
        'last_name': 'Mbala',
        'updated_at': 100,
        'synced_at': 100,
      });

  Future<int> countPreEnrollments() async =>
      (await db.query('ref_pre_enrollments')).length;

  setUp(() async {
    db = await openFullOfflineDb();
    syncMeta = SyncMetaDao(db);
    seedDao = EnrollmentSeedDao(db);
    currentUser = CurrentUserContext();
  });

  tearDown(() async {
    await db.close();
  });

  group('PreEnrollmentsSchoolGuard.onSessionOpened', () {
    test(
      'marqueur ABSENT : école inconnue, donc on purge — et on pose le repère',
      () async {
        // ⚠️ L'attente s'est INVERSÉE, et c'est le correctif d'un défaut réel.
        //
        // Ce test figeait « première session = rien à comparer = rien à
        // purger ». Mais rien n'amorce ce marqueur : la première session est
        // aussi celle qui suit la mise à jour, sur une tablette qui a pu être
        // réaffectée AVANT que cette garde n'existe. Elle adoptait alors le
        // vivier trouvé sur le disque, définitivement — `ref_pre_enrollments`
        // n'a pas de colonne `school_id`, donc plus rien ensuite ne distingue
        // les candidats de l'école A de ceux de B.
        //
        // Un vivier non attribuable est exactement le cas « fermé par défaut »
        // que la classe défend. Le prix est un rebootstrap unique par tablette.
        await seedPreEnrollment('pre-1');
        await syncMeta.setCursor(
          preEnrollmentsCursorKey('school-1'),
          cursor: 'WM-S1',
          syncedAt: 1,
        );

        final purged = await guardFor('school-1').onSessionOpened();

        expect(purged, isTrue);
        expect(await countPreEnrollments(), 0);
        // Purger sans rembobiner rendrait ces lignes inatteignables : le
        // serveur répondrait « rien de neuf » sur une table vide.
        expect(
          await syncMeta.getCursor(preEnrollmentsCursorKey('school-1')),
          isNull,
        );
        expect(
          await syncMeta.getCursor(kPreEnrollmentsSchoolResource),
          'school-1',
        );
      },
    );

    test(
      'et le rebootstrap ne se répète pas : la session suivante ne purge plus',
      () async {
        // Sans le repère posé au passage, le vivier serait vidé à CHAQUE
        // ouverture — le parc entier retéléchargerait ses préinscriptions tous
        // les matins.
        await guardFor('school-1').onSessionOpened();
        await seedPreEnrollment('pre-1');

        final purgedAgain = await guardFor('school-1').onSessionOpened();

        expect(purgedAgain, isFalse);
        expect(await countPreEnrollments(), 1);
      },
    );

    test('installation NEUVE : la purge ne coûte rien', () async {
      // Le contre-poids du test ci-dessus : sur une base vierge, « purger par
      // défaut » n'efface rien et ne rembobine rien qui existe.
      final purged = await guardFor('school-1').onSessionOpened();

      expect(purged, isTrue);
      expect(await countPreEnrollments(), 0);
      expect(
        await syncMeta.getCursor(kPreEnrollmentsSchoolResource),
        'school-1',
      );
    });

    test(
      'même école : le guichet garde le vivier qu\'il détenait la veille',
      () async {
        await syncMeta.setCursor(
          kPreEnrollmentsSchoolResource,
          cursor: 'school-1',
          syncedAt: 1,
        );
        await seedPreEnrollment('pre-1');
        await syncMeta.setCursor(
          preEnrollmentsCursorKey('school-1'),
          cursor: 'WM-S1',
          syncedAt: 1,
        );

        final purged = await guardFor('school-1').onSessionOpened();

        expect(purged, isFalse);
        expect(await countPreEnrollments(), 1);
        // Le curseur SURVIT : une reconnexion ordinaire ne doit rien faire
        // retélécharger.
        expect(
          await syncMeta.getCursor(preEnrollmentsCursorKey('school-1')),
          'WM-S1',
        );
      },
    );

    test('école changée : vivier vidé ET flux rembobiné', () async {
      await syncMeta.setCursor(
        kPreEnrollmentsSchoolResource,
        cursor: 'school-1',
        syncedAt: 1,
      );
      await seedPreEnrollment('pre-1');
      await syncMeta.setCursor(
        preEnrollmentsCursorKey('school-1'),
        cursor: 'WM-S1',
        syncedAt: 1,
      );

      final purged = await guardFor('school-2').onSessionOpened();

      expect(purged, isTrue);
      expect(await countPreEnrollments(), 0);
      expect(
        await syncMeta.getCursor(preEnrollmentsCursorKey('school-1')),
        isNull,
      );
      expect(
        await syncMeta.getCursor(kPreEnrollmentsSchoolResource),
        'school-2',
      );
    });

    test('le rembobinage vise TOUTES les écoles, pas la seule sortante : '
        'une tablette qui revient doit rebootstraper', () async {
      // La tablette a servi les écoles 1 et 2, puis revient à la 1. Si son
      // curseur `@school-1` survivait à la purge, le serveur répondrait « rien
      // de neuf » sur un vivier vide — et les préinscriptions de l'école 1
      // seraient perdues jusqu'à ce que le portail parent en produise d'autres.
      await syncMeta.setCursor(
        kPreEnrollmentsSchoolResource,
        cursor: 'school-2',
        syncedAt: 1,
      );
      await syncMeta.setCursor(
        preEnrollmentsCursorKey('school-1'),
        cursor: 'WM-S1',
        syncedAt: 1,
      );
      await syncMeta.setCursor(
        preEnrollmentsCursorKey('school-2'),
        cursor: 'WM-S2',
        syncedAt: 1,
      );

      await guardFor('school-1').onSessionOpened();

      expect(
        await syncMeta.getCursor(preEnrollmentsCursorKey('school-1')),
        isNull,
      );
      expect(
        await syncMeta.getCursor(preEnrollmentsCursorKey('school-2')),
        isNull,
      );
    });

    test('la clé plate héritée est balayée par le rembobinage', () async {
      // Elle n'est plus jamais relue, mais la laisser traîner serait de la
      // dette : `deleteCursorsOf` couvre la clé nue autant que ses variantes.
      await syncMeta.setCursor(
        kPreEnrollmentsSchoolResource,
        cursor: 'school-1',
        syncedAt: 1,
      );
      await syncMeta.setCursor(
        EnrollmentPullRepositoryImpl.preEnrollmentsResource,
        cursor: 'WM-HERITE',
        syncedAt: 1,
      );

      await guardFor('school-2').onSessionOpened();

      expect(
        await syncMeta.getCursor(
          EnrollmentPullRepositoryImpl.preEnrollmentsResource,
        ),
        isNull,
      );
    });

    test(
      'le marqueur d\'école SURVIT au rembobinage qu\'il déclenche',
      () async {
        // Si `deleteCursorsOf` l'emportait, la garde oublierait à chaque purge
        // l'école qu'elle vient d'installer et re-purgerait à la session
        // suivante — un vivier vidé à chaque ouverture, indéfiniment.
        await syncMeta.setCursor(
          kPreEnrollmentsSchoolResource,
          cursor: 'school-1',
          syncedAt: 1,
        );
        await seedPreEnrollment('pre-1');

        await guardFor('school-2').onSessionOpened();
        // Deuxième ouverture, même école : plus rien ne doit être purgé.
        await seedPreEnrollment('pre-2');
        final purgedAgain = await guardFor('school-2').onSessionOpened();

        expect(purgedAgain, isFalse);
        expect(await countPreEnrollments(), 1);
      },
    );

    test('école inconnue : ni purge ni oubli du repère', () async {
      await syncMeta.setCursor(
        kPreEnrollmentsSchoolResource,
        cursor: 'school-1',
        syncedAt: 1,
      );
      await seedPreEnrollment('pre-1');

      final purged = await guardFor(null).onSessionOpened();

      expect(purged, isFalse);
      expect(await countPreEnrollments(), 1);
      // Réécrire le repère ferait passer le prochain changement d'école pour
      // une continuité.
      expect(
        await syncMeta.getCursor(kPreEnrollmentsSchoolResource),
        'school-1',
      );
    });

    test(
      'base illisible → ne lève pas, la session s\'ouvre quand même',
      () async {
        await db.close();

        expect(await guardFor('school-2').onSessionOpened(), isFalse);

        // Réouverture pour que le tearDown trouve une base fermable.
        db = await openFullOfflineDb();
      },
    );
  });

  test('la clé du marqueur est hors du préfixe du flux', () {
    // Garde-fou de nommage : `deleteCursorsOf` efface `<prefix>`, `<prefix>@…`
    // et `<prefix>:…`. Un marqueur nommé avec l'un de ces séparateurs se
    // ferait effacer par la purge qu'il déclenche.
    const prefix = EnrollmentPullRepositoryImpl.preEnrollmentsResource;
    expect(kPreEnrollmentsSchoolResource, isNot(prefix));
    expect(kPreEnrollmentsSchoolResource.startsWith('$prefix@'), isFalse);
    expect(kPreEnrollmentsSchoolResource.startsWith('$prefix:'), isFalse);
  });
}
