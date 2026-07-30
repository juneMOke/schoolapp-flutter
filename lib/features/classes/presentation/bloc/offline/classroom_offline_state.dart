import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
// Réutilise les enums de statut/erreur du BLoC online (calque de style, DRY).
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';

/// État unique offline-first du module Classe (CF2/CF3/CF4).
///
/// Calqué sur [ClassroomState] (online) : un seul état porteur, muté par
/// `copyWith`, exposant en parallèle les classes, le roster, le transfert
/// (offline) et l'affectation d'un non-réparti (online).
///
/// Deux gestes d'écriture, deux régimes :
///  - **Transfert** (CF4, ADR-004 amendé) : OFFLINE, événement + outbox →
///    [transferStatus] + [transferPendingSync] (succès = « en attente de synchro »).
///  - **Affectation d'un non-réparti** (distribution, ADR-004) : ONLINE, POST +
///    intégration au miroir + re-pull → [assignStatus] + [assignRePullFailed].
class ClassroomOfflineState extends Equatable {
  // ── Classes de TOUTE l'année (CF3, dropdowns Présences/Classes/Résultats) ──
  final ClassroomStatus classroomsStatus;
  final List<OfflineClassroom> classrooms;
  final ClassroomErrorType classroomsErrorType;

  // ── Classes d'UN SEUL niveau (CF3, working-set dédié Organisation) — jamais
  // partagé avec [classrooms] ci-dessus (revue adversariale, cf.
  // `OfflineLevelClassroomsRequested`).
  final ClassroomStatus levelClassroomsStatus;
  final List<OfflineClassroom> levelClassrooms;
  final ClassroomErrorType levelClassroomsErrorType;

  // ── Roster d'une classe (CF3) ──
  final ClassroomStatus rosterStatus;
  final List<ClassroomMember> roster;
  final ClassroomErrorType rosterErrorType;

  // ── Pull delta (CF2) ──
  final ClassroomStatus syncStatus;

  /// Horodatage epoch ms de la dernière synchro (fraîcheur ADR-002), dérivé du
  /// `syncedAt` du bilan de pull.
  final int? freshness;

  // ── Rosters composés du niveau (CF4, affichage optimiste) ──
  final ClassroomStatus levelRostersStatus;

  /// Roster composé (miroir ± transferts pending) par `classroomId`. Vide tant
  /// qu'aucun niveau n'a été chargé.
  final Map<String, List<ClassroomMember>> levelRosters;

  // ── Élèves non affectés du niveau, calculé 100% offline (CF3/CF4) ──
  final ClassroomStatus levelUnassignedStatus;
  final List<EnrollmentSummary> levelUnassignedEnrollments;
  final ClassroomErrorType levelUnassignedErrorType;

  // ── Transfert OFFLINE (CF4) ──
  final ClassroomStatus transferStatus;
  final ClassroomErrorType transferErrorType;

  /// Élève dont le transfert est en cours (anti-double-envoi UI).
  final String transferringStudentId;

  /// `true` après un transfert enregistré localement (événement enfilé) : le
  /// geste est acquis en local et « en attente de synchro ».
  final bool transferPendingSync;

  // ── Affectation d'un non-réparti ONLINE (distribution) ──
  final ClassroomStatus assignStatus;
  final ClassroomErrorType assignErrorType;

  /// Dossier d'inscription dont l'affectation est en cours (anti-double-envoi
  /// UI). Un non-réparti n'ayant pas de ligne roster, c'est bien son
  /// `enrollmentId` — et non un `classroomMemberId` — qui l'identifie ici.
  final String assigningEnrollmentId;

  /// `true` uniquement après un succès partiel (Right(false)) : l'affectation
  /// serveur est acquise mais la mise à jour du miroir local a échoué
  /// (intégration du membre créé et/ou re-pull) — à retenter.
  final bool assignRePullFailed;

