import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/find_cached_document_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/list_cached_documents_use_case.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _FixedAccess implements EditiqueCacheAccess {
  final bool entitled;

  const _FixedAccess(this.entitled);

  @override
  Future<bool> isEntitled() async => entitled;
}

const _entitled = _FixedAccess(true);

/// Ce que ces deux lectures rendent, et ce qu'elles refusent de trancher.
///
/// La liste rend **tout** ce que l'index sait de l'élève : trier à sa place
/// reviendrait à décider deux fois, et la seconde décision — aveugle au
/// contexte de la première — se trompait. Le geste appartient au résolveur
/// d'actions, dont `_findCached` exige déjà `hasBytes && !isCancelled` : c'est
/// LÀ qu'on empêche « Consulter » de s'allumer sur des octets absents.
///
/// La recherche unitaire, elle, garde un filtre : elle répond à une question
/// fermée (« que sait-on de CETTE pièce, qui change le geste ? »), et son
/// appelant n'a pas de liste où retrouver le contexte.
///
/// Les deux refusent en revanche la même chose : un profil sans droit, et une
/// école courante inconnue.
void main() {
  late Database db;
  late EditiqueCacheDao dao;
  late CurrentUserContext currentUser;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = EditiqueCacheDao(db);
    currentUser = CurrentUserContext()..set('u-1', schoolId: 'school-1');
  });

  tearDown(() async => db.close());

  Future<void> seed({
    required String id,
    required String documentId,
    required String docType,
    String? contentSha256,
    int emittedAt = 500,
    int? cancelledAt,
    String? cancellationReason,
  }) => dao.upsert(
    EditiqueCacheEntry(
      id: id,
      documentId: documentId,
      documentNumber: 'ETL-$docType-$id',
      docType: docType,
      studentId: 's-1',
      academicYearId: 'y-1',
      schoolId: 'school-1',
      sizeBytes: 1024,
      contentSha256: contentSha256,
      emittedAt: emittedAt,
      cancelledAt: cancelledAt,
      cancellationReason: cancellationReason,
      createdAt: 1000,
      lastAccessedAt: 1000,
    ),
  );

  test('la liste rend tout ce que l index sait de l élève', () async {
    await seed(
      id: 'tenue',
      documentId: 'doc-1',
      docType: 'RC',
      contentSha256: 'a' * 64,
    );
    await seed(id: 'connue', documentId: 'doc-2', docType: 'NP');

    final visible = await ListCachedDocumentsUseCase(
      dao,
      currentUser,
      _entitled,
    )(studentId: 's-1', academicYearId: 'y-1');

    // Y COMPRIS la pièce dont la tablette n'a que la connaissance : sans elle,
    // une pièce de remplacement resterait invisible au résolveur, et sa
    // devancière annulée s'annoncerait comme la dernière nouvelle du type.
    expect(visible.map((e) => e.id), containsAll(['tenue', 'connue']));
  });

  // L'ordre est celui du serveur — la plus récemment émise d'abord —, et c'est
  // ce sur quoi le résolveur s'appuie pour savoir laquelle est la dernière
  // nouvelle d'un type.
  test('la liste rend l ordre d émission décroissant', () async {
    await seed(
      id: 'ancienne',
      documentId: 'doc-1',
      docType: 'RC',
      contentSha256: 'a' * 64,
    );
    await seed(
      id: 'recente',
      documentId: 'doc-2',
      docType: 'RC',
      emittedAt: 9000,
    );

    final visible = await ListCachedDocumentsUseCase(
      dao,
      currentUser,
      _entitled,
    )(studentId: 's-1');

    expect(visible.map((e) => e.id), ['recente', 'ancienne']);
  });

  test('la recherche unitaire ignore une pièce seulement connue', () async {
    await seed(id: 'connue', documentId: 'doc-2', docType: 'RC');
    final find = FindCachedDocumentUseCase(dao, currentUser, _entitled);

    expect(await find(documentId: 'doc-2'), isNull);
    expect(await find(documentNumber: 'ETL-RC-connue'), isNull);
  });

  test('mais rend bien une pièce détenue', () async {
    await seed(
      id: 'tenue',
      documentId: 'doc-1',
      docType: 'RC',
      contentSha256: 'a' * 64,
    );
    final find = FindCachedDocumentUseCase(dao, currentUser, _entitled);

    expect((await find(documentId: 'doc-1'))?.id, 'tenue');
    expect((await find(documentNumber: 'ETL-RC-tenue'))?.id, 'tenue');
  });

  // Le cœur de la dette : une pièce retirée par l'école ne disparaît pas de ce
  // que la tablette sait. La masquer ferait retomber la ligne sur « Émettre »
  // sans jamais dire pourquoi la pièce d'hier n'a plus cours.
  group('une pièce annulée', () {
    test('remonte dans la liste, avec ses octets', () async {
      await seed(
        id: 'annulee',
        documentId: 'doc-1',
        docType: 'RC',
        contentSha256: 'a' * 64,
        cancelledAt: 1786013000000,
        cancellationReason: 'Erreur de montant',
      );

      final visible = await ListCachedDocumentsUseCase(
        dao,
        currentUser,
        _entitled,
      )(studentId: 's-1');

      expect(visible.map((e) => e.id), ['annulee']);
      expect(visible.single.isCancelled, isTrue);
      expect(visible.single.cancellationReason, 'Erreur de montant');
    });

    // Le motif vit dans l'index, pas dans le fichier : il survit donc à
    // l'éviction des octets, et c'est ce qui permet d'expliquer une pièce dont
    // la tablette n'a plus la copie.
    test('remonte encore une fois ses octets évincés', () async {
      await seed(
        id: 'annulee',
        documentId: 'doc-1',
        docType: 'RC',
        cancelledAt: 1786013000000,
        cancellationReason: 'Doublon',
      );

      final visible = await ListCachedDocumentsUseCase(
        dao,
        currentUser,
        _entitled,
      )(studentId: 's-1');

      expect(visible.map((e) => e.id), ['annulee']);
      expect(visible.single.hasBytes, isFalse);
      expect(visible.single.cancellationReason, 'Doublon');
    });

    test('remonte aussi à la recherche unitaire', () async {
      await seed(
        id: 'annulee',
        documentId: 'doc-1',
        docType: 'RC',
        cancelledAt: 1786013000000,
      );
      final find = FindCachedDocumentUseCase(dao, currentUser, _entitled);

      expect((await find(documentId: 'doc-1'))?.isCancelled, isTrue);
      expect((await find(documentNumber: 'ETL-RC-annulee'))?.isCancelled, true);
    });

    // La garde de profil ne se contourne pas par la porte de l'annulation : un
    // profil sans droit n'a pas à connaître l'inventaire, retiré ou non.
    test('reste invisible à un profil sans droit', () async {
      await seed(
        id: 'annulee',
        documentId: 'doc-1',
        docType: 'RC',
        contentSha256: 'a' * 64,
        cancelledAt: 1786013000000,
      );
      const refused = _FixedAccess(false);

      expect(
        await ListCachedDocumentsUseCase(dao, currentUser, refused)(
          studentId: 's-1',
        ),
        isEmpty,
      );
      expect(
        await FindCachedDocumentUseCase(dao, currentUser, refused)(
          documentId: 'doc-1',
        ),
        isNull,
      );
    });
  });

  // RG-012-4 : l'effacement d'ouverture de session traite le cas ordinaire,
  // mais entre deux ouvertures — un rôle rétrogradé par le serveur, une session
  // déjà ouverte — l'index survivrait à la perte du droit. Ces deux lectures
  // alimentent l'UI : elles doivent refuser d'elles-mêmes.
  test(
    'un profil sans droit ne voit rien de ce qui reste sur le disque',
    () async {
      await seed(
        id: 'tenue',
        documentId: 'doc-1',
        docType: 'RC',
        contentSha256: 'a' * 64,
      );
      const refused = _FixedAccess(false);

      expect(
        await ListCachedDocumentsUseCase(dao, currentUser, refused)(
          studentId: 's-1',
        ),
        isEmpty,
      );
      final find = FindCachedDocumentUseCase(dao, currentUser, refused);
      expect(await find(documentId: 'doc-1'), isNull);
      expect(await find(documentNumber: 'ETL-RC-tenue'), isNull);
    },
  );

  // La portée de lecture est l'école : sans elle, on ne lit rien plutôt que de
  // rendre la pièce d'un autre établissement.
  test('sans école courante, aucune des deux ne répond', () async {
    await seed(
      id: 'tenue',
      documentId: 'doc-1',
      docType: 'RC',
      contentSha256: 'a' * 64,
    );
    currentUser.clear();

    expect(
      await ListCachedDocumentsUseCase(dao, currentUser, _entitled)(
        studentId: 's-1',
      ),
      isEmpty,
    );
    expect(
      await FindCachedDocumentUseCase(dao, currentUser, _entitled)(
        documentNumber: 'ETL-RC-tenue',
      ),
      isNull,
    );
  });
}
