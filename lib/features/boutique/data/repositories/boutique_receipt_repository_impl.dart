import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sync_api.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_receipt_repository.dart';
import 'package:school_app_flutter/features/documents/data/mappers/editique_document_mapper.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

/// Réclame au serveur le reçu de vente scellé, et consigne ce qu'il annonce.
///
/// Emprunte au module `documents` son mappeur et son classeur d'échecs plutôt
/// que d'en écrire des jumeaux : une pièce d'éditique se valide de la même façon
/// d'où qu'elle vienne, et deux décodeurs finiraient par diverger sur ce qui
/// compte — la garde `%PDF`, le `content-type`, la lecture tolérante des
/// en-têtes. L'imprimerie est partagée ; ce que l'invariant I-4 interdit, c'est
/// que la scolarité lise les ventes, pas que la caisse lise un PDF.
class BoutiqueReceiptRepositoryImpl implements BoutiqueReceiptRepository {
  final BoutiqueSyncApi _api;
  final BoutiqueSaleWriteDao _dao;
  final ConnectivityService _connectivity;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  const BoutiqueReceiptRepositoryImpl({
    required BoutiqueSyncApi api,
    required BoutiqueSaleWriteDao dao,
    required ConnectivityService connectivity,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _connectivity = connectivity,
       _requiredAuth = requiredAuth,
       _now = now;

  @override
  Future<Either<Failure, EditiqueDocument>> claimSaleReceipt(
    String saleId,
  ) async {
    // Pré-garde de connectivité, reprise de l'éditique : sans elle, une
    // réclamation hors ligne coûte le `connectTimeout` de la requête PDF **plus**
    // celui du mint proactif de jeton, soit de l'ordre de 12 s d'attente pour une
    // issue connue d'avance. La radio « up » ne prouve pas la joignabilité :
    // c'est une pré-garde, pas un verdict, et l'appel reste seul juge quand elle
    // passe.
    if (!await _connectivity.isOnline()) {
      return const Left(
        NetworkFailure(
          'Aucune connexion : le reçu scellé ne peut pas être réclamé.',
        ),
      );
    }

    try {
      final mapped = EditiqueDocumentMapper.map(
        await _api.emitSaleReceipt(_requiredAuth, saleId),
        EditiqueDocumentType.saleReceipt,
      );

      return await mapped.fold<Future<Either<Failure, EditiqueDocument>>>(
        (failure) async => Left(failure),
        (document) async {
          await _consignQuietly(saleId, document);
          return Right(document);
        },
      );
    } on DioException catch (e) {
      // Le mappeur d'éditique rend au passage le message du serveur, qu'un
      // intercepteur global écrase sinon par une constante.
      //
      // ⚠️ Il peut classer un délai dépassé en `UncertainOutcomeFailure`, ce qui
      // est la bonne prudence pour un relevé ou un quitus — qui brûlent un
      // numéro avant de rendre leurs octets. **Le RV n'est pas dans ce cas** :
      // il est archivé et idempotent sous verrou, donc toute reprise est sans
      // danger, et c'est `EditiqueDocumentType.saleReceipt.isReplayable` qui le
      // dit à la couche qui offre « Réessayer ».
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure('La réclamation du reçu a échoué : $e'));
    }
  }

  /// Écrit en local ce que le serveur vient d'annoncer, **sans pouvoir faire
  /// perdre la pièce**.
  ///
  /// L'échec est avalé délibérément : les octets sont en main et le payeur
  /// attend son papier. Refuser la pièce parce qu'une écriture SQLite a bronché
  /// serait absurde — et la route étant idempotente, la réclamation se refait
  /// sans rien abîmer.
  ///
  /// ⚠️ Le numéro et l'identifiant sont traités **séparément** : le second est
  /// annoncé par `X-Document-Id`, le premier ne voyage que dans un
  /// `Content-Disposition` hors contrat. Obtenir la pièce sans son numéro est un
  /// cas normal, et le DAO n'écrase alors rien.
  Future<void> _consignQuietly(String saleId, EditiqueDocument document) async {
    try {
      await _dao.applyClaimedReceipt(
        saleId,
        nowMs: _now(),
        documentId: document.documentId,
        documentNumber: document.documentNumber,
      );
    } catch (_) {
      // Rien à dire au guichet : la pièce est là, et c'est ce qu'il a demandé.
    }
  }
}
