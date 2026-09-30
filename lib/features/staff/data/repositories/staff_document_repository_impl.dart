import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_directory.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_mapping.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_transfer_api.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_content.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_dossier_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_document_repository.dart';

/// Les pièces du dossier : métadonnées dans la base, octets chiffrés dans le
/// magasin du module, les deux sous l'identifiant de la pièce.
class StaffDocumentRepositoryImpl implements StaffDocumentRepository {
  final StaffDocumentDao _documents;
  final StaffDocumentTypeDao _types;
  final StaffDocumentWriteDao _writer;
  final StaffDocumentSyncDao _sync;
  final StaffDocumentTransferApi _api;
  final EncryptedBlobStore _store;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;
  final Map<String, dynamic> _extras;
  final SyncEngine? _syncEngine;
  final DateTime Function() _now;

  const StaffDocumentRepositoryImpl({
    required StaffDocumentDao documents,
    required StaffDocumentTypeDao types,
    required StaffDocumentWriteDao writer,
    required StaffDocumentSyncDao sync,
    required StaffDocumentTransferApi api,
    required EncryptedBlobStore store,
    required CurrentUserContext currentUser,
    required IdGenerator ids,
    required Map<String, dynamic> extras,
    SyncEngine? syncEngine,
    DateTime Function() now = DateTime.now,
  }) : _documents = documents,
       _types = types,
       _writer = writer,
       _sync = sync,
       _api = api,
       _store = store,
       _currentUser = currentUser,
       _ids = ids,
       _extras = extras,
       _syncEngine = syncEngine,
       _now = now;

  @override
  Future<Either<Failure, StaffDossierSnapshot>> dossierOf(
    String staffMemberId,
  ) async {
    try {
      final schoolId = _currentUser.schoolId ?? '';
      return Right(
        StaffDossierSnapshot(
          types: [
            for (final type in await _types.forSchool(schoolId))
              type.toEntity(),
          ],
          documents: [
            for (final row in await _documents.forMember(staffMemberId))
              row.toEntity(),
          ],
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Lecture du dossier : $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addDocument(
    String staffMemberId,
    String rawCode,
    CapturedDocument document,
  ) async {
    final schoolId = _currentUser.schoolId ?? '';
    final authorId = _currentUser.uid;
    if (schoolId.isEmpty || authorId == null) {
      return const Left(AuthFailure('Aucune session pour verser'));
    }
    final id = _ids.newId();
    // Les octets d'abord, scellés et promus : la ligne ne doit jamais désigner
    // une pièce absente. Une panne entre les deux laisse un fichier orphelin,
    // chiffré — jamais une ligne sans octets. Aucun balayage ne le reprend
    // encore : le magasin est partagé par les écoles du poste, et un balayage
    // qui ne verrait que la base ouverte effacerait les pièces en attente des
    // autres.
    final stored = await _store.stage(id: id, bytes: document.bytes);
    if (stored == null || !await _store.commit(id)) {
      await _store.discard(id);
      return const Left(StorageFailure('Pièce non scellée sur la tablette'));
    }
    final now = _now();
    try {
      await _writer.add(
        request: StaffDocumentUploadDto(
          id: id,
          staffMemberId: staffMemberId,
          code: rawCode,
          source: switch (document.source) {
            DocumentCaptureSource.scan => StaffDocumentSource.scan.wire,
            DocumentCaptureSource.import => StaffDocumentSource.import.wire,
          },
          capturedAt: document.capturedAt.toUtc().toIso8601String(),
          fileName: document.fileName,
          mimeType: document.mimeType.value,
          sizeBytes: document.bytes.length,
          sha256: document.sha256Hex,
          authorId: authorId,
        ),
        schoolId: schoolId,
        nowMs: now.millisecondsSinceEpoch,
      );
    } catch (e) {
      await _store.delete(id);
      return Left(StorageFailure('Écriture de la pièce : $e'));
    }
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
    return const Right(unit);
  }

  @override
  Future<Either<Failure, StaffDocumentContent>> open(
    StaffDocument document,
  ) async {
    // Un identifiant venu du serveur qui ne ferait pas un nom de fichier sûr
    // ne touche ni au magasin ni à la route.
    if (!BlobDirectory.isSafeId(document.id)) {
      return const Left(NotFoundFailure('Pièce inconnue'));
    }
    try {
      return await _open(document);
    } catch (e) {
      return Left(StorageFailure('Ouverture de la pièce : $e'));
    }
  }

  Future<Either<Failure, StaffDocumentContent>> _open(
    StaffDocument document,
  ) async {
    final row = await _sync.find(document.id);
    if (row == null) return const Left(NotFoundFailure('Pièce inconnue'));
    StaffDocumentContent content(Uint8List bytes) => StaffDocumentContent(
      bytes: bytes,
      mimeType: document.mimeType,
      fileName: document.fileName ?? document.id,
    );

    final local = await _store.read(document.id);
    if (local case BlobFound(:final blob)) return Right(content(blob.bytes));
    try {
      final bytes = await _api.download(_extras, document.id);
      // L'empreinte rangée fait foi : des octets qui ne la portent pas ne
      // sont ni montrés ni gardés.
      if (await sha256Hex(bytes) != row.sha256) {
        return const Left(IntegrityFailure());
      }
      if (await _store.stage(id: document.id, bytes: bytes) != null) {
        await _store.commit(document.id);
      }
      return Right(content(bytes));
    } on DioException catch (e) {
      return Left(_failureOf(e));
    }
  }

  static Failure _failureOf(DioException e) => switch (e.response?.statusCode) {
    null => const NetworkFailure(),
    401 || 403 => const UnauthorizedFailure(),
    404 || 410 => const NotFoundFailure(),
    _ => const ServerFailure(),
  };
}
