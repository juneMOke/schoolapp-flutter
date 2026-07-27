import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_offline_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';

/// [PullHandler] du module Classe (CF2) : tire le delta `/sync/classrooms` pour
/// peupler `ref_classrooms` + `ref_classroom_members` locaux.
///
/// **Self-sufficient** : résout l'`academicYearId` courant depuis le
/// référentiel Inscription local (`ref_academic_years`, déjà pullé), scopé à
/// l'école de l'utilisateur courant — aucune dépendance à l'UI. No-op propre
/// (échec non-fatal) si le référentiel n'est pas encore synchronisé. Délègue
/// au repository offline, qui gère curseur `updatedSince`, upsert et 304.
class ClassroomPullHandler implements PullHandler {
  final ClassroomOfflineRepository _offlineRepository;
  final EnrollmentReferentialDao _referentialDao;
  final CurrentUserContext _currentUser;

  const ClassroomPullHandler({
    required ClassroomOfflineRepository offlineRepository,
    required EnrollmentReferentialDao referentialDao,
    required CurrentUserContext currentUser,
  }) : _offlineRepository = offlineRepository,
       _referentialDao = referentialDao,
       _currentUser = currentUser;

  @override
  String get resource => ClassroomOfflineRepositoryImpl.syncResource;

  @override
  Future<PullOutcome> pull() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null) {
      return const PullOutcome.error('Aucune session active');
    }
    final academicYearId = await _referentialDao.findCurrentAcademicYearId(
      schoolId,
    );
    if (academicYearId == null || academicYearId.isEmpty) {
      return const PullOutcome.error(
        'Année courante indisponible (référentiel local non chargé)',
      );
    }

    final result = await _offlineRepository.syncClassrooms(
      academicYearId: academicYearId,
    );
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.classroomsUpserted + outcome.membersUpserted,
            ),
    );
  }
}
