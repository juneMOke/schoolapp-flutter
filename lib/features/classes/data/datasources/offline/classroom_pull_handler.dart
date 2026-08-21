import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_pull_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';

/// [PullHandler] des classes (CF2) : tire le flux keyset `/sync/classrooms`
/// pour peupler `ref_classrooms` local. Ressource **indépendante** du roster
/// (voir `ClassroomMemberPullHandler`, curseur séparé).
///
/// **Self-sufficient** : résout l'`academicYearId` courant depuis le
/// référentiel Inscription local (`ref_academic_years`, déjà pullé), scopé à
/// l'école de l'utilisateur courant — aucune dépendance à l'UI. No-op propre
/// (échec non-fatal) si le référentiel n'est pas encore synchronisé. Délègue
/// au repository de pull dédié, qui gère le curseur keyset, l'upsert et le 304.
class ClassroomPullHandler implements PullHandler {
  final ClassroomPullRepository _pullRepository;
  final EnrollmentReferentialDao _referentialDao;
  final CurrentUserContext _currentUser;

  const ClassroomPullHandler({
    required ClassroomPullRepository pullRepository,
    required EnrollmentReferentialDao referentialDao,
    required CurrentUserContext currentUser,
  }) : _pullRepository = pullRepository,
       _referentialDao = referentialDao,
       _currentUser = currentUser;

  @override
  String get resource => ClassroomPullRepositoryImpl.resource;

  /// GET /sync/classrooms — gardé sur `classroom.read` côté serveur.
  @override
  List<Perm> get requiredPermissions => const [Perm.classroomRead];

  @override
  bool get isBaseline => false;

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

    final result = await _pullRepository.syncClassrooms(
      academicYearId: academicYearId,
    );
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
