import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/datasources/editique_remote_data_source.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/data/mappers/editique_document_mapper.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';

/// Coordinateur : pré-garde de connectivité, appel réseau, délégation du mapping
/// (octets → document, exception → `Failure`). Aucune logique de format ici.
///
/// ## Les deux verbes, et ce qui les sépare
///
/// **Émettre** garde sa pré-garde de connectivité et son verdict incertain :
/// rien de ce chemin ne change. **Restituer** ne la traverse pas — servir une
/// pièce que la tablette détient déjà n'a aucune raison d'exiger un réseau.
///
/// ## Qui remplit le cache
///
/// Ce fichier, et lui seul, en V1 : il n'existe aucun pull de métadonnées
/// (lot L3.4). Toute réponse portant des octets scellés — une émission réussie
/// **comme** un re-téléchargement — y dépose sa copie. C'est la moitié du lot
/// qu'il est le plus facile d'oublier : câbler la lecture sans l'écriture donne
/// un cache qui reste vide à jamais, sans qu'un seul test devienne rouge.
///
/// La mise en cache est **best-effort et silencieuse**. Elle ne peut ni faire
/// échouer une émission, ni la retarder d'un verdict : une pièce qu'on n'a pas
/// su cacher a quand même été produite, et c'est elle que l'appelant attend.
/// Un `null` rendu par le cache est une issue normale — c'est notamment ce que
/// rend tout relevé ou quitus, que le cache refuse par construction.
class EditiqueRepositoryImpl implements EditiqueRepository {
  final EditiqueRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;
  final Map<String, dynamic> requiredAuth;

  /// Cache de restitution. Alimenté par chaque réponse scellée, interrogé en
  /// premier par [restitute].
  final EditiqueDocumentCache cache;

  /// École et compte courants — la provenance et la portée de lecture d'une
  /// entrée de cache. Lu au moment de l'écriture, jamais mémorisé.
  final CurrentUserContext currentUser;

