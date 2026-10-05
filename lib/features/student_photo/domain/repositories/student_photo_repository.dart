import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

/// La photo des élèves : lecture 100 % locale, écriture 100 % outbox.
abstract class StudentPhotoRepository {
  /// L'état de chaque élève de l'école courante qui a, ou a eu, une photo.
  /// Un élève absent de la table n'a pas de photo.
  Future<Either<Failure, Map<String, StudentPhotoRef>>> loadIndex();

  /// Les octets JPEG de la photo de [ref] à [size] : la copie locale d'abord,
  /// sinon un téléchargement mis en cache. `null` si la photo n'est pas
  /// disponible (pas de photo, hors ligne sans copie).
  ///
  /// Sans [exact], une autre taille peut tenir lieu de celle demandée (la
  /// vignette, hors ligne) : la taille rendue le dit.
  Future<Either<Failure, StudentPhotoBytes?>> bytesOf(
    StudentPhotoRef ref,
    StudentPhotoSize size, {
    bool exact = false,
  });

  /// Enregistre [jpeg] (carré 512 px) comme photo de [studentId], prise à
  /// [takenAt] — la date du déclenchement, qui arbitrera côté serveur.
  Future<Either<Failure, Unit>> savePhoto({
    required String studentId,
    required Uint8List jpeg,
    required DateTime takenAt,
  });

  /// Retire la photo de [studentId] ; les initiales reprennent sa place.
  Future<Either<Failure, Unit>> removePhoto({
    required String studentId,
    required DateTime removedAt,
  });

  /// Les élèves dont la photo vient de changer (geste local, accusé, refus,
  /// descente). Un ensemble vide veut dire « relire tout ».
  Stream<Set<String>> get changes;
}
