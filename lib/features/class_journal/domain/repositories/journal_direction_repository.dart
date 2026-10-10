import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_read_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_teacher.dart';

/// La lecture **en ligne** des journaux, pour la direction : elle n'a ni
/// l'emploi du temps ni le journal des professeurs sur sa tablette.
abstract class JournalDirectionRepository {
  /// Les enseignants de l'école, par nom.
  Future<Either<Failure, List<JournalTeacher>>> teachers();

  /// La journée de [teacherId] à [date], triée par créneau.
  Future<Either<Failure, List<JournalReadLine>>> dayOf(
    String teacherId,
    DateTime date,
  );
}