  const ClassroomOfflineState({
    this.classroomsStatus = ClassroomStatus.initial,
    this.classrooms = const [],
    this.classroomsErrorType = ClassroomErrorType.none,
    this.levelClassroomsStatus = ClassroomStatus.initial,
    this.levelClassrooms = const [],
    this.levelClassroomsErrorType = ClassroomErrorType.none,
    this.rosterStatus = ClassroomStatus.initial,
    this.roster = const [],
    this.rosterErrorType = ClassroomErrorType.none,
    this.syncStatus = ClassroomStatus.initial,
    this.freshness,
    this.levelRostersStatus = ClassroomStatus.initial,
    this.levelRosters = const {},
    this.levelUnassignedStatus = ClassroomStatus.initial,
    this.levelUnassignedEnrollments = const [],
    this.levelUnassignedErrorType = ClassroomErrorType.none,
    this.transferStatus = ClassroomStatus.initial,
    this.transferErrorType = ClassroomErrorType.none,
    this.transferringStudentId = '',
    this.transferPendingSync = false,
    this.assignStatus = ClassroomStatus.initial,
    this.assignErrorType = ClassroomErrorType.none,
    this.assigningEnrollmentId = '',
    this.assignRePullFailed = false,
  });

  ClassroomOfflineState copyWith({
    ClassroomStatus? classroomsStatus,
    List<OfflineClassroom>? classrooms,
    ClassroomErrorType? classroomsErrorType,
    ClassroomStatus? levelClassroomsStatus,
    List<OfflineClassroom>? levelClassrooms,
    ClassroomErrorType? levelClassroomsErrorType,
    ClassroomStatus? rosterStatus,
    List<ClassroomMember>? roster,
    ClassroomErrorType? rosterErrorType,
    ClassroomStatus? syncStatus,
    Object? freshness = _undefined,
    ClassroomStatus? levelRostersStatus,
    Map<String, List<ClassroomMember>>? levelRosters,
    ClassroomStatus? levelUnassignedStatus,
    List<EnrollmentSummary>? levelUnassignedEnrollments,
    ClassroomErrorType? levelUnassignedErrorType,
    ClassroomStatus? transferStatus,
    ClassroomErrorType? transferErrorType,
    String? transferringStudentId,
    bool? transferPendingSync,
    ClassroomStatus? assignStatus,
    ClassroomErrorType? assignErrorType,
    String? assigningEnrollmentId,
    bool? assignRePullFailed,
  }) => ClassroomOfflineState(
    classroomsStatus: classroomsStatus ?? this.classroomsStatus,
    classrooms: classrooms ?? this.classrooms,
    classroomsErrorType: classroomsErrorType ?? this.classroomsErrorType,
    levelClassroomsStatus: levelClassroomsStatus ?? this.levelClassroomsStatus,
    levelClassrooms: levelClassrooms ?? this.levelClassrooms,
    levelClassroomsErrorType:
        levelClassroomsErrorType ?? this.levelClassroomsErrorType,
    rosterStatus: rosterStatus ?? this.rosterStatus,
    roster: roster ?? this.roster,
    rosterErrorType: rosterErrorType ?? this.rosterErrorType,
    syncStatus: syncStatus ?? this.syncStatus,
    freshness: identical(freshness, _undefined)
        ? this.freshness
        : freshness as int?,
    levelRostersStatus: levelRostersStatus ?? this.levelRostersStatus,
    levelRosters: levelRosters ?? this.levelRosters,
    levelUnassignedStatus: levelUnassignedStatus ?? this.levelUnassignedStatus,
    levelUnassignedEnrollments:
        levelUnassignedEnrollments ?? this.levelUnassignedEnrollments,
    levelUnassignedErrorType:
        levelUnassignedErrorType ?? this.levelUnassignedErrorType,
    transferStatus: transferStatus ?? this.transferStatus,
    transferErrorType: transferErrorType ?? this.transferErrorType,
    transferringStudentId: transferringStudentId ?? this.transferringStudentId,
    transferPendingSync: transferPendingSync ?? this.transferPendingSync,
    assignStatus: assignStatus ?? this.assignStatus,
    assignErrorType: assignErrorType ?? this.assignErrorType,
    assigningEnrollmentId: assigningEnrollmentId ?? this.assigningEnrollmentId,
    assignRePullFailed: assignRePullFailed ?? this.assignRePullFailed,
  );

  @override
  List<Object?> get props => [
    classroomsStatus,
    classrooms,
    classroomsErrorType,
    levelClassroomsStatus,
    levelClassrooms,
    levelClassroomsErrorType,
    rosterStatus,
    roster,
    rosterErrorType,
    syncStatus,
    freshness,
    levelRostersStatus,
    levelRosters,
    levelUnassignedStatus,
    levelUnassignedEnrollments,
    levelUnassignedErrorType,
    transferStatus,
    transferErrorType,
    transferringStudentId,
    transferPendingSync,
    assignStatus,
    assignErrorType,
    assigningEnrollmentId,
    assignRePullFailed,
  ];
}

const _undefined = Object();
