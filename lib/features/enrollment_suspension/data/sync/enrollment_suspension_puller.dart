import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/enrollment_suspension_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_api.dart';

/// Clé de routage du flux `enrollment.suspensions` côté client.
const String kEnrollmentSuspensionsResource = 'enrollment_suspensions';

/// La descente du flux `enrollment.suspensions` : périodes ouvertes et
/// fermées, d'où la tablette déduit l'état et la date « depuis le … ».
class EnrollmentSuspensionPuller {
  final EnrollmentSuspensionApi _api;
  final KeysetPullRunner _runner;
  final EnrollmentSuspensionSyncDao _sync;
  final EnrollmentSuspensionChangeBus _bus;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  const EnrollmentSuspensionPuller({
    required EnrollmentSuspensionApi api,
    required KeysetPullRunner runner,
    required EnrollmentSuspensionSyncDao sync,
    required EnrollmentSuspensionChangeBus bus,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _runner = runner,
       _sync = sync,
       _bus = bus,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  /// Une période pèse une centaine d'octets.
  static const int pageLimit = 500;

  /// Curseur scopé par école : une tablette réaffectée ne reprend pas la
  /// seconde école là où la première s'était arrêtée.
  static String cursorKey(String schoolId) =>
      '$kEnrollmentSuspensionsResource@$schoolId';

  Future<Either<Failure, KeysetPullResult>> pull() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return const Left(ServerFailure('Aucune école courante'));
    }
    final result = await _runner.run(
      cursorKey: cursorKey(schoolId),
      label: kEnrollmentSuspensionsResource,
      fetch: (cursor) => _api.pull(_requiredAuth, cursor, pageLimit),
      apply: (items, nowMs) =>
          _sync.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
    );
    if (result case Right(:final value) when !value.notModified) {
      _bus.emitAll();
    }
    return result;
  }
}