  const EditiqueRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
    required this.requiredAuth,
    required this.cache,
    required this.currentUser,
  });

  @override
  Future<Either<Failure, EditiqueDocument>> emitEnrollmentAttestation({
    required String enrollmentId,
    String? studentId,
    String? academicYearId,
  }) {
    return _emit(
      EditiqueDocumentType.enrollmentAttestation,
      () => remoteDataSource.emitEnrollmentAttestation(
        requiredAuth,
        enrollmentId,
      ),
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> emitNotePerception({
    required String studentId,
    required String academicYearId,
  }) {
    return _emit(
      EditiqueDocumentType.notePerception,
      () => remoteDataSource.emitNotePerception(
        requiredAuth,
        studentId,
        academicYearId,
      ),
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> emitPaymentReceipt({
    required String paymentId,
    String? studentId,
    String? academicYearId,
  }) {
    return _emit(
      EditiqueDocumentType.paymentReceipt,
      () => remoteDataSource.emitPaymentReceipt(requiredAuth, paymentId),
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> emitAccountStatement({
    required String studentId,
    required String academicYearId,
  }) {
    return _emit(
      EditiqueDocumentType.accountStatement,
      () => remoteDataSource.emitAccountStatement(
        requiredAuth,
        studentId,
        academicYearId,
      ),
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> emitFinancialClearance({
    required String studentId,
    required String academicYearId,
  }) {
    return _emit(
      EditiqueDocumentType.financialClearance,
      () => remoteDataSource.emitFinancialClearance(
        requiredAuth,
        studentId,
        academicYearId,
      ),
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> restitute({
    required EditiqueDocumentType type,
    String? documentId,
    String? documentNumber,
    String? studentId,
    String? academicYearId,
  }) async {
    if (!type.isArchived) {
      throw ArgumentError.value(
        type,
        'type',
        'Pièce non archivée : elle est recalculée à chaque demande, il n\'y a '
            'rien à restituer',
      );
    }

    final id = _blankToNull(documentId);
    final number = _blankToNull(documentNumber);
    if (id == null && number == null) {
      throw ArgumentError(
        'Restitution sans identifiant ni numéro : rien ne désigne la pièce',
      );
    }

    final cached = await _readCached(type, id: id, number: number);
    if (cached != null) return Right(cached);

    // Pas de copie locale. Le re-téléchargement exige l'identifiant d'archive :
    // le serveur n'expose aucune recherche par numéro, et l'inventer serait
    // promettre une route qui n'existe pas.
    // Ces deux échecs sont fabriqués **ici**, pas par le serveur : ils ne
    // portent donc aucun message. La présentation affiche le message d'une
    // `Failure` sous le libellé « Motif renvoyé par le serveur »
    // (`EditiqueServerDetail`) — y glisser une phrase écrite par le client
    // mentirait sur son origine, et court-circuiterait `AppLocalizations`.
    // L'anatomie d'erreur dit déjà la famille ; c'est à elle de parler.
    if (id == null) return const Left(NotFoundFailure());

    if (!await connectivityService.isOnline()) {
      return const Left(NetworkFailure());
    }

    try {
      final downloaded = EditiqueDocumentMapper.map(
        await remoteDataSource.downloadDocument(requiredAuth, id),
        type,
      );
      // Le re-téléchargement remplit le cache autant que l'émission : sans
      // cela, une pièce scellée par une AUTRE tablette resterait hors de
      // portée hors ligne pour toujours.
      await _cacheQuietly(
        downloaded,
        type: type,
        documentId: id,
        studentId: studentId,
        academicYearId: academicYearId,
      );
      return downloaded;
    } on DioException catch (e) {
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Contrairement à une émission, il n'y a **aucune** incertitude à lever
      // ici : un GET ne produit rien et ne consomme aucun numéro. L'échec se
      // réessaie librement, ce que `UncertainOutcomeFailure` interdirait.
      return const Left(ServerFailure());
    }
  }

  /// Dépose une pièce scellée dans le cache, sans jamais peser sur l'issue de
  /// l'appel qui l'a rapportée.
  ///
  /// Attendu plutôt que lancé en arrière-plan : la copie coûte quelques
  /// dizaines de millisecondes après un aller-retour réseau qui en a coûté
  /// cent fois plus, et une écriture qu'on n'attend pas est une écriture qu'on
  /// ne peut ni observer ni éprouver.
  ///
  /// Ne fait rien sur un échec, sur une pièce non archivée (le cache les
  /// refuse par construction), ou quand l'école courante est inconnue — une
  /// entrée doit pouvoir être relue, et la portée de lecture est l'école.
  Future<void> _cacheQuietly(
    Either<Failure, EditiqueDocument> result, {
    required EditiqueDocumentType type,
    String? studentId,
    String? academicYearId,
    String? documentId,
  }) async {
    if (!type.isArchived) return;
    final document = result.fold<EditiqueDocument?>((_) => null, (d) => d);
    if (document == null) return;

    final schoolId = currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return;

    try {
      await cache.put(
        docType: type.code,
        documentId: document.documentId ?? documentId,
        documentNumber: document.documentNumber,
        studentId: studentId,
        academicYearId: academicYearId,
        schoolId: schoolId,
        ownerUid: currentUser.uid ?? '',
        bytes: document.bytes,
      );
    } catch (_) {
      // Disque plein, index refusé, magasin en panne : la pièce vient d'être
      // servie à l'appelant, c'est tout ce qui compte.
    }
  }

  /// Copie locale de la pièce, ou `null` si elle n'est pas en cache — ou si le
  /// cache n'a pas su répondre, ce qui revient au même pour l'appelant.
  Future<EditiqueDocument?> _readCached(
    EditiqueDocumentType type, {
    required String? id,
    required String? number,
  }) async {
    try {
      var bytes = id == null ? null : await cache.readByDocumentId(id);

      if (bytes == null && number != null) {
        final schoolId = currentUser.schoolId;
        // Le numéro n'est unique que **par école** : le chercher sans elle
        // rendrait la pièce d'un autre établissement.
        if (schoolId != null && schoolId.isNotEmpty) {
          bytes = await cache.readByDocumentNumber(
            schoolId: schoolId,
            documentNumber: number,
          );
        }
      }
      if (bytes == null) return null;

      return EditiqueDocument(
        type: type,
        bytes: bytes,
        fileName: '${number ?? type.code.toLowerCase()}.pdf',
        documentNumber: number,
        documentId: id,
      );
    } catch (_) {
      // Une lecture de cache ne remonte jamais d'erreur : au pire elle n'a rien
      // trouvé, et la pièce se retélécharge.
      return null;
    }
  }

  Future<Either<Failure, EditiqueDocument>> _emit(
    EditiqueDocumentType type,
    Future<HttpResponse<Uint8List>> Function() call, {
    String? studentId,
    String? academicYearId,
  }) async {
    // Pré-garde de connectivité : sans elle, un appel hors ligne coûte le
    // `connectTimeout` de la requête PDF **plus** celui du mint proactif de
    // jeton déclenché par l'intercepteur d'authentification quand l'access
    // token est vide — de l'ordre de 12 s d'attente pour une issue connue
    // d'avance. La radio « up » ne prouve pas la joignabilité (cf.
    // [ConnectivityService]) : c'est une pré-garde, pas un verdict, et l'appel
    // reste seul juge quand elle passe.
    if (!await connectivityService.isOnline()) {
      return const Left(
        NetworkFailure('Aucune connexion : le document ne peut pas être émis.'),
      );
    }

    try {
      final emitted = EditiqueDocumentMapper.map(await call(), type);
      await _cacheQuietly(
        emitted,
        type: type,
        studentId: studentId,
        academicYearId: academicYearId,
      );
      return emitted;
    } on DioException catch (e) {
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Le sort de la requête est indéterminé (erreur locale survenue à un
      // moment inconnu du cycle). Sur une pièce non archivée, un numéro a
      // peut-être déjà été consommé — c'est le cas qui interdit le rejeu
      // automatique.
      return const Left(
        UncertainOutcomeFailure("L'émission du document a échoué."),
      );
    }
  }

  static String? _blankToNull(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value;
}
