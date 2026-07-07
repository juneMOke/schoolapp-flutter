import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_offline_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// [PullHandler] du module Classe (CF2) : tire le delta `/sync/classrooms` pour
/// peupler `ref_classrooms` + `ref_classroom_members` locaux.
///
/// **Self-sufficient** : résout l'`academicYearId` courant depuis le **bootstrap
/// local** (déjà mis en cache après authentification) — aucune dépendance à
/// l'UI. No-op propre (échec non-fatal) si le bootstrap n'est pas encore chargé.
/// Délègue au repository offline, qui gère curseur `updatedSince`, upsert et 304.
class ClassroomPullHandler implements PullHandler {
  final ClassroomOfflineRepository _offlineRepository;
  final BootstrapLocalRepository _bootstrapRepository;
  final String _bootstrapKey;

  const ClassroomPullHandler({
    required ClassroomOfflineRepository offlineRepository,
    required BootstrapLocalRepository bootstrapRepository,
    String bootstrapKey = AppConstants.bootstrapPayloadKey,
  }) : _offlineRepository = offlineRepository,
       _bootstrapRepository = bootstrapRepository,
       _bootstrapKey = bootstrapKey;

  @override
  String get resource => ClassroomOfflineRepositoryImpl.syncResource;

  @override
  Future<PullOutcome> pull() async {
    final bootstrap = await _bootstrapRepository.getStoredBootstrap(
      _bootstrapKey,
    );
    final academicYearId = bootstrap.fold(
      (_) => null,
      (b) => b.academicYear.id,
    );
    if (academicYearId == null || academicYearId.isEmpty) {
      return const PullOutcome.error(
        'Année courante indisponible (bootstrap local non chargé)',
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
