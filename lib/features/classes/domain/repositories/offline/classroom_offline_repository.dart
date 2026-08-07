import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';

/// Contrat offline-first du module Classe (CF2/CF3/CF4).
///
/// Profil read-heavy : le pull alimente `ref_classrooms` + `ref_classroom_members`,
/// les lectures servent le local (roster **composé** miroir ± transferts pending).
/// Le seul geste d'écriture — le transfert — est **offline** (ADR-004 amendé) :
/// événement append-only local + outbox, flush opportuniste.
abstract class ClassroomOfflineRepository {
  /// Pull des classes (CF2) : orchestre deux flux keyset **indépendants**
  /// (`classrooms` + `classroom-members`, curseurs propres à chacun),
  /// alimente le local, honore 304 par flux.
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

  /// Rosters **composés** de toutes les classes d'un niveau (CF4), indexés par
  /// `classroomId`. Sert l'affichage optimiste de l'écran d'organisation : un
  /// transfert local non synchronisé apparaît aussitôt dans la destination
  /// (`hasPendingTransfer`) et disparaît de l'origine, sans re-pull serveur.
  Future<Either<Failure, Map<String, List<ClassroomMember>>>>
  getComposedRosters({
    required String academicYearId,
    required String schoolLevelId,
  });

  /// Enregistre un **transfert d'élève** (CF4, offline) : événement append-only
  /// local + outbox, flush opportuniste. Retourne l'`id` du transfert créé (uuid
  /// client honoré). Le miroir n'est pas muté — la composition à la lecture
  /// reflète immédiatement le déplacement.
  Future<Either<Failure, String>> recordTransfer(
    RecordClassroomTransferDraft draft,
  );

  /// Intègre au miroir `ref_classroom_members` le membre **canonique** renvoyé
  /// par le serveur après une affectation (201 du POST members).
  ///
  /// Sans ça, l'élève resterait affiché dans « non répartis » jusqu'au prochain
  /// pull : les rosters composés — et donc le calcul des non-affectés — se
  /// lisent exclusivement dans le miroir. Écriture idempotente (`REPLACE` sur
  /// la PK) : le pull suivant réécrira la même ligne, enrichie de `version` /
  /// `updatedAt`.
  Future<Either<Failure, void>> upsertAssignedMember(ClassroomMember member);

  /// Horodatage epoch ms de dernière synchro des classes (fraîcheur ADR-002).
  Future<int?> getFreshness();
}
