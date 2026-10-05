import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_blobs.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/student_photo_change_bus.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_api.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_fetcher.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

/// Clé de routage du flux `student.photos` côté client.
const String kStudentPhotosResource = 'student_photos';

/// La descente du flux `student.photos`, puis le ménage des copies : une
/// photo retirée efface la sienne, une photo neuve voit sa vignette
/// préchargée — en arrière-plan, pour qu'une liste s'ouvre déjà illustrée.
class StudentPhotoPuller {
  final StudentPhotoApi _api;
  final KeysetPullRunner _runner;
  final StudentPhotoDao _photos;
  final StudentPhotoBlobs _blobs;
  final StudentPhotoFetcher _fetcher;
  final StudentPhotoChangeBus _bus;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  const StudentPhotoPuller({
    required StudentPhotoApi api,
    required KeysetPullRunner runner,
    required StudentPhotoDao photos,
    required StudentPhotoBlobs blobs,
    required StudentPhotoFetcher fetcher,
    required StudentPhotoChangeBus bus,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _runner = runner,
       _photos = photos,
       _blobs = blobs,
       _fetcher = fetcher,
       _bus = bus,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  /// Page de 500 : une ligne pèse une centaine d'octets, une école de mille
  /// élèves descend en deux pages.
  static const int pageLimit = 500;

  /// Curseur scopé par école : une tablette réaffectée ne reprend pas la
  /// seconde école là où la première s'était arrêtée.
  static String cursorKey(String schoolId) =>
      '$kStudentPhotosResource@$schoolId';

  Future<Either<Failure, KeysetPullResult>> pull() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return const Left(ServerFailure('Aucune école courante'));
    }
    final result = await _runner.run(
      cursorKey: cursorKey(schoolId),
      label: kStudentPhotosResource,
      fetch: (cursor) => _api.pull(_requiredAuth, cursor, pageLimit),
      apply: (items, nowMs) =>
          _photos.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
    );
    if (result case Right(:final value) when !value.notModified) {
      await _dropStaleCaches(schoolId);
      _bus.emitAll();
      unawaited(prefetchThumbnails(schoolId));
    }
    return result;
  }

  Future<void> _dropStaleCaches(String schoolId) async {
    for (final row in await _photos.staleCaches(schoolId)) {
      await _blobs.deleteCaches(row.studentId);
      for (final size in StudentPhotoSize.values) {
        await _photos.markCached(row.studentId, size, sha256: null);
      }
    }
  }

  /// Précharge les vignettes manquantes, une à une. S'arrête au premier échec
  /// de transport : hors ligne, la suite échouerait de même ; les vignettes
  /// restantes viendront à l'affichage ou au prochain pull.
  Future<void> prefetchThumbnails(String schoolId) async {
    try {
      for (final row in await _photos.missingThumbnails(schoolId)) {
        final sha = row.sha256;
        if (sha == null) continue;
        await _fetcher.fetch(row.studentId, sha, StudentPhotoSize.thumb);
        _bus.emit({row.studentId});
      }
    } catch (_) {
      // Un préchargement raté n'est pas une panne de synchronisation.
    }
  }
}
