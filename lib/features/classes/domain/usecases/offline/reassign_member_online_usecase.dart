import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// CF4 — Déplacement d'élève **ONLINE (Option A, V1)**.
///
/// Décision verrouillée : ZÉRO outbox pour le module Classe. Le déplacement
/// exige la connexion (comme la répartition, non time-critical). Après un PUT
/// réussi, on **re-pull** les classes concernées (pull delta) pour rafraîchir
/// les compteurs source/cible ; aucune application optimiste locale.
///
/// Le re-pull échoue « en douceur » : le déplacement serveur reste acquis même
/// si la synchro locale échoue (elle sera rattrapée au prochain flush/pull).
class ReassignMemberOnlineUseCase {
  final ClassroomRepository _onlineRepository;
  final ClassroomOfflineRepository _offlineRepository;

  const ReassignMemberOnlineUseCase({
    required ClassroomRepository onlineRepository,
    required ClassroomOfflineRepository offlineRepository,
  }) : _onlineRepository = onlineRepository,
       _offlineRepository = offlineRepository;

  /// Renvoie `Right(true)` si le re-pull local a aussi réussi, `Right(false)`
  /// si seul le déplacement serveur a réussi (re-pull à retenter plus tard).
  Future<Either<Failure, bool>> call({
    required String classroomMemberId,
    required String targetClassroomId,
    required String academicYearId,
  }) async {
    final reassigned = await _onlineRepository.reassignClassroomMember(
      classroomMemberId: classroomMemberId,
      targetClassroomId: targetClassroomId,
    );

    return reassigned.fold(Left.new, (_) async {
      final repull = await _offlineRepository.syncClassrooms(
        academicYearId: academicYearId,
      );
      return Right(repull.isRight());
    });
  }
}
