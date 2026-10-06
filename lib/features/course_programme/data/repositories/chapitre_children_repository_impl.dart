import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_children_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/programme_local_write.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_transfer_api.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/ressource_draft.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/chapitre_children_repository.dart';

/// Les notes de séance et les ressources, écrites sur la tablette ; le fichier
/// d'un document se relit dans le magasin chiffré, ou se télécharge à la
/// demande et s'y garde.
class ChapitreChildrenRepositoryImpl implements ChapitreChildrenRepository {
  final ChapitreChildrenWriteDao _writer;
  final ProgrammeBlobs _blobs;
  final ProgrammeTransferApi _transfer;
  final IdGenerator _ids;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const ChapitreChildrenRepositoryImpl({
    required ChapitreChildrenWriteDao writer,
    required ProgrammeBlobs blobs,
    required ProgrammeTransferApi transfer,
    required IdGenerator ids,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _writer = writer,
       _blobs = blobs,
       _transfer = transfer,
       _ids = ids,
       _currentUser = currentUser,
       _extras = extras,
       _syncEngine = syncEngine,
       _now = now;

  @override
  Future<Either<Failure, Unit>> addNote(Chapitre chapitre, String texte) {
    final nowMs = _now();
    return writeProgrammeLocally(
      _syncEngine,
      () => _writer.addNote(
        ChapitreNote(
          id: _ids.newId(),
          chapitreId: chapitre.id,
          texte: texte.trim(),
          ecriteLe: DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
        ),
        coursId: chapitre.coursId,
        schoolId: _currentUser.schoolId,
        authorId: _currentUser.uid,
        nowMs: nowMs,
      ),
      unit,
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteNote(String noteId) =>
      writeProgrammeLocally(
        _syncEngine,
        () => _writer.deleteNote(
          noteId,
          schoolId: _currentUser.schoolId,
          authorId: _currentUser.uid,
          nowMs: _now(),
        ),
        unit,
      );

  @override
  Future<Either<Failure, Unit>> addRessource(
    Chapitre chapitre,
    RessourceDraft draft,
  ) => writeProgrammeLocally(_syncEngine, () async {
    final kept = await _writer.addRessource(
      ChapitreRessource(
        id: draft.id,
        chapitreId: chapitre.id,
        type: draft.type,
        nom: draft.nom.trim(),
        url: draft.url?.trim(),
        reference: draft.reference?.trim(),
        taille: draft.bytes?.length,
        sha256: draft.sha256,
        mimeType: draft.mimeType,
        fileName: draft.fileName,
      ),
      coursId: chapitre.coursId,
      bytes: draft.bytes,
      schoolId: _currentUser.schoolId,
      authorId: _currentUser.uid,
      nowMs: _now(),
    );
    if (!kept) throw StateError('Fichier non scellé');
  }, unit);

  @override
  Future<Either<Failure, Unit>> deleteRessource(String ressourceId) =>
      writeProgrammeLocally(
        _syncEngine,
        () => _writer.deleteRessource(
          ressourceId,
          schoolId: _currentUser.schoolId,
          authorId: _currentUser.uid,
          nowMs: _now(),
        ),
        unit,
      );

  @override
  Future<Either<Failure, Uint8List>> openDocument(
    ChapitreRessource ressource,
  ) async {
    switch (await _blobs.read(ressource.id)) {
      case BlobFound(:final blob):
        return Right(blob.bytes);
      case BlobUnavailable():
        return const Left(StorageFailure('Magasin indisponible'));
      case BlobGone():
        return _download(ressource);
    }
  }

  /// Télécharge le fichier d'une ressource que le serveur a, le confronte à
  /// son empreinte, puis le garde : la prochaine ouverture se fera hors ligne.
  Future<Either<Failure, Uint8List>> _download(
    ChapitreRessource ressource,
  ) async {
    final Uint8List bytes;
    try {
      bytes = await _transfer.download(
        _extras,
        chapitreId: ressource.chapitreId,
        ressourceId: ressource.id,
      );
    } on DioException catch (e) {
      return Left(ApiErrorParser.failureOf(e));
    }
    final expected = ressource.sha256;
    if (expected != null && await sha256Hex(bytes) != expected) {
      return const Left(IntegrityFailure());
    }
    await _blobs.guarded(() => _blobs.write(ressource.id, bytes));
    return Right(bytes);
  }
}
