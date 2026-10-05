import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';

/// L'état de la photo de chaque élève de l'école courante.
class LoadStudentPhotoIndexUseCase {
  final StudentPhotoRepository _repository;

  const LoadStudentPhotoIndexUseCase(this._repository);

  Future<Either<Failure, Map<String, StudentPhotoRef>>> call() =>
      _repository.loadIndex();

  /// Les élèves dont la photo change, au fil de l'eau.
  Stream<Set<String>> get changes => _repository.changes;
}

/// Les octets d'une photo à afficher.
class ReadStudentPhotoUseCase {
  final StudentPhotoRepository _repository;

  const ReadStudentPhotoUseCase(this._repository);

  Future<Either<Failure, StudentPhotoBytes?>> call(
    StudentPhotoRef ref,
    StudentPhotoSize size, {
    bool exact = false,
  }) => _repository.bytesOf(ref, size, exact: exact);
}

/// Enregistre une photo prise ou importée, et la met en file d'envoi.
class SaveStudentPhotoUseCase {
  final StudentPhotoRepository _repository;

  const SaveStudentPhotoUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String studentId,
    required Uint8List jpeg,
    required DateTime takenAt,
  }) =>
      _repository.savePhoto(studentId: studentId, jpeg: jpeg, takenAt: takenAt);
}

/// Retire la photo d'un élève, et met le retrait en file d'envoi.
class RemoveStudentPhotoUseCase {
  final StudentPhotoRepository _repository;

  const RemoveStudentPhotoUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String studentId,
    required DateTime removedAt,
  }) => _repository.removePhoto(studentId: studentId, removedAt: removedAt);
}
