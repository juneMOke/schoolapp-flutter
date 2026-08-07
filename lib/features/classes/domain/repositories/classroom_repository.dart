import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

abstract class ClassroomRepository {
  Future<Either<Failure, List<Classroom>>> getClassroomsByLevelAndAcademicYear({
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required String academicYearId,
  });

  Future<Either<Failure, List<ClassroomMember>>> getClassroomMembers({
    required String classroomId,
    required String academicYearId,
  });

  Future<Either<Failure, LevelDistributionOverview>>
  getLevelDistributionOverview({
    required String academicYearId,
    required String schoolLevelId,
  });

  Future<Either<Failure, void>> distributeStudentsToClassrooms({
    required String academicYearId,
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required ClassroomDistributionCriterion distributionCriterion,
  });

  /// Première affectation d'un élève non réparti (POST members) : crée sa ligne
  /// roster à partir de son **dossier d'inscription** et renvoie le membre
  /// canonique créé par le serveur (à intégrer au miroir par l'appelant).
  ///
  /// Ne couvre QUE la première mise en classe : le déplacement d'un membre
  /// existant passe par l'événement de transfert hors ligne.
  Future<Either<Failure, ClassroomMember>> assignEnrollmentToClassroom({
    required String classroomId,
    required String enrollmentId,
  });

  Future<Either<Failure, ClassroomStats>> getClassroomStats();
}
