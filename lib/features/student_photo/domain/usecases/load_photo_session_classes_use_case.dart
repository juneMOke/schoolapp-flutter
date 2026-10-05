import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/class_roster_source.dart';

/// Les classes de l'année, chacune avec ses élèves et ceux qui ont déjà une
/// photo — de quoi choisir la classe d'une séance.
class LoadPhotoSessionClassesUseCase {
  final ClassRosterSource _rosters;
  final StudentPhotoRepository _photos;

  const LoadPhotoSessionClassesUseCase({
    required ClassRosterSource rosters,
    required StudentPhotoRepository photos,
  }) : _rosters = rosters,
       _photos = photos;

  Future<Either<Failure, List<SessionClassSummary>>> call(
    String academicYearId,
  ) async {
    final classes = await _rosters.classes(academicYearId);
    final index = await _photos.loadIndex();
    final failure =
        classes.fold<Failure?>((f) => f, (_) => null) ??
        index.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final withPhoto = {
      for (final entry in index.getOrElse(() => const {}).entries)
        if (entry.value.hasPhoto) entry.key,
    };
    final summaries = <SessionClassSummary>[];
    for (final klass in classes.getOrElse(() => const [])) {
      final roster = await _rosters.roster(klass.id);
      summaries.add(
        SessionClassSummary(
          klass: klass,
          students: roster.getOrElse(() => const []),
          withPhoto: withPhoto,
        ),
      );
    }
    return Right(summaries);
  }
}
