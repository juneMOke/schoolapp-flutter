import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// CF4 — Affectation d'un élève **non réparti** (première mise en classe),
/// ONLINE (Option A, V1).
///
/// Décision verrouillée : ZÉRO outbox pour le module Classe. Le geste exige la
/// connexion (comme la répartition, non time-critical) — un non-réparti n'a
/// aucune ligne dans le miroir, il ne peut donc pas passer par l'événement de
/// transfert (qui, lui, DÉPLACE une appartenance existante).
///
/// Coordination en trois temps, du plus au moins critique :
///  1. `POST /classrooms/{id}/members` — seule étape dont l'échec est un échec ;
///  2. intégration du membre canonique renvoyé (201) dans le miroir, pour que
///     l'élève quitte immédiatement la section « non répartis » (les rosters
///     composés se lisent dans le miroir, pas dans une réponse serveur) ;
///  3. re-pull delta, qui rafraîchit en plus les compteurs pré-agrégés de
///     `ref_classrooms` (hors périmètre du 201, qui ne porte pas de compteurs).
///
/// Les étapes 2 et 3 échouent « en douceur » : l'affectation serveur reste
/// acquise, la synchro suivante rattrapera.
class AssignEnrollmentToClassroomUseCase {
  final ClassroomRepository _onlineRepository;
  final ClassroomOfflineRepository _offlineRepository;

  const AssignEnrollmentToClassroomUseCase({
    required ClassroomRepository onlineRepository,
    required ClassroomOfflineRepository offlineRepository,
  }) : _onlineRepository = onlineRepository,
       _offlineRepository = offlineRepository;

  /// Renvoie `Right(true)` si le miroir local est à jour (intégration **et**
  /// re-pull OK), `Right(false)` si seule l'affectation serveur est acquise —
  /// succès partiel à re-synchroniser, jamais un échec.
  Future<Either<Failure, bool>> call({
    required String classroomId,
    required String enrollmentId,
    required String academicYearId,
  }) async {
    final assigned = await _onlineRepository.assignEnrollmentToClassroom(
      classroomId: classroomId,
      enrollmentId: enrollmentId,
    );

    return assigned.fold(Left.new, (member) async {
      final upserted = await _offlineRepository.upsertAssignedMember(member);
      final repull = await _offlineRepository.syncClassrooms(
        academicYearId: academicYearId,
      );
      return Right(upserted.isRight() && repull.isRight());
    });
  }
}
