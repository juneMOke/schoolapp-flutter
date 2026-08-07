import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/attendance_pull_outcome.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_pull_repository.dart';

/// Déclenche le pull keyset de la Présence (hydratation au montage du
/// FeatureScope). Le second déclencheur — retour online — passe par le
/// `PullCoordinator` (`AttendancePullHandler`). Les DEUX sont nécessaires : une
/// tablette démarrée déjà connectée ne tirerait jamais sur le seul signal online.
///
/// **Gate crédentiels** : ce déclencheur contourne le gate `SessionCredentialsProbe`
/// du `PullCoordinator` — sans le revérifier ici, une tablette sans session
/// valide taperait le réseau à chaque montage du scope Présence.
///
/// **Gate connectivité** : même raisonnement — sans `ConnectivityService`, une
/// tablette hors-ligne taperait quand même le réseau à chaque montage.
class SyncAttendancePullUseCase {
  final AttendancePullRepository _repository;
  final SessionCredentialsProbe _credentialsProbe;
  final ConnectivityService _connectivity;

  const SyncAttendancePullUseCase(
    this._repository,
    this._credentialsProbe,
    this._connectivity,
  );

  Future<Either<Failure, AttendancePullOutcome>> call() async {
    if (!await _connectivity.isOnline()) {
      return const Left(NetworkFailure('Hors-ligne : pull ignoré'));
    }
    if (!await _canAuthenticate()) {
      return const Left(AuthFailure('Session non authentifiée : pull ignoré'));
    }
    return _repository.syncAttendance();
  }

  /// Sonde défaillante (storage indisponible…) : ne pas bloquer l'hydratation —
  /// même politique fail-open que `SyncStatusCubit._canAuthenticate()`.
  Future<bool> _canAuthenticate() async {
    try {
      return await _credentialsProbe.canAuthenticate();
    } catch (_) {
      return true;
    }
  }
}
