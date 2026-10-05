import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_read.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_blobs.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_write_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/student_photo_change_bus.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_fetcher.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_push_request.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';

class StudentPhotoRepositoryImpl implements StudentPhotoRepository {
  final StudentPhotoDao _photos;
  final StudentPhotoWriteDao _writer;
  final StudentPhotoBlobs _blobs;
  final StudentPhotoFetcher _fetcher;
  final StudentPhotoChangeBus _bus;
  final CurrentUserContext _currentUser;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const StudentPhotoRepositoryImpl({
    required StudentPhotoDao photos,
    required StudentPhotoWriteDao writer,
    required StudentPhotoBlobs blobs,
    required StudentPhotoFetcher fetcher,
    required StudentPhotoChangeBus bus,
    required CurrentUserContext currentUser,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _photos = photos,
       _writer = writer,
       _blobs = blobs,
       _fetcher = fetcher,
       _bus = bus,
       _currentUser = currentUser,
       _syncEngine = syncEngine,
       _now = now;

  @override
  Stream<Set<String>> get changes => _bus.stream;

  @override
  Future<Either<Failure, Map<String, StudentPhotoRef>>> loadIndex() async {
    try {
      final rows = await _photos.forSchool(_currentUser.schoolId ?? '');
      return Right({for (final row in rows) row.studentId: row.toRef()});
    } catch (e) {
      return Left(StorageFailure('Lecture des photos : $e'));
    }
  }

  @override
  Future<Either<Failure, StudentPhotoBytes?>> bytesOf(
    StudentPhotoRef ref,
    StudentPhotoSize size, {
    bool exact = false,
  }) async {
    try {
      final row = await _photos.find(ref.studentId);
      if (row == null) return const Right(null);
      return Right(await _bytesOf(row, size, exact: exact));
    } catch (e) {
      return Left(StorageFailure('Lecture de la photo : $e'));
    }
  }

  Future<StudentPhotoBytes?> _bytesOf(
    StudentPhotoLocalModel row,
    StudentPhotoSize size, {
    required bool exact,
  }) async {
    final pendingSha = row.pendingSha256;
    if (row.pendingOp == StudentPhotoOp.delete) return null;
    if (row.pendingOp == StudentPhotoOp.put && pendingSha != null) {
      // Le geste en attente est toujours le carré 512 px envoyé.
      final read = await _blobs.readPending(row.studentId, pendingSha);
      return read is BlobFound
          ? StudentPhotoBytes(read.blob.bytes, StudentPhotoSize.full)
          : null;
    }
    final sha = row.sha256;
    if (sha == null) return null;

    final wanted = await _cached(row, size, sha);
    if (wanted != null) return StudentPhotoBytes(wanted, size);
    // La vignette peut se tirer de la grande copie ; l'inverse se verrait.
    if (size == StudentPhotoSize.thumb) {
      final larger = await _cached(row, StudentPhotoSize.full, sha);
      if (larger != null) {
        return StudentPhotoBytes(larger, StudentPhotoSize.full);
      }
    }
    try {
      return StudentPhotoBytes(
        await _fetcher.fetch(
          row.studentId,
          sha,
          size,
          served: row.servedShaOf(size),
        ),
        size,
      );
    } catch (_) {
      if (exact || size == StudentPhotoSize.thumb) return null;
      // Hors ligne : la vignette, faute de mieux, plutôt que les initiales.
      final thumb = await _cached(row, StudentPhotoSize.thumb, sha);
      return thumb == null
          ? null
          : StudentPhotoBytes(thumb, StudentPhotoSize.thumb);
    }
  }

  Future<Uint8List?> _cached(
    StudentPhotoLocalModel row,
    StudentPhotoSize size,
    String sha,
  ) async {
    if (row.cachedShaOf(size) != sha) return null;
    final read = await _blobs.readCache(row.studentId, size);
    if (read is BlobFound) return read.blob.bytes;
    if (read is BlobGone) {
      await _photos.markCached(row.studentId, size, sha256: null);
    }
    return null;
  }

  @override
  Future<Either<Failure, Unit>> savePhoto({
    required String studentId,
    required Uint8List jpeg,
    required DateTime takenAt,
  }) async {
    final sha = await sha256Hex(jpeg);
    // Les octets d'abord : la ligne ne doit jamais désigner une photo absente.
    if (!await _blobs.writePending(studentId, sha, jpeg)) {
      return const Left(StorageFailure('Photo non scellée sur la tablette'));
    }
    return _record(
      studentId,
      (authorId) => StudentPhotoPushRequest(
        studentId: studentId,
        op: StudentPhotoOp.put,
        at: wireInstant(takenAt),
        sha256: sha,
        authorId: authorId,
      ),
      onFailure: () => _blobs.deletePending(studentId, sha),
    );
  }

  @override
  Future<Either<Failure, Unit>> removePhoto({
    required String studentId,
    required DateTime removedAt,
  }) => _record(
    studentId,
    (authorId) => StudentPhotoPushRequest(
      studentId: studentId,
      op: StudentPhotoOp.delete,
      at: wireInstant(removedAt),
      authorId: authorId,
    ),
  );

  Future<Either<Failure, Unit>> _record(
    String studentId,
    StudentPhotoPushRequest Function(String authorId) build, {
    Future<void> Function()? onFailure,
  }) async {
    final schoolId = _currentUser.schoolId ?? '';
    final authorId = _currentUser.uid;
    if (schoolId.isEmpty || authorId == null) {
      await onFailure?.call();
      return const Left(AuthFailure('Aucune session pour la photo'));
    }
    final request = build(authorId);
    final StudentPhotoLocalModel? before;
    try {
      before = await _writer.record(request, schoolId: schoolId, nowMs: _now());
    } catch (e) {
      await onFailure?.call();
      return Left(StorageFailure('Écriture de la photo : $e'));
    }
    // Les octets du geste remplacé ne partiront plus.
    final replacedSha = before?.pendingSha256;
    if (before?.pendingOp == StudentPhotoOp.put &&
        replacedSha != null &&
        replacedSha != request.sha256) {
      await _blobs.deletePending(studentId, replacedSha);
    }
    _bus.emit({studentId});
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
    return const Right(unit);
  }

  /// Un instant tel qu'il part sur le fil : UTC, à la milliseconde — le
  /// serveur compare des dates, pas des chaînes de microsecondes.
  static String wireInstant(DateTime at) => DateTime.fromMillisecondsSinceEpoch(
    at.millisecondsSinceEpoch,
    isUtc: true,
  ).toIso8601String();
}
