import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';

/// Contrat de consultation offline-first du module Classe (CF2/CF3/CF4).
///
/// Profil read-heavy : le pull alimente `ref_classrooms` + `ref_classroom_members`,
/// les lectures servent le local sans réseau. Le seul geste d'écriture
/// (déplacement) reste **online** (CF4 Option A) : cf. re-pull après succès.
abstract class ClassroomOfflineRepository {
  /// Pull delta (CF2) : alimente le local, avance le curseur, honore 304.
  Future<Either<Failure, ClassroomSyncOutcome>> syncClassrooms({
    required String academicYearId,
  });

  /// Classes d'une année (+ niveau optionnel), compteurs pré-agrégés, sans roster.
  Future<Either<Failure, List<OfflineClassroom>>> getClassrooms({
    required String academicYearId,
    String? schoolLevelId,
  });

  /// Une classe par id (`null` → NotFoundFailure).
  Future<Either<Failure, OfflineClassroom>> getClassroom({
    required String classroomId,
  });

  /// Roster ACTIVE d'une classe.
  Future<Either<Failure, List<ClassroomMember>>> getRoster({
    required String classroomId,
  });

  /// Recherche locale dans le roster ACTIVE (nom/post-nom/prénom, insensible casse).
  Future<Either<Failure, List<ClassroomMember>>> searchRoster({
    required String classroomId,
    required String query,
  });

  /// Horodatage epoch ms de dernière synchro des classes (fraîcheur ADR-002).
  Future<int?> getFreshness();
}
