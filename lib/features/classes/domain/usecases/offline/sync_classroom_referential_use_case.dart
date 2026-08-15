import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_transfer_pull_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';

/// Hydrate le référentiel Classe de l'**année courante** — classes
/// (`ref_classrooms`), roster (`ref_classroom_members`) **et** transferts
/// (`classroom_transfers`) — sans qu'on ait à lui passer l'année.
///
/// [SyncClassroomsUseCase] exige un `academicYearId` : il sert l'écran Classes,
/// qui l'a déjà sous la main. Les autres modules qui **consomment** le roster
/// sans l'afficher (le Contrôle des frais borne sa recherche à une classe) n'ont
/// pas ce contexte au montage de leur scope. Ils appelaient donc… rien, et
/// lisaient une table que personne n'avait remplie : la recherche par classe
/// remontait zéro élève, silencieusement.
///
/// Résout l'année comme les handlers de pull (`ref_academic_years` scopé école),
/// applique les mêmes gates que [SyncFinancePullsUseCase] — connectivité et
/// crédentiels, parce que ce déclencheur contourne le `PullCoordinator` — et
/// reste **best-effort** : aucun échec ne remonte à l'UI, qui lit le local de
/// toute façon.
class SyncClassroomReferentialUseCase {
  final ClassroomOfflineRepository _repository;
  final ClassroomTransferPullRepository _transferRepository;
  final EnrollmentReferentialDao _referentialDao;
  final CurrentUserContext _currentUser;
  final SessionCredentialsProbe _credentialsProbe;
  final ConnectivityService _connectivity;

  const SyncClassroomReferentialUseCase({
    required ClassroomOfflineRepository repository,
    required ClassroomTransferPullRepository transferRepository,
    required EnrollmentReferentialDao referentialDao,
    required CurrentUserContext currentUser,
    required SessionCredentialsProbe credentialsProbe,
    required ConnectivityService connectivity,
  }) : _repository = repository,
       _transferRepository = transferRepository,
       _referentialDao = referentialDao,
       _currentUser = currentUser,
       _credentialsProbe = credentialsProbe,
       _connectivity = connectivity;

  /// Vrai si les **classes et le roster** ont été (re)tirés, faux si l'appel a
  /// été sauté ou a échoué. Le sort des transferts n'y entre pas : ils sont
  /// tirés en flux indépendant (cf. [_syncTransfers]). Aucun appelant n'est
  /// tenu d'observer ce booléen.
  Future<bool> call() async {
    try {
      if (!await _connectivity.isOnline()) return false;
      if (!await _canAuthenticate()) return false;

      final schoolId = _currentUser.schoolId;
      if (schoolId == null) return false;

      final academicYearId = await _referentialDao.findCurrentAcademicYearId(
        schoolId,
      );
      if (academicYearId == null || academicYearId.isEmpty) return false;

      final result = await _repository.syncClassrooms(
        academicYearId: academicYearId,
      );
      // TOUJOURS après les classes : le DAO résout `school_level_id` par un
      // SELECT sur `ref_classrooms` à l'application de chaque delta, et
      // remplirait la colonne d'une chaîne vide si la classe destination
      // n'était pas encore en base. Ne jamais inverser.
      await _syncTransfers();
      return result.isRight();
    } catch (_) {
      // Hydratation opportuniste : jamais un chemin d'échec pour l'écran.
      return false;
    }
  }

  /// Tire les transferts, en **flux indépendant** : un échec des classes ne
  /// doit pas les priver de leur cycle (isolation par ressource, calquée sur le
  /// `PullCoordinator`).
  ///
  /// Ce flux n'ajoute aucun élève à aucune lecture — le roster composé ne
  /// regarde que les transferts NON synchronisés, et le pull n'écrit que du
  /// `SYNCED`. Il reste pourtant indispensable : c'est lui, et lui seul, qui
  /// pose le marqueur de bootstrap dont dépend l'onglet Présence de la fiche
  /// élève. Sans porteur au montage, ce marqueur n'était jamais posé sur une
  /// tablette démarrée déjà connectée, et l'onglet restait à vie sur
  /// « Synchronisation en attente » (ADR-015 §6-D).
  Future<void> _syncTransfers() async {
    try {
      await _transferRepository.syncTransfers();
    } catch (_) {
      // Best-effort, comme le reste de cette hydratation.
    }
  }

  /// Sonde défaillante : ne pas bloquer l'hydratation — même politique
  /// fail-open que `SyncFinancePullsUseCase`.
  Future<bool> _canAuthenticate() async {
    try {
      return await _credentialsProbe.canAuthenticate();
    } catch (_) {
      return true;
    }
  }
}
